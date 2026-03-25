import Foundation
import Combine

struct WeekGroup: Identifiable {
    let id: Int
    let weekNumber: Int
    let year: Int
    let startDate: Date
    let reflections: [Reflection]

    var title: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "Week of \(formatter.string(from: startDate))"
    }
}

final class ArchiveViewModel: ObservableObject {
    @Published var reflections: [Reflection] = []
    @Published var searchQuery: String = ""
    @Published var weekGroups: [WeekGroup] = []

    private let db = DatabaseService.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        loadReflections()
        setupSearch()
    }

    private func setupSearch() {
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] query in
                self?.performSearch(query: query)
            }
            .store(in: &cancellables)
    }

    func loadReflections() {
        reflections = db.getAllReflections()
        groupByWeek()
    }

    private func performSearch(query: String) {
        if query.isEmpty {
            reflections = db.getAllReflections()
        } else {
            reflections = db.searchReflections(query: query)
        }
        groupByWeek()
    }

    private func groupByWeek() {
        let calendar = Calendar.current
        var groups: [Int: [Reflection]] = [:]

        for reflection in reflections {
            let weekOfYear = calendar.component(.weekOfYear, from: reflection.date)
            let year = calendar.component(.year, from: reflection.date)
            let key = year * 100 + weekOfYear
            groups[key, default: []].append(reflection)
        }

        weekGroups = groups.keys.sorted(by: >).compactMap { key in
            let year = key / 100
            let week = key % 100
            guard let startDate = calendar.date(from: DateComponents(weekOfYear: week, yearForWeekOfYear: year)) else {
                return nil
            }
            return WeekGroup(id: key, weekNumber: week, year: year, startDate: startDate, reflections: groups[key] ?? [])
        }
    }

    func deleteReflection(_ reflection: Reflection) {
        reflections.removeAll { $0.id == reflection.id }
        try? DatabaseService.shared.saveReflection(reflection)
        loadReflections()
    }
}
