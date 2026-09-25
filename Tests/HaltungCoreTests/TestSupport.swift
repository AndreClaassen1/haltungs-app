import Foundation

/// Gemeinsame Zeit-Helfer fuer alle Test-Suites, damit Kalender und
/// Datums-Konstruktion nicht in jeder Datei dupliziert werden.
let berlinTimeZone = TimeZone(identifier: "Europe/Berlin")!

var berlinCalendar: Calendar {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = berlinTimeZone
    return cal
}

/// Fester Referenztag (09.06.2026) mit gegebener Uhrzeit in Berliner Zeit.
func berlinDate(_ hour: Int, _ minute: Int, day: Int = 9) -> Date {
    berlinDate(year: 2026, month: 6, day: day, hour: hour, minute: minute)
}

/// Beliebiger Zeitpunkt in Berliner Zeit — fuer Tests rund um die
/// Zeitumstellung, die einen anderen Monat als den Referenztag brauchen.
func berlinDate(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
    var comps = DateComponents()
    comps.year = year
    comps.month = month
    comps.day = day
    comps.hour = hour
    comps.minute = minute
    comps.timeZone = berlinTimeZone
    return berlinCalendar.date(from: comps)!
}
