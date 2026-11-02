import SwiftUI

@main
struct OverlapWindowApp: App {
  var body: some Scene {
    WindowGroup { PlannerView() }
  }
}

struct PlannerView: View {
  @State private var people = [
    Participant(name: "Chicago", zoneID: "America/Chicago"),
    Participant(name: "London", zoneID: "Europe/London"),
  ]
  @State private var date = Date()
  @State private var minutes = 30
  @State private var adding = false
  @State private var suggestions: [Date] = []
  @State private var searched = false
  private let durations = [15, 30, 45, 60, 90, 120, 180]

  private var report: String {
    (["OverlapWindow — proposed meeting (\(minutes) minutes)"]
      + people.map { person in
        "\(person.name): \(Planner.localTime(date, zoneID: person.zoneID)) — "
          + (Planner.available(person, at: date, minutes: minutes)
            ? "within work hours" : "outside work hours")
      } + ["Monday–Friday only; holidays and actual calendar availability are not checked."])
      .joined(separator: "\n")
  }

  var body: some View {
    NavigationStack {
      Form {
        Section {
          DatePicker(
            "Meeting start", selection: $date, displayedComponents: [.date, .hourAndMinute])
          Text(
            "Picker uses your device time zone: \(TimeZone.current.identifier). Seconds are ignored."
          )
          .font(.caption).foregroundStyle(.secondary)
          Picker("Duration", selection: $minutes) {
            ForEach(durations, id: \.self) { Text("\($0) minutes").tag($0) }
          }
        } header: {
          Text("Proposed meeting")
        }
        Section {
          ForEach(people) { person in
            VStack(alignment: .leading, spacing: 6) {
              Text(person.name).font(.headline)
              Text(Planner.localTime(date, zoneID: person.zoneID)).font(.subheadline)
              Text("Mon–Fri · \(person.startHour):00–\(person.endHour):00 · \(person.zoneID)")
                .font(.caption).foregroundStyle(.secondary)
              Label(
                Planner.available(person, at: date, minutes: minutes)
                  ? "Within work hours" : "Outside work hours",
                systemImage: Planner.available(person, at: date, minutes: minutes)
                  ? "checkmark.circle" : "clock.badge.exclamationmark"
              )
            }.padding(.vertical, 4)
          }.onDelete { offsets in people.remove(atOffsets: offsets) }
          Button("Add participant", systemImage: "person.badge.plus") { adding = true }
            .disabled(people.count >= 8)
        } header: {
          Text("Participants (\(people.count)/8)")
        } footer: {
          Text(
            "Swipe to remove a participant. To change hours, remove and add again. Configuration lasts for this session."
          )
        }
        Section("Find an overlap") {
          Button("Find next shared times") {
            suggestions = Planner.suggestions(people: people, after: date, minutes: minutes)
            searched = true
          }.disabled(people.isEmpty)
          if searched && suggestions.isEmpty {
            Text("No shared time in the next seven elapsed days for these hours and duration.")
          }
          ForEach(suggestions, id: \.self) { suggestion in
            Button(Planner.localTime(suggestion, zoneID: TimeZone.current.identifier)) {
              date = suggestion
            }
          }
          Text(
            "Checks quarter-hour starts, Monday–Friday in each zone. Holidays, overnight shifts, and calendar conflicts are not included."
          )
          .font(.caption).foregroundStyle(.secondary)
        }
        Section {
          ShareLink("Share proposal", item: report).disabled(people.isEmpty)
        }
      }
      .navigationTitle("OverlapWindow")
      .sheet(isPresented: $adding) {
        ParticipantEditor { people.append($0) }
      }
      .onChange(of: people) { _, _ in resetSearch() }
      .onChange(of: minutes) { _, _ in resetSearch() }
      .onChange(of: date) { _, _ in resetSearch() }
    }
  }

  private func resetSearch() {
    suggestions = []
    searched = false
  }
}

struct ParticipantEditor: View {
  @Environment(\.dismiss) private var dismiss
  @State private var name = ""
  @State private var zone = "America/Chicago"
  @State private var start = 9
  @State private var end = 17
  let save: (Participant) -> Void
  private var person: Participant {
    Participant(name: name, zoneID: zone, startHour: start, endHour: end)
  }

  var body: some View {
    NavigationStack {
      Form {
        TextField("Name", text: $name).onChange(of: name) { _, newValue in
          name = String(newValue.prefix(60))
        }
        Picker("Time zone", selection: $zone) {
          ForEach(TimeZone.knownTimeZoneIdentifiers, id: \.self) { Text($0).tag($0) }
        }.pickerStyle(.navigationLink)
        Stepper("Start: \(start):00", value: $start, in: 0...23)
        Stepper("End: \(end):00", value: $end, in: 1...24)
        Text("Use same-day working hours; end must be later than start. Weekends are excluded.")
          .font(.caption)
      }
      .navigationTitle("Add participant")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
        ToolbarItem(placement: .confirmationAction) {
          Button("Add") {
            save(person)
            dismiss()
          }.disabled(!person.isValid)
        }
      }
    }
  }
}
