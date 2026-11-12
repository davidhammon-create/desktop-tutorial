import Foundation
import CoreGraphics

enum OrganonDemoData {

static let kanzleiName = "Hågemmøn & Partner"

static func laden() -> (knoten: [OrganonKnoten], kanten: [OrganonKante]) {
let knoten: [OrganonKnoten] = [
 // Gesellschaft
 OrganonKnoten(
  id: "org", typ: .gesellschaft, name: kanzleiName,
  untertitel: "Rechtsanwaltsgesellschaft · 47 Berufsträger",
  parentId: nil, posX: 400, posY: 80,
  mitarbeiterAnzahl: 47, standort: "Hamburg · Berlin · München"
 ),

 // Abteilungen / Dezernate (Organisationseinheiten -- klar getrennt von Personen)
 OrganonKnoten(id: "dz-straf", typ: .bereich, name: "Abteilung Strafrecht",
        untertitel: "Dezernat · Hamburg", parentId: "org", posX: 120, posY: 220,
        mitarbeiterAnzahl: 12, standort: "Hamburg"),
 OrganonKnoten(id: "dz-zivil", typ: .bereich, name: "Abteilung Zivilrecht",
        untertitel: "Dezernat · Hamburg", parentId: "org", posX: 320, posY: 220,
        mitarbeiterAnzahl: 14, standort: "Hamburg"),
 OrganonKnoten(id: "dz-corp", typ: .bereich, name: "Abteilung Corporate",
        untertitel: "Dezernat · Berlin", parentId: "org", posX: 520, posY: 220,
        mitarbeiterAnzahl: 11, standort: "Berlin"),
 OrganonKnoten(id: "dz-it", typ: .bereich, name: "Abteilung IT-Recht",
        untertitel: "Dezernat · München", parentId: "org", posX: 720, posY: 220,
        mitarbeiterAnzahl: 6, standort: "München"),
 OrganonKnoten(id: "dz-back", typ: .bereich, name: "Abteilung Backoffice",
        untertitel: "Sekretariat · Hamburg", parentId: "org", posX: 400, posY: 380,
        mitarbeiterAnzahl: 4, standort: "Hamburg"),

 // Teams
 OrganonKnoten(id: "tm-weco", typ: .team, name: "Team Wirtschaftsstrafrecht",
        parentId: "dz-straf", posX: 60, posY: 360, mitarbeiterAnzahl: 5),
 OrganonKnoten(id: "tm-owi", typ: .team, name: "Team Ordnungswidrigkeiten",
        parentId: "dz-straf", posX: 180, posY: 360, mitarbeiterAnzahl: 4),
 OrganonKnoten(id: "tm-miet", typ: .team, name: "Team Mietrecht",
        parentId: "dz-zivil", posX: 280, posY: 360, mitarbeiterAnzahl: 6),
 OrganonKnoten(id: "tm-mna", typ: .team, name: "Team M&A",
        parentId: "dz-corp", posX: 500, posY: 360, mitarbeiterAnzahl: 5),
 OrganonKnoten(id: "tm-dsgvo", typ: .team, name: "Team DSGVO & Compliance",
        parentId: "dz-it", posX: 700, posY: 360, mitarbeiterAnzahl: 4),

 // Personen -- Partner hängen DIREKT unter der Abteilung (nicht unter Team)
 person(id: "p-hagem", name: "Dr. Lars Hågemmøn", rolle: "Managing Partner",
    team: "dz-straf", pos: (60, 500),
    claim: "Verantwortet Konzernstrafrecht und Compliance-Programme",
    skills: ["Wirtschaftsstrafrecht", "Compliance", "Exportkontrolle"],
    projekte: ["Mandat Siemens Energy", "Mandat Nordbank"],
    kapazitaet: .ausgelastet, sprachen: ["Deutsch", "Englisch", "Norwegisch"]),
 person(id: "p-mueller", name: "Dr. Anna Müller", rolle: "Partnerin Corporate",
    team: "dz-corp", pos: (500, 500),
    claim: "Leitet M&A und Gesellschaftsrecht für Mittelstand",
    skills: ["M&A", "Gesellschaftsrecht", "Vertragsrecht"],
    projekte: ["Mandat TechVentures GmbH"],
    kapazitaet: .verfuegbar, sprachen: ["Deutsch", "Englisch"]),
 person(id: "p-schmidt", name: "RA Felix Schmidt", rolle: "Partner IT-Recht",
    team: "dz-it", pos: (700, 500),
    claim: "DSGVO, KI-Compliance und digitale Verträge",
    skills: ["DSGVO", "KI-Compliance", "SaaS-Verträge"],
    projekte: ["Mandat FenlynineOS Plattform"],
    kapazitaet: .verfuegbar, sprachen: ["Deutsch", "Englisch"]),

 // Associates / Berufsträger
 person(id: "a-weber", name: "RAin Sarah Weber", rolle: "Senior Associate",
    team: "tm-weco", pos: (40, 620),
    claim: "Wirtschaftsstrafrecht, Beweiswürdigung, Kronzeugenregelung",
    skills: ["Wirtschaftsstrafrecht", "Beweisrecht", "SAP-Migration"],
    projekte: ["Mandat Siemens Energy"],
    kapazitaet: .ausgelastet, sprachen: ["Deutsch", "Englisch", "Portugiesisch"]),
 person(id: "a-klein", name: "RA Jonas Klein", rolle: "Associate",
    team: "tm-miet", pos: (280, 620),
    claim: "Mietrecht, Wohnraummiete, Kündigungsschutz",
    skills: ["Mietrecht", "WEG-Recht"],
    projekte: ["Mandat Immobilien AG"],
    kapazitaet: .verfuegbar, sprachen: ["Deutsch"]),
 person(id: "a-fischer", name: "RAin Lisa Fischer", rolle: "Associate",
    team: "tm-dsgvo", pos: (680, 620),
    claim: "Datenschutz-Folgenabschätzung, AVV, Betriebsrat",
    skills: ["DSGVO", "BetrVG", "Datenschutz"],
    projekte: ["Mandat FenlynineOS Plattform"],
    kapazitaet: .verfuegbar, sprachen: ["Deutsch", "Englisch"]),
 person(id: "a-braun", name: "RA Tim Braun", rolle: "Werkstudent",
    team: "tm-owi", pos: (180, 620),
    claim: "Recherche, Aktenanalyse, Grid Technologies",
    skills: ["Recherche", "Grid Technologies"],
    projekte: [],
    kapazitaet: .verfuegbar, sprachen: ["Deutsch", "Englisch"]),

 // Vakanz
 OrganonKnoten(
  id: "vakanz-mna", typ: .person, name: "Offene Stelle",
  untertitel: "Senior Associate M&A", parentId: "tm-mna",
  posX: 560, posY: 620, rolle: "Vakanz",
  taetigkeitsclaim: "M&A-Transaktionen, Due Diligence",
  istVakanz: true
)
]

let kanten: [OrganonKante] = [
// Hierarchie
k("k1", "org", "dz-straf", .disziplinarisch),
k("k2", "org", "dz-zivil", .disziplinarisch),
k("k3", "org", "dz-corp", .disziplinarisch),
k("k4", "org", "dz-it", .disziplinarisch),
k("k5", "org", "dz-back", .disziplinarisch),
k("k6", "dz-straf", "tm-weco", .disziplinarisch),
k("k7", "dz-straf", "tm-owi", .disziplinarisch),
k("k8", "dz-zivil", "tm-miet", .disziplinarisch),
k("k9", "dz-corp", "tm-mna", .disziplinarisch),
k("k10", "dz-it", "tm-dsgvo", .disziplinarisch),
// Personen -> Eltern (Partner = Abteilung, Associates = Team) -- deckungsgleich mit parentId
k("k11", "dz-straf", "p-hagem", .disziplinarisch),
k("k12", "tm-weco", "a-weber", .disziplinarisch),
k("k13", "tm-miet", "a-klein", .disziplinarisch),
k("k14", "dz-corp", "p-mueller", .disziplinarisch),
k("k15", "dz-it", "p-schmidt", .disziplinarisch),
k("k16", "tm-dsgvo", "a-fischer", .disziplinarisch),
k("k17", "tm-owi", "a-braun", .disziplinarisch),
k("k18", "tm-mna", "vakanz-mna", .disziplinarisch),
// Quer-Verbindungen (Matrix / Projekte)
k("k19", "p-hagem", "a-weber", .projekt),
k("k20", "p-schmidt", "a-fischer", .projekt),
k("k21", "p-mueller", "a-klein", .fachlich),
k("k22", "a-weber", "a-fischer", .mandat),
k("k23", "p-hagem", "p-schmidt", .projekt)
]

return (knoten, kanten)
}

private static func k(_ id: String, _ von: String, _ zu: String, _ typ: OrganonKantenTyp) -> OrganonKante {
OrganonKante(id: id, vonId: von, zuId: zu, typ: typ)
}

private static func person(
id: String, name: String, rolle: String, team: String,
pos: (Double, Double), claim: String, skills: [String], projekte: [String],
kapazitaet: OrganonKapazitaet, sprachen: [String]
) -> OrganonKnoten {
OrganonKnoten(
id: id, typ: .person, name: name, parentId: team,
posX: pos.0, posY: pos.1,
rolle: rolle, taetigkeitsclaim: claim,
verantwortungen: Array(skills.prefix(3)),
projekte: projekte, skills: skills, sprachen: sprachen,
kapazitaet: kapazitaet,
ansprechthemen: skills
)
}
}

