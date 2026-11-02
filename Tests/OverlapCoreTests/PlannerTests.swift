import Foundation
import Testing

@testable import OverlapCore

private func instant(_ value: String) -> Date { ISO8601DateFormatter().date(from: value)! }
private let chicago = Participant(name: "Chicago", zoneID: "America/Chicago")

@Test func workingHoursBoundaries() {
  #expect(Planner.available(chicago, at: instant("2026-11-02T15:00:00Z"), minutes: 30))
  #expect(!Planner.available(chicago, at: instant("2026-11-02T14:59:00Z"), minutes: 30))
  #expect(Planner.available(chicago, at: instant("2026-11-02T22:30:00Z"), minutes: 30))
  #expect(!Planner.available(chicago, at: instant("2026-11-02T22:31:00Z"), minutes: 30))
}

@Test func weekend() {
  #expect(!Planner.available(chicago, at: instant("2026-11-01T16:00:00Z"), minutes: 30))
}

@Test func daylightSavingOffset() {
  #expect(Planner.available(chicago, at: instant("2026-07-06T14:00:00Z"), minutes: 30))
  #expect(!Planner.available(chicago, at: instant("2026-11-02T14:00:00Z"), minutes: 30))
}

@Test func halfHourZone() {
  let kolkata = Participant(name: "Kolkata", zoneID: "Asia/Kolkata")
  #expect(Planner.available(kolkata, at: instant("2026-11-02T03:30:00Z"), minutes: 30))
  #expect(!Planner.available(kolkata, at: instant("2026-11-02T03:15:00Z"), minutes: 30))
}

@Test func midnightAndLocalWeekday() {
  let tokyo = Participant(name: "Tokyo", zoneID: "Asia/Tokyo", startHour: 0, endHour: 24)
  #expect(Planner.available(tokyo, at: instant("2026-11-01T15:00:00Z"), minutes: 30))
  #expect(!Planner.available(tokyo, at: instant("2026-11-06T14:45:00Z"), minutes: 30))
}

@Test func search() {
  let london = Participant(name: "London", zoneID: "Europe/London")
  let values = Planner.suggestions(
    people: [chicago, london], after: instant("2026-11-02T14:01:00Z"), minutes: 30)
  #expect(values.count == 5)
  #expect(values.first == instant("2026-11-02T15:00:00Z"))
  #expect(
    values.allSatisfy {
      Planner.available(chicago, at: $0, minutes: 30)
        && Planner.available(london, at: $0, minutes: 30)
    })
}

@Test func noOverlapAndInvalidInputs() {
  let remote = Participant(name: "Other", zoneID: "Asia/Tokyo", startHour: 9, endHour: 10)
  #expect(
    Planner.suggestions(
      people: [chicago, remote], after: instant("2026-11-02T00:00:00Z"), minutes: 30
    ).isEmpty)
  #expect(Planner.suggestions(people: [], after: Date(), minutes: 30).isEmpty)
  #expect(!Planner.available(chicago, at: Date(), minutes: 0))
  #expect(!Participant(name: "", zoneID: "UTC").isValid)
  #expect(!Participant(name: "Bad", zoneID: "invalid").isValid)
  #expect(!Participant(name: "Bad", zoneID: "UTC", startHour: 17, endHour: 9).isValid)
}

@Test func secondsIgnoredAndReport() {
  #expect(Planner.available(chicago, at: instant("2026-11-02T22:30:59Z"), minutes: 30))
  #expect(
    Planner.localTime(instant("2026-11-02T15:00:00Z"), zoneID: "America/Chicago").contains("09:00"))
}
