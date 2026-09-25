import Foundation

/// Art einer Erinnerung. Bestimmt Standardverhalten und Icon, ist aber pro
/// Eintrag in der konfigurierbaren Tabelle frei kombinierbar.
public enum ReminderKind: String, Codable, CaseIterable, Sendable {
    /// Wechsel zwischen Sitzen und Stehen am hoehenverstellbaren Tisch.
    case sitStand
    /// Reiner Haltungs-Cue (Brustbein heben, Schultern zurueck, Kinn zurueck).
    case postureCue
    /// Kurze Bewegungspause (aufstehen, lockern, ein paar Schritte).
    case microBreak
    /// Augenpause nach der 20-20-20-Regel.
    case eyeBreak
    /// Mobilisations-Mikrouebung.
    case mobility
    /// Frei definierter, eigener Erinnerungstyp.
    case custom

    /// SF-Symbol-Name fuer die Darstellung in der App.
    public var systemImageName: String {
        switch self {
        case .sitStand: return "figure.stand"
        case .postureCue: return "figure.walk.motion"
        case .microBreak: return "figure.flexibility"
        case .eyeBreak: return "eye"
        case .mobility: return "figure.cooldown"
        case .custom: return "bell"
        }
    }

    /// Ausfuehrliche Schritt-fuer-Schritt-Anleitung, was bei dieser Haltung zu
    /// tun ist. Wird im Info-Panel unter dem Piktogramm angezeigt. Fuer eigene
    /// Erinnerungen leer (dort traegt der Cue-Text die Anweisung).
    public var howTo: String {
        switch self {
        case .sitStand:
            return """
            1. Tisch in Stehhöhe fahren.
            2. Füße hüftbreit, Gewicht gleichmäßig verteilen.
            3. Becken aufrichten, Knie locker lassen.
            4. Bildschirmoberkante etwa auf Augenhöhe prüfen.
            """
        case .postureCue:
            return """
            1. Brustbein leicht anheben.
            2. Schulterblätter sanft nach hinten und unten ziehen.
            3. Kinn leicht zurücknehmen (Chin-Tuck).
            4. Ruhig weiteratmen.
            """
        case .microBreak:
            return """
            1. Kurz aufstehen.
            2. Schultern 5 mal langsam kreisen.
            3. Ein paar Schritte gehen.
            4. Arme locker ausschütteln.
            """
        case .eyeBreak:
            return """
            1. Vom Bildschirm wegschauen.
            2. 20 Sekunden in die Ferne sehen, etwa 6 Meter weit.
            3. Ein paar Mal bewusst blinzeln.
            """
        case .mobility:
            return """
            1. Chin-Tuck: Kinn zurücknehmen, 5 Sekunden halten.
            2. Brustkorb öffnen, Hände locker hinter den Kopf.
            3. Schultern langsam kreisen.
            4. Sanfte Nacken-Seitneige je Seite, kurz halten.
            """
        case .custom:
            return ""
        }
    }

    /// Phasenabhängige Anleitung. Nur der Sitz-Steh-Wechsel unterscheidet
    /// Aufstehen (im Sitzen) und Hinsetzen (im Stehen); alle anderen Haltungen
    /// liefern ihre normale Anleitung.
    public func howTo(for phase: Phase) -> String {
        guard self == .sitStand else { return howTo }
        switch phase {
        case .sitting:
            return howTo
        case .standing:
            return """
            1. Tisch in Sitzhöhe herunterfahren.
            2. Tief in den Stuhl setzen, Rücken anlehnen.
            3. Füße flach auf den Boden, Knie etwa rechtwinklig.
            4. Schultern locker lassen, Bildschirm auf Augenhöhe prüfen.
            """
        }
    }

    /// Phasenabhängiger Kurz-Cue für den Sitz-Steh-Wechsel. Für andere Haltungen
    /// nil (dort gilt der frei editierbare Cue-Text der Erinnerung).
    public func directionalCue(for phase: Phase) -> String? {
        guard self == .sitStand else { return nil }
        switch phase {
        case .sitting:
            return "Zeit zum Aufstehen. Tisch hochfahren und im Stehen weiterarbeiten."
        case .standing:
            return "Zeit zum Hinsetzen. Tisch herunterfahren und wieder im Sitzen weiterarbeiten."
        }
    }

    /// Lesbarer deutscher Name.
    public var displayName: String {
        switch self {
        case .sitStand: return "Sitz-Steh-Wechsel"
        case .postureCue: return "Haltungs-Cue"
        case .microBreak: return "Mikropause"
        case .eyeBreak: return "Augenpause"
        case .mobility: return "Mobilisationsübung"
        case .custom: return "Eigene Erinnerung"
        }
    }
}
