import Testing
import Foundation
@testable import HaltungCore

@Suite("WorkWindow")
struct WorkWindowTests {

    @Test("Standardfenster ist 8 bis 18 Uhr")
    func standardWindow() {
        #expect(WorkWindow.standard.startMinute == 480)
        #expect(WorkWindow.standard.endMinute == 1080)
    }

    @Test("Zeitpunkt im Fenster wird erkannt")
    func insideWindow() {
        #expect(WorkWindow.standard.contains(berlinDate(10, 0), calendar: berlinCalendar))
        #expect(WorkWindow.standard.contains(berlinDate(8, 0), calendar: berlinCalendar))
    }

    @Test("Zeitpunkt vor und nach dem Fenster liegt ausserhalb")
    func outsideWindow() {
        #expect(!WorkWindow.standard.contains(berlinDate(7, 59), calendar: berlinCalendar))
        #expect(!WorkWindow.standard.contains(berlinDate(18, 0), calendar: berlinCalendar))
        #expect(!WorkWindow.standard.contains(berlinDate(23, 0), calendar: berlinCalendar))
    }

    @Test("Fenster ueber Mitternacht funktioniert")
    func overnightWindow() {
        let night = WorkWindow(startHour: 22, endHour: 6)
        #expect(night.contains(berlinDate(23, 0), calendar: berlinCalendar))
        #expect(night.contains(berlinDate(5, 0), calendar: berlinCalendar))
        #expect(!night.contains(berlinDate(12, 0), calendar: berlinCalendar))
    }

    @Test("nextStart liefert den heutigen Start, wenn er noch bevorsteht")
    func nextStartToday() {
        let start = WorkWindow.standard.nextStart(after: berlinDate(6, 30), calendar: berlinCalendar)
        #expect(start == berlinDate(8, 0))
    }

    @Test("nextStart springt auf den Folgetag, wenn der Start vorbei ist")
    func nextStartTomorrow() {
        let start = WorkWindow.standard.nextStart(after: berlinDate(20, 0), calendar: berlinCalendar)
        #expect(start == berlinDate(8, 0, day: 10))
    }

    @Test("nextStart auf dem Start selbst zeigt auf den Folgetag")
    func nextStartAtStart() {
        // Der Start ist bereits erreicht, also ist der naechste erst morgen.
        let start = WorkWindow.standard.nextStart(after: berlinDate(8, 0), calendar: berlinCalendar)
        #expect(start == berlinDate(8, 0, day: 10))
    }

    @Test("nextStart trifft am Tag der Winterzeit-Umstellung 8:00 Wanduhrzeit")
    func nextStartOnDSTFallBack() {
        // 25.10.2026 hat 25 Stunden. Wer Minuten auf den Tagesbeginn addiert,
        // landet auf 07:00 — also ausserhalb des Fensters, der Countdown liefe
        // dann auf null, ohne dass etwas feuert.
        let date = berlinDate(year: 2026, month: 10, day: 25, hour: 3, minute: 0)
        let start = WorkWindow.standard.nextStart(after: date, calendar: berlinCalendar)
        #expect(start == berlinDate(year: 2026, month: 10, day: 25, hour: 8, minute: 0))
        #expect(WorkWindow.standard.contains(start, calendar: berlinCalendar))
    }

    @Test("nextStart trifft am Tag der Sommerzeit-Umstellung 8:00 Wanduhrzeit")
    func nextStartOnDSTSpringForward() {
        // 29.03.2026 hat 23 Stunden (02:00 bis 03:00 faellt aus).
        let date = berlinDate(year: 2026, month: 3, day: 29, hour: 1, minute: 0)
        let start = WorkWindow.standard.nextStart(after: date, calendar: berlinCalendar)
        #expect(start == berlinDate(year: 2026, month: 3, day: 29, hour: 8, minute: 0))
    }

    @Test("nextStart eines Nachtfensters trifft an der Umstellung 22:00")
    func nextStartOvernightOnDST() {
        let night = WorkWindow(startHour: 22, endHour: 6)
        let date = berlinDate(year: 2026, month: 10, day: 25, hour: 12, minute: 0)
        let start = night.nextStart(after: date, calendar: berlinCalendar)
        #expect(start == berlinDate(year: 2026, month: 10, day: 25, hour: 22, minute: 0))
        #expect(night.contains(start, calendar: berlinCalendar))
    }
}
