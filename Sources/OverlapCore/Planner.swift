import Foundation

public struct Participant: Identifiable, Equatable, Sendable {
  public let id: UUID
  public var name: String
  public var zoneID: String
  public var startHour: Int
  public var endHour: Int

  public init(
    id: UUID = UUID(), name: String, zoneID: String, startHour: Int = 9, endHour: Int = 17
  ) {
    self.id = id
    self.name = name
    self.zoneID = zoneID
    self.startHour = startHour
    self.endHour = endHour
  }

  public var isValid: Bool {
    !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && name.count <= 60
      && TimeZone(identifier: zoneID) != nil && (0...23).contains(startHour)
      && (1...24).contains(endHour) && startHour < endHour
  }
}

public enum Planner {
  /// Checks every occupied minute of a minute-aligned interval. End is exclusive.
  /// Weekdays and wall-clock hours are evaluated separately in each participant's zone.
  public static func available(_ person: Participant, at date: Date, minutes: Int) -> Bool {
    guard person.isValid, (15...180).contains(minutes),
      date.timeIntervalSince1970.isFinite,
      let zone = TimeZone(identifier: person.zoneID)
    else { return false }
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = zone
    let start = floor(date.timeIntervalSince1970 / 60) * 60
    for offset in 0..<minutes {
      let instant = Date(timeIntervalSince1970: start + Double(offset * 60))
      let parts = calendar.dateComponents([.weekday, .hour], from: instant)
      guard let weekday = parts.weekday, let hour = parts.hour,
        (2...6).contains(weekday), hour >= person.startHour, hour < person.endHour
      else { return false }
    }
    return true
  }

  /// Search seven elapsed days on a UTC quarter-hour grid, returning at most five starts.
  public static func suggestions(people: [Participant], after date: Date, minutes: Int) -> [Date] {
    guard (1...8).contains(people.count), people.allSatisfy({ $0.isValid }),
      (15...180).contains(minutes), date.timeIntervalSince1970.isFinite
    else { return [] }
    let start = ceil(date.timeIntervalSince1970 / 900) * 900
    var result: [Date] = []
    for step in 0..<(7 * 24 * 4) {
      let candidate = Date(timeIntervalSince1970: start + Double(step * 900))
      if people.allSatisfy({ available($0, at: candidate, minutes: minutes) }) {
        result.append(candidate)
        if result.count == 5 { break }
      }
    }
    return result
  }

  public static func localTime(_ date: Date, zoneID: String) -> String {
    guard let zone = TimeZone(identifier: zoneID) else { return "Invalid time zone" }
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = zone
    formatter.dateFormat = "EEE, MMM d, yyyy HH:mm zzz (XXXXX)"
    return formatter.string(from: date)
  }
}
