import Foundation

/// Quelle der orthopaedischen Empfehlungen, die die Default-Intervalle begruenden.
/// Wird in den Einstellungen als anklickbarer Link angezeigt.
public enum RecommendationSource {
    public static let title = "Ergonomie am Bildschirmarbeitsplatz (DGUV / BAuA)"

    public static let summary =
        "Die Default-Intervalle orientieren sich an der 60-30-10-Faustregel "
        + "(rund 60 Prozent dynamisches Sitzen, 30 Prozent Stehen, 10 Prozent Bewegung) "
        + "sowie an den Hinweisen der Deutschen Gesetzlichen Unfallversicherung "
        + "(DGUV Information 215-410) und der BAuA."

    /// DGUV-Publikationen, Suche nach "215-410".
    public static let dguvURL = URL(string: "https://publikationen.dguv.de")!

    /// Bundesanstalt fuer Arbeitsschutz und Arbeitsmedizin.
    public static let bauaURL = URL(string: "https://www.baua.de")!

    /// Default-Quelle, die in den Einstellungen vorbelegt und anpassbar ist.
    public static let defaultURL = dguvURL
}
