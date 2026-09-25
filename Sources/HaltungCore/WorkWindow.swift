import Foundation

/// Arbeitszeitfenster. Ausserhalb davon feuert keine Erinnerung. Speicherung als
/// Minuten seit Mitternacht, damit es zeitzonenunabhaengig persistierbar ist.
public struct WorkWindow: Codable, Sendable, Equatable {
    /// Start in Minuten seit Mitternacht (z.B. 480 fuer 8:00).
    public var startMinute: Int
    /// Ende in Minuten seit Mitternacht (z.B. 1080 fuer 18:00).
    public var endMinute: Int

    public init(startMinute: Int, endMinute: Int) {
        self.startMinute = startMinute
        self.endMinute = endMinute
    }

    public init(startHour: Int, startMin: Int = 0, endHour: Int, endMin: Int = 0) {
        self.startMinute = startHour * 60 + startMin
        self.endMinute = endHour * 60 + endMin
    }

    /// Default: 8:00 bis 18:00.
    public static let standard = WorkWindow(startHour: 8, endHour: 18)

    /// Naechster Fensterbeginn nach dem gegebenen Zeitpunkt. Liegt der heutige
    /// Start noch bevor, ist es dieser, sonst der von morgen.
    ///
    /// Fuer die Anzeige gedacht: eine Erinnerung, die ausserhalb des Fensters
    /// faellig wuerde, kommt fruehestens zu diesem Zeitpunkt dran.
    ///
    /// Gesucht wird ueber `nextDate(after:matching:)`, also ueber die Wanduhrzeit.
    /// Minuten auf den Tagesbeginn zu addieren waere falsch: an den beiden
    /// Umstellungstagen hat der Tag 23 bzw. 25 Stunden, das Ergebnis laege eine
    /// Stunde daneben und damit ausserhalb des Fensters. `.nextTime` faengt
    /// zusaetzlich den Fall ab, dass die gesuchte Uhrzeit im Fruehjahr
    /// uebersprungen wird (02:00 bis 03:00 existiert dann nicht).
    public func nextStart(after date: Date, calendar: Calendar = .current) -> Date {
        calendar.nextDate(
            after: date,
            matching: DateComponents(hour: startMinute / 60, minute: startMinute % 60),
            matchingPolicy: .nextTime
        ) ?? date
    }

    /// Liegt der Zeitpunkt innerhalb des Fensters? Inklusive Start, exklusive Ende.
    /// Unterstuetzt auch ueber Mitternacht laufende Fenster (start > end).
    public func contains(_ date: Date, calendar: Calendar = .current) -> Bool {
        let comps = calendar.dateComponents([.hour, .minute], from: date)
        let minutes = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
        if startMinute <= endMinute {
            return minutes >= startMinute && minutes < endMinute
        } else {
            // Fenster ueber Mitternacht, z.B. 22:00 bis 6:00.
            return minutes >= startMinute || minutes < endMinute
        }
    }
}
