# Konzept: Haltungs-App (Arbeitstitel)

> macOS-Menubar-App mit watchOS-Begleiter, die regelmäßig an Haltungskorrektur,
> Mikropausen und den Wechsel zwischen Sitzen und Stehen am höhenverstellbaren
> Tisch erinnert.

## 1. Vision & Problem

Lange Bildschirmarbeit am Schreibtisch führt zu statischer Dauerhaltung: krummer
Rücken, vorgeschobener Kopf, hochgezogene Schultern, dauerhaftes Sitzen oder
ebenso ermüdendes Dauerstehen. Der höhenverstellbare Tisch ist vorhanden, wird
aber zu selten umgestellt, weil der Impuls im Arbeitsfluss untergeht.

Die App löst genau diesen Impuls-Mangel: Sie sitzt unauffällig in der Menubar,
beobachtet die Zeit und stupst in sinnvollen Intervallen an. Nicht mit
erhobenem Zeigefinger, sondern als ruhiger Coach, der den nächsten
Haltungswechsel anbietet. Kernidee orthopädisch: nicht die eine perfekte Pose
zählt, sondern der **häufige Wechsel**.

## 2. Zielnutzer & Nutzungskontext

- **Primärnutzer:** André, Solo-Selbständiger, viele Stunden täglich am Mac.
- **Kontext:** Schreibtisch mit manuell verstellbarem Sitz-Steh-Tisch, Apple Watch am Handgelenk.
- **Plattform-Fokus:** macOS Menubar (dort wird gearbeitet, dort wirkt die Erinnerung sofort).
- **Begleiter:** Apple Watch für haptische Erinnerung am Handgelenk, weil Bildschirm-Notifications im Tunnel der Arbeit oft übersehen werden („Notification-Blindheit").

## 3. Orthopädische Grundlage

Kurz und fachlich belastbar; **keine medizinische Beratung**, sondern allgemein
anerkannte Ergonomie-Prinzipien für Bildschirmarbeit:

- **„Die beste Haltung ist die nächste Haltung."** Statische Dauerhaltung ist das eigentliche Problem, auch Dauerstehen. Häufiger Wechsel entlastet Bandscheiben, Muskulatur und Durchblutung.
- **Sitz-Steh-Wechsel:** Verhältnis grob 2:1 bis 1:1 (Sitzen:Stehen). Faustregel: Position etwa alle 30 Minuten wechseln, nicht länger als 30 bis 60 Minuten am Stück stehen.
- **Mikropausen:** Alle 20 bis 30 Minuten kurze Bewegung, aufstehen, lockern, ein paar Schritte.
- **Haltungs-Cues:** Brustbein heben, Schulterblätter sanft nach hinten und unten, Kinn leicht zurück (Chin-Tuck) gegen den „Geierhals", Becken aufrichten.
- **20-20-20-Regel für die Augen:** Alle 20 Minuten für 20 Sekunden etwa 6 Meter in die Ferne schauen, gegen Bildschirm-Ermüdung.
- **Mobilisations-Mikroübungen:** je 20 bis 40 Sekunden, bürotauglich, ohne Geräte.

**Quelle der Empfehlungen:** Die Werte orientieren sich an der bekannten
60-30-10-Faustregel für dynamisches Büroarbeiten (rund 60 % dynamisches Sitzen,
30 % Stehen, 10 % aktive Bewegung) sowie an den Hinweisen der Deutschen
Gesetzlichen Unfallversicherung. Referenz: DGUV Information 215-410
„Bildschirm- und Büroarbeitsplätze" und die Hinweise der BAuA zu
Bewegung am Arbeitsplatz.

- DGUV Publikationen (Suche „215-410"): https://publikationen.dguv.de
- BAuA, Büroarbeit / Bewegung: https://www.baua.de

Dieser Link ist in den App-Einstellungen direkt anklickbar hinterlegt (siehe
Abschnitt 5 und 10), damit die Begründung der Intervalle jederzeit nachvollziehbar bleibt.

## 4. Erinnerungstypen (Kern-Tabelle)

| Typ | Default-Intervall | Modalität | Beispiel-Cue |
|---|---|---|---|
| Sitz-Steh-Wechsel | 30 min | Notification + Sound + Overlay | „Zeit zum Aufstehen. Tisch hochfahren und im Stehen weiterarbeiten." |
| Haltungs-Cue | 15 min | Notification (leise) | „Brustbein heben, Schultern locker nach hinten-unten, Kinn zurück." |
| Mikropause | 25 min | Notification + Overlay | „Kurz aufstehen, Schultern kreisen, ein paar Schritte gehen." |
| Augenpause (20-20-20) | 20 min | Notification (leise) | „Blick für 20 Sekunden in die Ferne, etwa 6 Meter weg." |
| Mobilisationsübung | 45 min | Overlay mit Übung | rotierend: Chin-Tuck, Brustkorb öffnen, Schulterkreisen, Nacken-Seitneige, Hüftbeuger-Dehnung, Handgelenke |

Diese Tabelle ist **vollständig konfigurierbar**. Die hier gezeigten Werte sind
nur Defaults. In den Einstellungen kann André pro Zeile:

- den Erinnerungstyp **aktivieren oder deaktivieren**,
- das **Intervall** (Minuten) frei setzen,
- die **Modalität** wählen (leise Notification | Notification + Sound | zusätzlich Glass-Overlay),
- den **Cue-Text** anpassen oder eigene Texte hinterlegen,
- die **Priorität** bei Kollision festlegen,
- eigene Erinnerungstypen **hinzufügen** oder vorhandene **entfernen**.

Die Intervalle sind bewusst nicht synchron, damit nicht alles gleichzeitig
auslöst; bei Kollision greift die konfigurierte Priorisierung (Default:
Sitz-Steh-Wechsel vor Mikropause vor reinem Cue). Über „Auf Standard
zurücksetzen" lassen sich die orthopädisch begründeten Defaults jederzeit
wiederherstellen.

## 5. Funktionsumfang MVP

- **Menubar-Icon mit Status:** zeigt aktuelle Phase (Sitzen | Stehen) und Zeit bis zur nächsten Erinnerung. Icon-Zustand wechselt je nach Phase.
- **Konfigurierbare Erinnerungstypen-Tabelle:** vollständige Verwaltung aller Zeilen (an/aus, Intervall, Modalität, Cue-Text, Priorität, eigene Typen hinzufügen/entfernen, „Auf Standard zurücksetzen").
- **Quellen-Link in den Einstellungen:** anklickbarer Verweis auf die Grundlage der empfohlenen Default-Intervalle (DGUV / BAuA, siehe Abschnitt 3), damit nachvollziehbar bleibt, warum die Standardwerte so gesetzt sind.
- **Arbeitszeitfenster:** App erinnert nur innerhalb eines definierten Zeitfensters (z.B. 8:00 bis 18:00), keine Störung abends.
- **Aktionen pro Erinnerung:** „Erledigt" (bestätigt und startet das nächste Intervall) und „Snooze" (z.B. 5 oder 10 Minuten verschieben).
- **Mittlere Aufdringlichkeit:** Notification + dezenter Sound; bei wichtigen Erinnerungen (Sitz-Steh-Wechsel, Mobilisation) zusätzlich ein kurzes Liquid-Glass-Overlay-Panel mit dem Übungs-Cue und einem großen „Erledigt"-Button. Leise Cues kommen nur als Notification.
- **Tagesstatistik:** Anzahl Sitz-Steh-Wechsel, geschätzte Stehzeit, erledigte vs. gesnoozte Erinnerungen.

## 6. watchOS-Begleiter

- **Haptischer Tap** am Handgelenk synchron zur Mac-Erinnerung, damit sie nicht im Bildschirm-Tunnel untergeht.
- **„Erledigt"-Bestätigung** direkt von der Watch, ohne zum Mac greifen zu müssen.
- **Kompakte Anzeige** des aktuellen Cues (Sitzen | Stehen, nächste Übung).
- **Sync** mit dem Mac über die übliche Watch-Connectivity, damit Statistik und Phase konsistent bleiben.

## 7. Architektur-Skizze

- **Projektgenerierung:** XCGen `project.yml` mit zwei Targets (macOS App, watchOS App) und Source-Sharing per `excludes`, analog zu `menubar-social`.
- **UI:** `MenuBarExtra` für die Menubar; SwiftUI-Views je Plattform; Liquid-Glass-Overlay-Panel als `NSPanel`/`NSHostingView` (macOS-only).
- **State:** `@Observable @MainActor` ViewModels, plattformunabhängig geteilt.
- **Scheduling:** Timer- und Erinnerungs-Service als `actor`, der die nächste fällige Erinnerung berechnet.
- **Notifications:** `UNUserNotificationCenter` für System-Notifications und Sound.
- **Persistenz:** SwiftData für Settings und Event-Log (Statistik).
- **Geteilte Schichten:** Models, Services, ViewModels shared; Views und App-Entry pro Plattform.

## 8. Erinnerungs-Engine (Logik)

- **Phasenmodell:** Zustand Sitzen ↔ Stehen, der mit jedem bestätigten Sitz-Steh-Wechsel kippt; Stehzeit wird gemessen.
- **Intervall-Scheduler:** pro aktivem Erinnerungstyp ein eigener nächster Fälligkeitszeitpunkt; der Service feuert den jeweils nächsten und respektiert Prioritäten bei Kollision.
- **Pausenlogik:** keine Erinnerung außerhalb des Arbeitszeitfensters; keine Erinnerung wenn der Mac gesperrt ist (kein Sinn). Fokus-Modus-Awareness (still bei „Nicht stören" / Meeting) als spätere Ausbaustufe.
- **Snooze-Verhalten:** verschiebt nur die betroffene Erinnerung um den Snooze-Wert, ohne die übrigen Timer zu stören.
- **Stummschaltung:** manuelle Ruhe für 1, 1,5 oder 2 Stunden über das Menubar-Popup, für Meetings und Fokusblöcke. Wirkt global über alle Erinnerungen, überlebt einen Neustart und ist jederzeit vorzeitig beendbar. Die einzelnen Takte laufen währenddessen weiter, damit nach der Stille sofort dran ist, was fällig geworden ist. Das ist die benutzergesteuerte Vorstufe zur automatischen Fokus-Modus-Awareness (Phase 2b).

## 9. Design (Liquid Glass)

Gemäß Swift-Projekt-Konvention durchgängig Liquid Glass (macOS 26 Tahoe):

- **Menubar-Symbolzustände:** ruhiges Symbol für Sitzen, betontes für Stehen, dezenter Hinweis-Zustand kurz vor einer fälligen Erinnerung.
- **Glass-Overlay-Panel:** kleines, schwebendes `.regular`-Glass-Panel mit dem Übungs-Cue, optional einer einfachen Illustration und einem großen „Erledigt"-Button (`.buttonStyle(.glass)`, `.interactive()`).
- **Farbsemantik:** zurückhaltende Tint-Farben für Sitzen vs. Stehen (`.tint`), Glass nur auf Control-Ebene, nie auf dem Inhalt.
- **Ruhe vor Show:** Das Panel soll einladen, nicht erschrecken; sanftes Einblenden, automatisches Ausblenden nach Bestätigung oder Timeout.

## 10. Datenmodell

- **ReminderType (konfigurierbar, eigene Entität):** Name, aktiv, Intervall (Minuten), Modalität (leise | Sound | Overlay), Cue-Text, Priorität, Reihenfolge. Damit ist die Erinnerungstypen-Tabelle aus Abschnitt 4 datengetrieben und vom Nutzer editierbar; ein Seed legt die orthopädischen Defaults an, „Auf Standard zurücksetzen" stellt sie wieder her.
- **Settings:** Arbeitszeitfenster (Start, Ende), Snooze-Dauer, Ende einer laufenden Stummschaltung, globaler Sound an/aus, globaler Overlay an/aus, hinterlegte **Quellen-URL** der Empfehlungen (Default: DGUV/BAuA, in den Einstellungen anklickbar und bei Bedarf anpassbar).
- **Event-Log:** Zeitstempel, Erinnerungstyp, Ergebnis (erledigt | gesnoozt | verpasst), Phase zum Zeitpunkt. Basis für die Tagesstatistik und spätere Auswertungen.

## 11. Ausbaustufen (Roadmap)

| Phase | Inhalt | Aufwand |
|---|---|---|
| 1 (MVP) | macOS-Menubar mit Erinnerungen, Overlay, Statistik | ★★★☆☆ |
| 1b | watchOS-Begleiter mit Haptik und Sync | +★★☆☆☆ |
| 2 | Aktive Tischsteuerung per Bluetooth (Linak / IKEA Idåsen) als optionales Modul | ★★★★☆ |
| 2b | Fokus-Modus-Awareness (still bei Meetings / „Nicht stören") — manuelle Stummschaltung ist umgesetzt, offen ist die automatische Erkennung | ★★☆☆☆ |
| 3 | iOS-Begleiter, Notion-Anbindung (Stehzeit ins Business-Journal / Habit-Tracking) | ★★★☆☆ |

Die aktive Tischsteuerung ist bewusst nicht im MVP: Sie hängt von einem
kompatiblen Tisch und Bluetooth-Reverse-Engineering ab. Das Erinnerungs-Konzept
funktioniert komplett unabhängig davon.

## 12. Deployment-Pfad

Gemäß Swift-CLAUDE.md, analog zu `notion-sync` und `menubar-social`:

- **Build:** XCGen (`xcodegen generate`), Fastlane-Standard-Lanes (`test`, `start`, `release`, `install`, `update`).
- **Distribution macOS:** GitLab Generic Package Registry, ZIP per CI bei Tag `v*.*.*`, Bezug über `fastlane install` / `fastlane update`. Umgesetzt.
- **Versionierung:** `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` in pbxproj (Xcode-Targets); Build-Nummer per xcodebuild-Override, nicht per `increment_build_number`.
- **watchOS-Verteilung:** offen, ob lokaler Ad-hoc-Build reicht oder TestFlight nötig ist (watchOS-Apps lassen sich schwer ad-hoc verteilen, siehe offene Fragen).

## 13. Offene Fragen / Annahmen

- **Default-Intervalle:** Die Werte in der Tabelle (30/25/20/15 min) sind Vorschläge; André sollte gegenprüfen, ob das im Alltag zu häufig oder zu selten ist.
- **Arbeitszeitfenster:** Default 8:00 bis 18:00 angenommen, anpassbar.
- **watchOS-Verteilung:** Ad-hoc vs. TestFlight klären; ggf. beginnt Phase 1 rein macOS und die Watch folgt, sobald der Verteilweg steht.
- **Sound-Auswahl:** dezenter System-Sound vs. eigener; mit mittlerer Aufdringlichkeit abgestimmt.
- **Overlay-Trigger:** nur für „schwere" Erinnerungen (Sitz-Steh, Mobilisation) oder für alle? Vorschlag: nur schwere, um nicht zu nerven.

## 14. Aufwandsschätzung

| Baustein | Aufwand |
|---|---|
| MVP macOS-Menubar (Engine, Notifications, Overlay, Statistik) | ★★★☆☆ |
| watchOS-Begleiter (Haptik, Sync) | ★★☆☆☆ |
| Aktive Tischsteuerung (Phase 2, Bluetooth) | ★★★★☆ |

## Nächster Schritt

Nach inhaltlicher Freigabe dieses Konzepts: GitLab-Issue anlegen (gemäß
Projects-Konvention), dann XCGen-Projekt aufsetzen und mit dem macOS-MVP starten.
