//
//  JurisdictionConfig.swift
//  Swift-Pendant zu src/lib/jurisdictionConfig.js.
//
//  Enthält 1:1 die Daten der JS-Datei:
//    - JURISDICTIONS (Liste der Codes)
//    - JURISDICTION_META (Flag, Name (DE/EN/FR), System, Währung)
//    - AI-Kontextstrings je Jurisdiktion (inkl. optionalem US-Bundesstaat)
//    - UI-Texte in DE / EN / FR (TEXTS-Map)
//    - Lookup-Funktionen getT(jurisdiction:) und getTByLanguage(lang:)
//
//  Pure Foundation, keine externen Dependencies. macOS 14+.
//

import Foundation

public enum JurisdictionConfig {

    // MARK: - Jurisdiktions-Codes

    /// Identische Schlüssel wie in `JURISDICTIONS` (JS).
    public enum Jurisdiction: String, Codable, Hashable, CaseIterable, Sendable {
        case DE, AT, CH, LI, LU, SE, NO, DK, FI, US
    }

    // MARK: - Sprach-Codes für `getTByLanguage`

    public enum Language: String, Codable, Hashable, CaseIterable, Sendable {
        case DE, EN, FR
    }

    // MARK: - Meta-Strukturen

    /// Mehrsprachiger Name einer Jurisdiktion (DE/EN/FR).
    public struct LocalizedName: Codable, Hashable, Sendable {
        public let de: String
        public let en: String
        public let fr: String

        public init(de: String, en: String, fr: String) {
            self.de = de
            self.en = en
            self.fr = fr
        }
    }

    /// Meta-Daten zu einer Jurisdiktion (Flag, Name, Rechtssystem, Währung).
    public struct JurisdictionMeta: Codable, Hashable, Sendable {
        public let flag: String
        public let name: LocalizedName
        public let system: String
        public let currency: String

        public init(flag: String, name: LocalizedName, system: String, currency: String) {
            self.flag = flag
            self.name = name
            self.system = system
            self.currency = currency
        }
    }

    // MARK: - JURISDICTION_META

    /// 1:1-Übernahme von `JURISDICTION_META` aus dem JS-Modul.
    public static let meta: [Jurisdiction: JurisdictionMeta] = [
        .DE: JurisdictionMeta(
            flag: "🇩🇪",
            name: LocalizedName(de: "Deutschland", en: "Germany", fr: "Allemagne"),
            system: "ZPO / BGB / StPO",
            currency: "€"
        ),
        .AT: JurisdictionMeta(
            flag: "🇦🇹",
            name: LocalizedName(de: "Österreich", en: "Austria", fr: "Autriche"),
            system: "ZPO / ABGB / StPO",
            currency: "€"
        ),
        .CH: JurisdictionMeta(
            flag: "🇨🇭",
            name: LocalizedName(de: "Schweiz", en: "Switzerland", fr: "Suisse"),
            system: "ZPO / OR / ZGB",
            currency: "CHF"
        ),
        .LI: JurisdictionMeta(
            flag: "🇱🇮",
            name: LocalizedName(de: "Liechtenstein", en: "Liechtenstein", fr: "Liechtenstein"),
            system: "ZPO / PGR",
            currency: "CHF"
        ),
        .LU: JurisdictionMeta(
            flag: "🇱🇺",
            name: LocalizedName(de: "Luxemburg", en: "Luxembourg", fr: "Luxembourg"),
            system: "Code de procédure civile",
            currency: "€"
        ),
        .SE: JurisdictionMeta(
            flag: "🇸🇪",
            name: LocalizedName(de: "Schweden", en: "Sweden", fr: "Suède"),
            system: "Rättegångsbalken",
            currency: "SEK"
        ),
        .NO: JurisdictionMeta(
            flag: "🇳🇴",
            name: LocalizedName(de: "Norwegen", en: "Norway", fr: "Norvège"),
            system: "Tvisteloven",
            currency: "NOK"
        ),
        .DK: JurisdictionMeta(
            flag: "🇩🇰",
            name: LocalizedName(de: "Dänemark", en: "Denmark", fr: "Danemark"),
            system: "Retsplejeloven",
            currency: "DKK"
        ),
        .FI: JurisdictionMeta(
            flag: "🇫🇮",
            name: LocalizedName(de: "Finnland", en: "Finland", fr: "Finlande"),
            system: "Oikeudenkäymiskaari",
            currency: "€"
        ),
        .US: JurisdictionMeta(
            flag: "🇺🇸",
            name: LocalizedName(de: "USA", en: "United States", fr: "États-Unis"),
            system: "Common Law / FRCP",
            currency: "$"
        )
    ]

    // MARK: - AI-Kontext

    /// Liefert den (englischen) System-Prompt für die jeweilige Jurisdiktion.
    /// Für US wird optional der Bundesstaat in den Prompt eingewoben.
    public static func aiContext(for jurisdiction: Jurisdiction, usState: String? = nil) -> String {
        switch jurisdiction {
        case .DE:
            return "You are an expert German attorney. Apply German law strictly: ZPO, BGB, StGB, HGB. Reference specific paragraphs (§§). Follow BGH and BVerfG case law. Use precise German legal terminology."
        case .AT:
            return "You are an expert Austrian attorney. Apply Austrian law: ZPO, ABGB, StGB. Reference OGH decisions. Distinguish from German law where relevant. Use Austrian legal terminology."
        case .CH:
            return "You are an expert Swiss attorney. Apply Swiss law: ZPO, OR, ZGB, StGB. Reference BGer/Tribunal fédéral decisions. Note cantonal variations where relevant."
        case .LI:
            return "You are an expert Liechtenstein attorney. Apply Liechtenstein law including the PGR (Personen- und Gesellschaftsrecht). Note similarities to Austrian law."
        case .LU:
            return "You are an expert Luxembourg attorney. Apply Luxembourg law based on French civil law tradition. Reference Cour d'appel and Cour de cassation decisions. Note EU law primacy."
        case .SE:
            return "You are an expert Swedish attorney. Apply Swedish law under the Rättegångsbalken. Reference Högsta domstolen decisions. Note Nordic legal tradition."
        case .NO:
            return "You are an expert Norwegian attorney. Apply Norwegian law under the Tvisteloven. Reference Høyesterett decisions."
        case .DK:
            return "You are an expert Danish attorney. Apply Danish law under the Retsplejeloven. Reference Højesteret decisions."
        case .FI:
            return "You are an expert Finnish attorney. Apply Finnish law under the Oikeudenkäymiskaari. Reference Korkein oikeus decisions. Note bilingual (Finnish/Swedish) legal system."
        case .US:
            // Originale JS-Logik: Wenn ein US-Bundesstaat angegeben ist,
            // wird er an mehreren Stellen des Prompts eingesetzt.
            let stateSpec = usState.map { " specializing in \($0) law" } ?? ""
            let stateOrState = usState ?? "state"
            let rulesSpec = usState.map { "\($0) Rules of Civil Procedure, " } ?? ""
            return "You are an expert American attorney\(stateSpec). Apply US federal and \(stateOrState) law. Reference FRCP, applicable federal statutes, \(rulesSpec)and relevant case law. Use IRAC structure."
        }
    }

    /// String-API analog zur JS-Funktion: nicht-unterstützte Werte fallen auf DE zurück.
    public static func aiContext(jurisdictionCode: String, usState: String? = nil) -> String {
        let jur = Jurisdiction(rawValue: jurisdictionCode) ?? .DE
        return aiContext(for: jur, usState: usState)
    }

    // MARK: - UI-Texte

    /// Container für alle übersetzten UI-Strings einer Sprache.
    /// Felder spiegeln das JS-Objekt 1:1.
    public struct UITexts: Sendable {

        // -- Plattform
        public let platform: String
        public let platformSub: String
        public let copyright: String
        public let dsgvo: String

        // -- KI-Analyse
        public let kiFallanalyse: String
        public let analyseStarten: String
        public let analyseWarning: String
        public let fallAuswaehlen: String

        // -- KPI-Labels
        public let aktiveFaelleLabel: String
        public let offeeneFristenLabel: String
        public let avgPrognoseLabel: String
        public let argumenteLabel: String

        // -- Charts
        public let faelleNachRechtsgebiet: String
        public let statusVerteilung: String
        public let prognoseVerteilung: String
        public let fristenUebersicht: String
        public let naechste14Tage: String
        public let instanzVerteilung: String
        public let risikoverteilung: String
        public let rechtsgebiet: String
        public let gericht: String
        public let instanz: String
        public let aktiv: String
        public let streitwert: String
        public let prognose: String

        // -- Allgemein
        public let noDataLabel: String
        public let noDeadlinesRecorded: String
        public let noUpcomingDeadlines: String
        public let loading: String
        public let saveBtn: String
        public let cancelBtn: String
        public let updateBtn: String
        public let createBtn: String
        public let backLabel: String
        public let searchPlaceholder: String
        public let todayLabel: String
        public let tomorrowLabel: String

        /// Funktional: `(n) => "${n}d überfällig"` etc.
        public let daysOverdueLabel: @Sendable (Int) -> String
        public let inDaysLabel: @Sendable (Int) -> String

        // -- Geteilte Subtitle-Helpers
        public let mandatesSub: @Sendable (Int, Int) -> String
        public let ofTotalLabel: @Sendable (Int) -> String
        public let winProbabilityLabel: String
        public let totalRecordedLabel: String
        public let filterResetBtn: String
        public let noDataShort: String
        public let noDeadlinesShort: String
        public let todayShort: String
        public let noUpcomingShort: String

        // -- FallAssistentChat
        public let conversationLabel: String
        public let lexTitle: String
        public let lexDescription: String
        public let newConversationBtn: String
        public let loadingLabel: String
        public let noConversationsYet: String
        public let chatInputPlaceholder: String
        public let quickPrompts: [String]

        // -- LexaraDashboard
        public let caseOverview: String
        public let mandatesTotalSub: @Sendable (Int, Int) -> String
        public let searchCase: String
        public let newCase: String
        public let createCaseTitle: String
        public let caseNamePlaceholder: String
        public let fileNumberPlaceholder: String
        public let legalAreaPlaceholder: String
        public let createButton: String
        public let progressLabel: String
        public let stepsLabel: String
        public let argsLabel: String
        public let evidenceLabel: String
        public let personsLabel: String
        public let deadlinesLabel: String
        public let noCasesTitle: String
        public let noCasesSubtitle: String
        public let statusOptions: [String]
        public let instanzOptions: [String]

        // -- KanzleiCockpit
        public let cockpitTitle: String
        public let portfolioSub: @Sendable (Int) -> String
        public let newCaseLinkLabel: String
        public let totalClaimLabel: String
        public let allMandatesSub: String
        public let avgPrognosisLabel: String
        public let weightedAvgSub: String
        public let overdueDeadlinesLabel: String
        public let actNow: String
        public let allOnTrack: String
        public let highRiskLabel: String
        public let noHighRisk: String
        public let topChancesLabel: String
        public let noTopChancesText: String
        public let nextDeadlinesLabel: String
        public let showAllLink: String
        public let noOpenDeadlinesText: String
        public let allMandatesLabel: String
        public let entriesLabel: @Sendable (Int) -> String
        public let tableHeaderCase: String
        public let tableHeaderCourt: String
        public let tableHeaderClaimValue: String
        public let tableHeaderStatus: String
        public let casesLabelShort: String

        // -- RichterProfile
        public let judgeProfilesTitle: String
        public let profilesSub: @Sendable (Int) -> String
        public let addJudgeBtn: String
        public let editProfileTitle: String
        public let newProfileTitle: String
        public let namePlaceholder: String
        public let courtPlaceholder: String
        public let chamberPlaceholder: String
        public let plaintiffRateLabel: String
        public let settlementRateLabel: String
        public let avgDurationLabel: String
        public let totalRulingsLabel: String
        public let knownForPlaceholder: String
        public let notesPlaceholder: String
        public let linkToCase: String
        public let selectCasePlaceholder: String
        public let detailsAI: String
        public let noProfilesTitle: String
        public let noProfilesSub: String
        public let plaintiffRateBar: String
        public let settlementRateBar: String
        public let avgMonthsSuffix: String
        public let rulingsLabelShort: String
        public let experiencesLabelShort: String
        public let kiAnalysisExists: String

        // -- RichterDetail
        public let backToOverview: String
        public let experiencesSection: String
        public let addExperience: String
        public let dateLabel: String
        public let authorLabel: String
        public let caseContextLabel: String
        public let settlementReadiness: String
        public let decisionSpeed: String
        public let expertiseLabel: String
        public let experienceReport: String
        public let noExperiencesYet: String
        public let addFirstExperience: String
        public let kiTacticsTitle: String
        public let reanalyzeBtn: String
        public let startAnalysisBtn: String
        public let analyzingBtn: String
        public let kiAnalysisHint: String
        public let lastAnalysis: String
        public let kiCreditWarning: String
        public let summaryLabel: String
        public let foundRulingsLabel: String
        public let argumentationPatternsLabel: String
        public let preferredNormsLabel: String
        public let argumentStanceLabel: String
        public let preferredMotionsLabel: String
        public let damageRangeLabel: String
        public let evidenceHandlingLabel: String
        public let plaintiffStrengthsLabel: String
        public let plaintiffRisksLabel: String
        public let doLabel: String
        public let dontLabel: String
        public let tacticalTipsLabel: String
        public let settlementStrategyLabel: String
        public let timingLabel: String
        public let overallAssessmentLabel: String
        public let anonLabel: String
        public let settlementBar: String
        public let speedBar: String
        public let resultLabel: String
        public let sourceLabel: String
        public let parametersLabel: String
        public let successRateLabel: String
        public let typicalRangeLabel: String
        public let factorsLabel: String
        public let specialFeaturesLabel: String
        public let stanceLabel: String
        public let reasonLabel: String

        // -- Zeitleiste
        public let timelineTitle: String
        public let iCalExport: String
        public let filterAll: String
        public let filterOpen: String
        public let filterCritical: String
        public let filterCompleted: String
        public let noDeadlinesFound: String
        public let openStatusLabel: String
        public let criticalStatusLabel: String
        public let doneStatus: String
        public let missedStatus: String

        // -- PlattformAgent
        public let newSession: String
        public let sessionsLabel: String
        public let noSessionsYet: String
        public let platformAgentTitle: String
        public let platformAgentDesc: String
        public let nextTaskPlaceholder: String
        public let customTaskPlaceholder: String
        public let agentNote: String

        // -- Module-Liste
        public struct ModuleEntry: Codable, Hashable, Sendable {
            public let category: String
            public let title: String
            public let description: String
            public init(category: String, title: String, description: String) {
                self.category = category
                self.title = title
                self.description = description
            }
        }
        public let module: [ModuleEntry]
    }

    // MARK: - Texte: Deutsch

    public static let deText: UITexts = UITexts(
        platform: "Ihre KI-gestützte Rechtsplattform",
        platformSub: "Strategische Fallanalyse & Intelligente Prozessführung",
        copyright: "© 2026 MachiavelLEX · Alle Rechte vorbehalten",
        dsgvo: "DSGVO-konform · EU-Server",

        kiFallanalyse: "KI-Fallanalyse",
        analyseStarten: "KI-Analyse starten",
        analyseWarning: "Diese Analyse ist eine KI-gestützte Einschätzung und ersetzt keine Rechtsberatung.",
        fallAuswaehlen: "Fall auswählen",

        aktiveFaelleLabel: "Aktive Fälle",
        offeeneFristenLabel: "Offene Fristen",
        avgPrognoseLabel: "Ø Prognose",
        argumenteLabel: "Argumente",

        faelleNachRechtsgebiet: "Fälle nach Rechtsgebiet",
        statusVerteilung: "Status-Verteilung",
        prognoseVerteilung: "Prognose-Verteilung",
        fristenUebersicht: "Fristen-Übersicht",
        naechste14Tage: "Nächste 14 Tage",
        instanzVerteilung: "Instanz-Verteilung",
        risikoverteilung: "Risikoverteilung",
        rechtsgebiet: "Rechtsgebiet",
        gericht: "Gericht",
        instanz: "Instanz",
        aktiv: "Status",
        streitwert: "Streitwert",
        prognose: "Prognose",

        noDataLabel: "Keine Daten",
        noDeadlinesRecorded: "Keine Fristen erfasst",
        noUpcomingDeadlines: "Keine bevorstehenden Fristen",
        loading: "Laden…",
        saveBtn: "Speichern",
        cancelBtn: "Abbrechen",
        updateBtn: "Aktualisieren",
        createBtn: "Erstellen",
        backLabel: "Zurück",
        searchPlaceholder: "Suchen…",
        todayLabel: "Heute",
        tomorrowLabel: "Morgen",
        daysOverdueLabel: { n in "\(n)d überfällig" },
        inDaysLabel: { n in "in \(n) Tagen" },

        mandatesSub: { total, active in "\(total) Mandate · \(active) aktiv" },
        ofTotalLabel: { n in "von \(n) gesamt" },
        winProbabilityLabel: "Erfolgswahrscheinlichkeit",
        totalRecordedLabel: "gesamt erfasst",
        filterResetBtn: "Zurücksetzen",
        noDataShort: "Keine Daten",
        noDeadlinesShort: "Keine Fristen erfasst",
        todayShort: "Heute",
        noUpcomingShort: "Keine bevorstehenden Fristen",

        conversationLabel: "Gespräch",
        lexTitle: "Lex · Fall-Assistent",
        lexDescription: "Ich kann Fälle analysieren, Fristen überwachen, Argumente verwalten und strategische Empfehlungen geben.",
        newConversationBtn: "Neues Gespräch",
        loadingLabel: "Lädt…",
        noConversationsYet: "Noch keine Gespräche",
        chatInputPlaceholder: "Juristische Frage stellen oder Fall-Daten verwalten…",
        quickPrompts: [
            "Zeige mir alle offenen Fristen",
            "Analysiere meinen stärksten Fall",
            "Welche Argumente fehlen noch?",
            "Gib mir eine Risikoübersicht"
        ],

        caseOverview: "Fallübersicht",
        mandatesTotalSub: { total, active in "\(total) Mandate · \(active) aktiv" },
        searchCase: "Fall suchen…",
        newCase: "Neuer Fall",
        createCaseTitle: "Neuen Fall anlegen",
        caseNamePlaceholder: "Fallname *",
        fileNumberPlaceholder: "Aktenzeichen",
        legalAreaPlaceholder: "Rechtsgebiet",
        createButton: "Fall erstellen",
        progressLabel: "Fortschritt",
        stepsLabel: "Schritte",
        argsLabel: "Args",
        evidenceLabel: "Beweise",
        personsLabel: "Personen",
        deadlinesLabel: "Fristen",
        noCasesTitle: "Noch keine Fälle",
        noCasesSubtitle: "Klicke auf „Neuer Fall“ um zu beginnen",
        statusOptions: ["Aktiv", "Vorbereitung", "Abgeschlossen", "Ruhend"],
        instanzOptions: ["Erstinstanz", "Berufung", "Revision"],

        cockpitTitle: "Kanzlei-Cockpit",
        portfolioSub: { n in "Portfolio-Übersicht · \(n) Mandate" },
        newCaseLinkLabel: "+ Neuer Fall",
        totalClaimLabel: "Gesamtstreitwert",
        allMandatesSub: "alle Mandate",
        avgPrognosisLabel: "Ø Erfolgsprognose",
        weightedAvgSub: "gewichteter Durchschnitt",
        overdueDeadlinesLabel: "überfällig",
        actNow: "Sofort handeln",
        allOnTrack: "Alles im Plan",
        highRiskLabel: "Hochrisiko-Fälle (aktiv)",
        noHighRisk: "Keine Hochrisiko-Fälle aktiv ✓",
        topChancesLabel: "Top-Chancen (aktiv)",
        noTopChancesText: "Noch keine Fälle mit hoher Prognose",
        nextDeadlinesLabel: "Nächste Fristen",
        showAllLink: "Alle anzeigen →",
        noOpenDeadlinesText: "Keine offenen Fristen ✓",
        allMandatesLabel: "Alle Mandate",
        entriesLabel: { n in "\(n) Einträge" },
        tableHeaderCase: "Fall",
        tableHeaderCourt: "Gericht",
        tableHeaderClaimValue: "Streitwert",
        tableHeaderStatus: "Status",
        casesLabelShort: "Fälle",

        judgeProfilesTitle: "Richterprofile",
        profilesSub: { n in "\(n) Profile · Erfahrungen & KI-Taktikanalyse" },
        addJudgeBtn: "+ Richter",
        editProfileTitle: "Profil bearbeiten",
        newProfileTitle: "Neues Richterprofil",
        namePlaceholder: "Name *",
        courtPlaceholder: "Gericht *",
        chamberPlaceholder: "Kammer / Senat",
        plaintiffRateLabel: "Klägerquote %",
        settlementRateLabel: "Vergleichsrate %",
        avgDurationLabel: "Ø Dauer (Mo.)",
        totalRulingsLabel: "Urteile gesamt",
        knownForPlaceholder: "Bekannt für...",
        notesPlaceholder: "Notizen",
        linkToCase: "Mit Fall verknüpfen",
        selectCasePlaceholder: "Fall auswählen...",
        detailsAI: "Details & KI",
        noProfilesTitle: "Noch keine Richterprofile",
        noProfilesSub: "Klicken Sie auf \"+ Richter\" um ein Profil anzulegen",
        plaintiffRateBar: "Klägerquote",
        settlementRateBar: "Vergleichsrate",
        avgMonthsSuffix: "Mo. Ø",
        rulingsLabelShort: "Urteile",
        experiencesLabelShort: "Erfahrungen",
        kiAnalysisExists: "✓ KI-Analyse vorhanden",

        backToOverview: "Zurück zur Übersicht",
        experiencesSection: "Kanzlei-Erfahrungen",
        addExperience: "Erfahrung",
        dateLabel: "Datum",
        authorLabel: "Autor / Anwalt",
        caseContextLabel: "Fallkontext (optional)",
        settlementReadiness: "Vergleichsbereitschaft",
        decisionSpeed: "Entscheidungsgeschwindigkeit",
        expertiseLabel: "Sachkompetenz",
        experienceReport: "Erfahrungsbericht *",
        noExperiencesYet: "Noch keine Erfahrungen dokumentiert.",
        addFirstExperience: "Fügen Sie die erste Erfahrung hinzu.",
        kiTacticsTitle: "KI-Taktikanalyse",
        reanalyzeBtn: "Neu analysieren",
        startAnalysisBtn: "Analyse starten",
        analyzingBtn: "Analysiere...",
        kiAnalysisHint: "Starten Sie die KI-Analyse um taktische Empfehlungen auf Basis des Profils und der Kanzlei-Erfahrungen zu erhalten.",
        lastAnalysis: "Letzte Analyse",
        kiCreditWarning: "⚠️ Diese Analyse verwendet Gemini Pro mit Internetsuche (mehr KI-Credits)",
        summaryLabel: "📊 Zusammenfassung",
        foundRulingsLabel: "🔍 Gefundene Urteile & Entscheidungen",
        argumentationPatternsLabel: "🧠 Typische Argumentationsmuster",
        preferredNormsLabel: "§ Bevorzugte Rechtsnormen",
        argumentStanceLabel: "⚖️ Haltung zu Argumenttypen",
        preferredMotionsLabel: "📋 Bevorzugte Antragstypen",
        damageRangeLabel: "💶 Schadensersatz / Urteilsbandbreite",
        evidenceHandlingLabel: "📜 Umgang mit Beweismitteln",
        plaintiffStrengthsLabel: "✅ Stärken für Kläger",
        plaintiffRisksLabel: "⚠️ Risiken für Kläger",
        doLabel: "👍 DO",
        dontLabel: "👎 DON'T",
        tacticalTipsLabel: "💡 Verhandlungstipps",
        settlementStrategyLabel: "🤝 Vergleichsstrategie",
        timingLabel: "⏰ Timing",
        overallAssessmentLabel: "🎯 Gesamteinschätzung",
        anonLabel: "Anonym",
        settlementBar: "Vergleich",
        speedBar: "Geschwindigkeit",
        resultLabel: "Ergebnis",
        sourceLabel: "Quelle",
        parametersLabel: "Parameter",
        successRateLabel: "Erfolgsrate",
        typicalRangeLabel: "Typischer Bereich",
        factorsLabel: "Einflussfaktoren",
        specialFeaturesLabel: "Besonderheiten",
        stanceLabel: "Haltung",
        reasonLabel: "Begründung",

        timelineTitle: "Fristen-Zeitleiste",
        iCalExport: "iCal exportieren",
        filterAll: "Alle",
        filterOpen: "Offen",
        filterCritical: "⚠ Kritisch",
        filterCompleted: "Erledigt",
        noDeadlinesFound: "Keine Fristen gefunden",
        openStatusLabel: "offen",
        criticalStatusLabel: "kritisch (≤14 Tage)",
        doneStatus: "Erledigt",
        missedStatus: "Versäumt",

        newSession: "+ Neue Sitzung",
        sessionsLabel: "Sitzungen",
        noSessionsYet: "Noch keine Sitzungen",
        platformAgentTitle: "Plattform-Optimierer",
        platformAgentDesc: "Der KI-Agent analysiert Ihre Kanzleidaten, identifiziert Lücken und setzt Verbesserungen direkt um – bis MachiavelLEX für Großkanzleien unverzichtbar ist.",
        nextTaskPlaceholder: "Nächste Aufgabe für den Agenten…",
        customTaskPlaceholder: "Eigene Aufgabe eingeben…",
        agentNote: "Der Agent kann Richterprofile, Argumente und Fristen direkt erstellen & bearbeiten.",

        module: [
            UITexts.ModuleEntry(category: "KI-Assistent",            title: "Fall-Assistent Chat", description: "Konversationelle KI-Analyse Ihrer Mandate"),
            UITexts.ModuleEntry(category: "Mandatsverwaltung",       title: "Lexara Dashboard",    description: "Alle Fälle im Überblick – Fristen, Argumente, Beweise"),
            UITexts.ModuleEntry(category: "Personenprofile",         title: "Richterprofile",      description: "Erfahrungen, Statistiken & KI-Taktikanalyse"),
            UITexts.ModuleEntry(category: "KI-Agent",                title: "Plattform-Agent",     description: "Autonomer Agent für Plattformoptimierung und Analyse"),
            UITexts.ModuleEntry(category: "Cockpit",                 title: "Kanzlei-Cockpit",     description: "Risiko-Ampel, Portfolio und Fristen-Monitoring"),
            UITexts.ModuleEntry(category: "Analytics",               title: "Kanzlei-Analytik",    description: "Visualisierung aller Fallkennzahlen und Trends"),
            UITexts.ModuleEntry(category: "Strategie & Psycho-Analyse", title: "Sun Tzu × Machiavelli", description: "48 Laws of Power · Strategischer Pfad & Risikobewertung für Ihren Fall"),
            UITexts.ModuleEntry(category: "Szenario-Prognose",       title: "Strategos",           description: "Kosten-Nutzen-Szenarien, Gesetzeslücken-DB & strategische Prognosen")
        ]
    )

    // MARK: - Texte: Englisch

    public static let enText: UITexts = UITexts(
        platform: "Your AI-Powered Legal Platform",
        platformSub: "Strategic Case Analysis & Intelligent Litigation Management",
        copyright: "© 2026 MachiavelLEX · All rights reserved",
        dsgvo: "GDPR-compliant · EU Servers",

        kiFallanalyse: "AI Case Analysis",
        analyseStarten: "Start AI Analysis",
        analyseWarning: "This analysis is AI-assisted and does not constitute legal advice.",
        fallAuswaehlen: "Select case",

        aktiveFaelleLabel: "Active Cases",
        offeeneFristenLabel: "Open Deadlines",
        avgPrognoseLabel: "Avg. Prognosis",
        argumenteLabel: "Arguments",

        faelleNachRechtsgebiet: "Cases by Practice Area",
        statusVerteilung: "Status Distribution",
        prognoseVerteilung: "Prognosis Distribution",
        fristenUebersicht: "Deadline Overview",
        naechste14Tage: "Next 14 Days",
        instanzVerteilung: "Court Level Distribution",
        risikoverteilung: "Risk Distribution",
        rechtsgebiet: "Practice Area",
        gericht: "Court",
        instanz: "Court Level",
        aktiv: "Status",
        streitwert: "Amount in Controversy",
        prognose: "Win Probability",

        noDataLabel: "No data available",
        noDeadlinesRecorded: "No deadlines recorded",
        noUpcomingDeadlines: "No upcoming deadlines",
        loading: "Loading…",
        saveBtn: "Save",
        cancelBtn: "Cancel",
        updateBtn: "Update",
        createBtn: "Create",
        backLabel: "Back",
        searchPlaceholder: "Search…",
        todayLabel: "Today",
        tomorrowLabel: "Tomorrow",
        daysOverdueLabel: { n in "\(n)d overdue" },
        inDaysLabel: { n in "in \(n) days" },

        mandatesSub: { total, active in "\(total) matters · \(active) active" },
        ofTotalLabel: { n in "of \(n) total" },
        winProbabilityLabel: "Win Probability",
        totalRecordedLabel: "total recorded",
        filterResetBtn: "Reset",
        noDataShort: "No data",
        noDeadlinesShort: "No deadlines recorded",
        todayShort: "Today",
        noUpcomingShort: "No upcoming deadlines",

        conversationLabel: "Conversation",
        lexTitle: "Lex · Case Assistant",
        lexDescription: "I can analyze cases, monitor deadlines, manage arguments and provide strategic recommendations.",
        newConversationBtn: "New Conversation",
        loadingLabel: "Loading…",
        noConversationsYet: "No conversations yet",
        chatInputPlaceholder: "Ask a legal question or manage case data…",
        quickPrompts: [
            "Show me all open deadlines",
            "Analyze my strongest case",
            "Which arguments are missing?",
            "Give me a risk overview"
        ],

        caseOverview: "Case Overview",
        mandatesTotalSub: { total, active in "\(total) matters · \(active) active" },
        searchCase: "Search cases…",
        newCase: "New Case",
        createCaseTitle: "Create New Case",
        caseNamePlaceholder: "Case name *",
        fileNumberPlaceholder: "File number",
        legalAreaPlaceholder: "Practice area",
        createButton: "Create Case",
        progressLabel: "Progress",
        stepsLabel: "steps",
        argsLabel: "Args",
        evidenceLabel: "Evidence",
        personsLabel: "Persons",
        deadlinesLabel: "Deadlines",
        noCasesTitle: "No cases yet",
        noCasesSubtitle: "Click \"New Case\" to get started",
        // 1:1-Übernahme: im JS sind die Optionen auch in EN auf Deutsch.
        statusOptions: ["Aktiv", "Vorbereitung", "Abgeschlossen", "Ruhend"],
        instanzOptions: ["Erstinstanz", "Berufung", "Revision"],

        cockpitTitle: "Firm Cockpit",
        portfolioSub: { n in "Portfolio Overview · \(n) matters" },
        newCaseLinkLabel: "+ New Case",
        totalClaimLabel: "Total Claim Value",
        allMandatesSub: "all matters",
        avgPrognosisLabel: "Avg. Win Probability",
        weightedAvgSub: "weighted average",
        overdueDeadlinesLabel: "overdue",
        actNow: "Act immediately",
        allOnTrack: "All on track",
        highRiskLabel: "High-Risk Cases (active)",
        noHighRisk: "No high-risk cases active ✓",
        topChancesLabel: "Top Opportunities (active)",
        noTopChancesText: "No cases with high prognosis yet",
        nextDeadlinesLabel: "Upcoming Deadlines",
        showAllLink: "View all →",
        noOpenDeadlinesText: "No open deadlines ✓",
        allMandatesLabel: "All Matters",
        entriesLabel: { n in "\(n) entries" },
        tableHeaderCase: "Case",
        tableHeaderCourt: "Court",
        tableHeaderClaimValue: "Claim Value",
        tableHeaderStatus: "Status",
        casesLabelShort: "Cases",

        judgeProfilesTitle: "Judge Profiles",
        profilesSub: { n in "\(n) profiles · Experience & AI Tactical Analysis" },
        addJudgeBtn: "+ Judge",
        editProfileTitle: "Edit Profile",
        newProfileTitle: "New Judge Profile",
        namePlaceholder: "Name *",
        courtPlaceholder: "Court *",
        chamberPlaceholder: "Chamber / Panel",
        plaintiffRateLabel: "Plaintiff Rate %",
        settlementRateLabel: "Settlement Rate %",
        avgDurationLabel: "Avg. Duration (mo.)",
        totalRulingsLabel: "Total Rulings",
        knownForPlaceholder: "Known for...",
        notesPlaceholder: "Notes",
        linkToCase: "Link to case",
        selectCasePlaceholder: "Select case...",
        detailsAI: "Details & AI",
        noProfilesTitle: "No judge profiles yet",
        noProfilesSub: "Click \"+ Judge\" to create a profile",
        plaintiffRateBar: "Plaintiff Rate",
        settlementRateBar: "Settlement Rate",
        avgMonthsSuffix: "mo. avg.",
        rulingsLabelShort: "Rulings",
        experiencesLabelShort: "Experiences",
        kiAnalysisExists: "✓ AI Analysis available",

        backToOverview: "Back to overview",
        experiencesSection: "Firm Experiences",
        addExperience: "Experience",
        dateLabel: "Date",
        authorLabel: "Author / Attorney",
        caseContextLabel: "Case context (optional)",
        settlementReadiness: "Settlement Readiness",
        decisionSpeed: "Decision Speed",
        expertiseLabel: "Expertise",
        experienceReport: "Experience Report *",
        noExperiencesYet: "No experiences documented yet.",
        addFirstExperience: "Add the first experience.",
        kiTacticsTitle: "AI Tactical Analysis",
        reanalyzeBtn: "Re-analyze",
        startAnalysisBtn: "Start Analysis",
        analyzingBtn: "Analyzing...",
        kiAnalysisHint: "Start the AI analysis to receive tactical recommendations based on the profile and firm experiences.",
        lastAnalysis: "Last analysis",
        kiCreditWarning: "⚠️ This analysis uses Gemini Pro with internet search (more AI credits)",
        summaryLabel: "📊 Summary",
        foundRulingsLabel: "🔍 Found Rulings & Decisions",
        argumentationPatternsLabel: "🧠 Typical Argumentation Patterns",
        preferredNormsLabel: "§ Preferred Legal Norms",
        argumentStanceLabel: "⚖️ Stance on Argument Types",
        preferredMotionsLabel: "📋 Preferred Motion Types",
        damageRangeLabel: "💶 Damage Award / Ruling Range",
        evidenceHandlingLabel: "📜 Evidence Handling",
        plaintiffStrengthsLabel: "✅ Strengths for Plaintiff",
        plaintiffRisksLabel: "⚠️ Risks for Plaintiff",
        doLabel: "👍 DO",
        dontLabel: "👎 DON'T",
        tacticalTipsLabel: "💡 Tactical Tips",
        settlementStrategyLabel: "🤝 Settlement Strategy",
        timingLabel: "⏰ Timing",
        overallAssessmentLabel: "🎯 Overall Assessment",
        anonLabel: "Anonymous",
        settlementBar: "Settlement",
        speedBar: "Speed",
        resultLabel: "Outcome",
        sourceLabel: "Source",
        parametersLabel: "Parameters",
        successRateLabel: "Success Rate",
        typicalRangeLabel: "Typical Range",
        factorsLabel: "Influencing Factors",
        specialFeaturesLabel: "Special Features",
        stanceLabel: "Stance",
        reasonLabel: "Reasoning",

        timelineTitle: "Deadline Timeline",
        iCalExport: "Export iCal",
        filterAll: "All",
        filterOpen: "Open",
        filterCritical: "⚠ Critical",
        filterCompleted: "Completed",
        noDeadlinesFound: "No deadlines found",
        openStatusLabel: "open",
        criticalStatusLabel: "critical (≤14 days)",
        doneStatus: "Completed",
        missedStatus: "Missed",

        newSession: "+ New Session",
        sessionsLabel: "Sessions",
        noSessionsYet: "No sessions yet",
        platformAgentTitle: "Platform Optimizer",
        platformAgentDesc: "The AI agent analyzes your firm data, identifies gaps and implements improvements directly – making MachiavelLEX indispensable for large law firms.",
        nextTaskPlaceholder: "Next task for the agent…",
        customTaskPlaceholder: "Enter custom task…",
        agentNote: "The agent can create & edit judge profiles, arguments and deadlines directly.",

        module: [
            UITexts.ModuleEntry(category: "AI Assistant",                title: "Case Assistant Chat", description: "Conversational AI analysis of your cases"),
            UITexts.ModuleEntry(category: "Case Management",             title: "Lexara Dashboard",    description: "All cases at a glance – deadlines, arguments, evidence"),
            UITexts.ModuleEntry(category: "People Profiles",             title: "Judge Profiles",      description: "Experience, statistics & AI tactical analysis"),
            UITexts.ModuleEntry(category: "AI Agent",                    title: "Platform Agent",      description: "Autonomous agent for platform optimization"),
            UITexts.ModuleEntry(category: "Cockpit",                     title: "Firm Cockpit",        description: "Risk indicators, portfolio and deadline monitoring"),
            UITexts.ModuleEntry(category: "Analytics",                   title: "Firm Analytics",      description: "Visualization of all case metrics and trends"),
            UITexts.ModuleEntry(category: "Strategy & Psycho-Analysis",  title: "Sun Tzu × Machiavelli", description: "48 Laws of Power · Strategic path & risk assessment for your case"),
            UITexts.ModuleEntry(category: "Scenario Forecasting",        title: "Strategos",           description: "Cost-benefit scenarios, legal loophole database & strategic forecasting")
        ]
    )

    // MARK: - Texte: Französisch

    public static let frText: UITexts = UITexts(
        platform: "Votre plateforme juridique IA",
        platformSub: "Analyse stratégique des dossiers & gestion intelligente du contentieux",
        copyright: "© 2026 MachiavelLEX · Tous droits réservés",
        dsgvo: "Conforme RGPD · Serveurs UE",

        kiFallanalyse: "Analyse IA du dossier",
        analyseStarten: "Lancer l'analyse IA",
        analyseWarning: "Cette analyse est assistée par IA et ne constitue pas un avis juridique.",
        fallAuswaehlen: "Sélectionner un dossier",

        aktiveFaelleLabel: "Dossiers actifs",
        offeeneFristenLabel: "Délais ouverts",
        avgPrognoseLabel: "Pronostic moy.",
        argumenteLabel: "Arguments",

        faelleNachRechtsgebiet: "Dossiers par domaine",
        statusVerteilung: "Répartition des statuts",
        prognoseVerteilung: "Répartition du pronostic",
        fristenUebersicht: "Vue d'ensemble des délais",
        naechste14Tage: "14 prochains jours",
        instanzVerteilung: "Répartition par instance",
        risikoverteilung: "Répartition des risques",
        rechtsgebiet: "Domaine juridique",
        gericht: "Tribunal",
        instanz: "Instance",
        aktiv: "Statut",
        streitwert: "Valeur du litige",
        prognose: "Pronostic",

        noDataLabel: "Aucune donnée",
        noDeadlinesRecorded: "Aucun délai enregistré",
        noUpcomingDeadlines: "Aucun délai à venir",
        loading: "Chargement…",
        saveBtn: "Enregistrer",
        cancelBtn: "Annuler",
        updateBtn: "Mettre à jour",
        createBtn: "Créer",
        backLabel: "Retour",
        searchPlaceholder: "Rechercher…",
        todayLabel: "Aujourd'hui",
        tomorrowLabel: "Demain",
        daysOverdueLabel: { n in "\(n)j en retard" },
        inDaysLabel: { n in "dans \(n) jours" },

        mandatesSub: { total, active in "\(total) dossiers · \(active) actifs" },
        ofTotalLabel: { n in "sur \(n) au total" },
        winProbabilityLabel: "Probabilité de succès",
        totalRecordedLabel: "enregistrés au total",
        filterResetBtn: "Réinitialiser",
        noDataShort: "Aucune donnée",
        noDeadlinesShort: "Aucun délai enregistré",
        todayShort: "Aujourd'hui",
        noUpcomingShort: "Aucun délai à venir",

        conversationLabel: "Conversation",
        lexTitle: "Lex · Assistant dossier",
        lexDescription: "Je peux analyser des dossiers, surveiller les délais, gérer les arguments et fournir des recommandations stratégiques.",
        newConversationBtn: "Nouvelle conversation",
        loadingLabel: "Chargement…",
        noConversationsYet: "Aucune conversation",
        chatInputPlaceholder: "Posez une question juridique ou gérez vos données de dossier…",
        quickPrompts: [
            "Montrez-moi tous les délais ouverts",
            "Analysez mon dossier le plus solide",
            "Quels arguments manquent encore ?",
            "Donnez-moi un aperçu des risques"
        ],

        caseOverview: "Vue d'ensemble des dossiers",
        mandatesTotalSub: { total, active in "\(total) dossiers · \(active) actifs" },
        searchCase: "Rechercher un dossier…",
        newCase: "Nouveau dossier",
        createCaseTitle: "Créer un nouveau dossier",
        caseNamePlaceholder: "Nom du dossier *",
        fileNumberPlaceholder: "Référence",
        legalAreaPlaceholder: "Domaine juridique",
        createButton: "Créer le dossier",
        progressLabel: "Progression",
        stepsLabel: "étapes",
        argsLabel: "Args",
        evidenceLabel: "Preuves",
        personsLabel: "Personnes",
        deadlinesLabel: "Délais",
        noCasesTitle: "Aucun dossier",
        noCasesSubtitle: "Cliquez sur « Nouveau dossier » pour commencer",
        // 1:1-Übernahme aus dem JS-Original (deutsche Optionen).
        statusOptions: ["Aktiv", "Vorbereitung", "Abgeschlossen", "Ruhend"],
        instanzOptions: ["Erstinstanz", "Berufung", "Revision"],

        cockpitTitle: "Tableau de bord cabinet",
        portfolioSub: { n in "Vue d'ensemble · \(n) dossiers" },
        newCaseLinkLabel: "+ Nouveau dossier",
        totalClaimLabel: "Valeur totale du litige",
        allMandatesSub: "tous dossiers",
        avgPrognosisLabel: "Pronostic moy. de succès",
        weightedAvgSub: "moyenne pondérée",
        overdueDeadlinesLabel: "en retard",
        actNow: "Agir immédiatement",
        allOnTrack: "Tout est en ordre",
        highRiskLabel: "Dossiers à haut risque (actifs)",
        noHighRisk: "Aucun dossier à haut risque ✓",
        topChancesLabel: "Meilleures opportunités (actives)",
        noTopChancesText: "Aucun dossier à pronostic élevé",
        nextDeadlinesLabel: "Prochains délais",
        showAllLink: "Tout afficher →",
        noOpenDeadlinesText: "Aucun délai ouvert ✓",
        allMandatesLabel: "Tous les dossiers",
        entriesLabel: { n in "\(n) entrées" },
        tableHeaderCase: "Dossier",
        tableHeaderCourt: "Tribunal",
        tableHeaderClaimValue: "Valeur du litige",
        tableHeaderStatus: "Statut",
        casesLabelShort: "Dossiers",

        judgeProfilesTitle: "Profils de juges",
        profilesSub: { n in "\(n) profils · Expériences & analyse tactique IA" },
        addJudgeBtn: "+ Juge",
        editProfileTitle: "Modifier le profil",
        newProfileTitle: "Nouveau profil de juge",
        namePlaceholder: "Nom *",
        courtPlaceholder: "Tribunal *",
        chamberPlaceholder: "Chambre / Formation",
        plaintiffRateLabel: "Taux demandeur %",
        settlementRateLabel: "Taux de règlement %",
        avgDurationLabel: "Durée moy. (mois)",
        totalRulingsLabel: "Décisions totales",
        knownForPlaceholder: "Connu pour...",
        notesPlaceholder: "Notes",
        linkToCase: "Lier à un dossier",
        selectCasePlaceholder: "Sélectionner un dossier...",
        detailsAI: "Détails & IA",
        noProfilesTitle: "Aucun profil de juge",
        noProfilesSub: "Cliquez sur « + Juge » pour créer un profil",
        plaintiffRateBar: "Taux demandeur",
        settlementRateBar: "Taux de règlement",
        avgMonthsSuffix: "mois moy.",
        rulingsLabelShort: "Décisions",
        experiencesLabelShort: "Expériences",
        kiAnalysisExists: "✓ Analyse IA disponible",

        backToOverview: "Retour à la liste",
        experiencesSection: "Expériences du cabinet",
        addExperience: "Expérience",
        dateLabel: "Date",
        authorLabel: "Auteur / Avocat",
        caseContextLabel: "Contexte du dossier (optionnel)",
        settlementReadiness: "Disposition au règlement",
        decisionSpeed: "Rapidité de décision",
        expertiseLabel: "Expertise",
        experienceReport: "Rapport d'expérience *",
        noExperiencesYet: "Aucune expérience documentée.",
        addFirstExperience: "Ajoutez la première expérience.",
        kiTacticsTitle: "Analyse tactique IA",
        reanalyzeBtn: "Ré-analyser",
        startAnalysisBtn: "Démarrer l'analyse",
        analyzingBtn: "Analyse en cours...",
        kiAnalysisHint: "Démarrez l'analyse IA pour obtenir des recommandations tactiques basées sur le profil et les expériences du cabinet.",
        lastAnalysis: "Dernière analyse",
        kiCreditWarning: "⚠️ Cette analyse utilise Gemini Pro avec recherche internet (plus de crédits IA)",
        summaryLabel: "📊 Résumé",
        foundRulingsLabel: "🔍 Décisions & jugements trouvés",
        argumentationPatternsLabel: "🧠 Schémas d'argumentation typiques",
        preferredNormsLabel: "§ Normes juridiques préférées",
        argumentStanceLabel: "⚖️ Position sur les types d'arguments",
        preferredMotionsLabel: "📋 Types de requêtes préférés",
        damageRangeLabel: "💶 Fourchette de dommages-intérêts",
        evidenceHandlingLabel: "📜 Gestion des preuves",
        plaintiffStrengthsLabel: "✅ Points forts pour le demandeur",
        plaintiffRisksLabel: "⚠️ Risques pour le demandeur",
        doLabel: "👍 À FAIRE",
        dontLabel: "👎 À ÉVITER",
        tacticalTipsLabel: "💡 Conseils tactiques",
        settlementStrategyLabel: "🤝 Stratégie de règlement",
        timingLabel: "⏰ Timing",
        overallAssessmentLabel: "🎯 Évaluation globale",
        anonLabel: "Anonyme",
        settlementBar: "Règlement",
        speedBar: "Rapidité",
        resultLabel: "Résultat",
        sourceLabel: "Source",
        parametersLabel: "Paramètres",
        successRateLabel: "Taux de succès",
        typicalRangeLabel: "Fourchette typique",
        factorsLabel: "Facteurs",
        specialFeaturesLabel: "Particularités",
        stanceLabel: "Position",
        reasonLabel: "Justification",

        timelineTitle: "Calendrier des délais",
        iCalExport: "Exporter iCal",
        filterAll: "Tous",
        filterOpen: "Ouverts",
        filterCritical: "⚠ Critiques",
        filterCompleted: "Terminés",
        noDeadlinesFound: "Aucun délai trouvé",
        openStatusLabel: "ouvert",
        criticalStatusLabel: "critique (≤14 jours)",
        doneStatus: "Terminé",
        missedStatus: "Manqué",

        newSession: "+ Nouvelle session",
        sessionsLabel: "Sessions",
        noSessionsYet: "Aucune session",
        platformAgentTitle: "Optimiseur de plateforme",
        platformAgentDesc: "L'agent IA analyse les données de votre cabinet, identifie les lacunes et met en œuvre des améliorations directement.",
        nextTaskPlaceholder: "Prochaine tâche pour l'agent…",
        customTaskPlaceholder: "Saisir une tâche personnalisée…",
        agentNote: "L'agent peut créer et modifier des profils de juges, des arguments et des délais directement.",

        module: [
            UITexts.ModuleEntry(category: "Assistant IA",                 title: "Chat assistant dossier",   description: "Analyse IA conversationnelle de vos dossiers"),
            UITexts.ModuleEntry(category: "Gestion des dossiers",         title: "Tableau de bord Lexara",   description: "Tous les dossiers en un coup d'œil"),
            UITexts.ModuleEntry(category: "Profils de personnes",         title: "Profils de juges",         description: "Expériences, statistiques & analyse tactique IA"),
            UITexts.ModuleEntry(category: "Agent IA",                     title: "Agent de plateforme",      description: "Agent autonome d'optimisation de la plateforme"),
            UITexts.ModuleEntry(category: "Cockpit",                      title: "Cockpit cabinet",          description: "Indicateurs de risque, portefeuille et délais"),
            UITexts.ModuleEntry(category: "Analytique",                   title: "Analytique cabinet",       description: "Visualisation de tous les indicateurs de dossiers"),
            UITexts.ModuleEntry(category: "Stratégie & Psycho-Analyse",   title: "Sun Tzu × Machiavel",      description: "48 Lois du Pouvoir · Chemin stratégique & évaluation des risques"),
            UITexts.ModuleEntry(category: "Prévision de scénarios",       title: "Strategos",                description: "Scénarios coûts-bénéfices, base de failles juridiques & prévisions stratégiques")
        ]
    )

    // MARK: - Lookup-Funktionen

    /// Pendant zu `getT(jurisdiction)`. Mapping (1:1):
    ///   DE/AT/CH/LI → DE-Texte
    ///   EN/US/SE/NO/DK/FI → EN-Texte
    ///   LU → FR-Texte
    /// Fallback: DE.
    public static func texts(for jurisdiction: Jurisdiction) -> UITexts {
        switch jurisdiction {
        case .DE, .AT, .CH, .LI:
            return deText
        case .US, .SE, .NO, .DK, .FI:
            return enText
        case .LU:
            return frText
        }
    }

    /// String-API analog zur JS-Funktion (mit Fallback auf DE).
    public static func texts(jurisdictionCode: String) -> UITexts {
        // Sonderfälle, die im JS-Mapping zusätzlich erscheinen ("EN" / "FR"):
        switch jurisdictionCode {
        case "EN": return enText
        case "FR": return frText
        default:
            if let jur = Jurisdiction(rawValue: jurisdictionCode) {
                return texts(for: jur)
            }
            return deText
        }
    }

    /// Pendant zu `getTByLanguage(lang)`.
    public static func texts(byLanguage lang: Language) -> UITexts {
        switch lang {
        case .EN: return enText
        case .FR: return frText
        case .DE: return deText
        }
    }

    /// String-API analog zur JS-Funktion (mit Fallback auf DE).
    public static func texts(byLanguageCode lang: String) -> UITexts {
        switch lang {
        case "EN": return enText
        case "FR": return frText
        default:   return deText
        }
    }
}
