import Foundation

extension Calendar {
    func minuteTimeline(startingAt date: Date, count: Int) -> [Date] {
        guard count > 0 else { return [] }

        let start = dateInterval(of: .minute, for: date)?.start ?? date
        return (0..<count).compactMap { offset in
            self.date(byAdding: .minute, value: offset, to: start)
        }
    }
}
