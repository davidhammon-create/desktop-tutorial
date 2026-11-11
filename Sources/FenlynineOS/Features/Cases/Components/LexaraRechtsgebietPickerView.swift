import SwiftUI
struct LexaraRechtsgebietPickerView: View {
    @Binding var auswahl: LexaraRechtsgebietAuswahl
    var bearbeitung: Bool
    @State private var expandedKategorien: Set<String> = []
    @State private var expandedGebiet: String?
    @State private var suche = ""
    private var gefilterteKategorien: [LexaraRechtsgebietKategorie] {
        guard !suche.trimmingCharacters(in: .whitespaces).isEmpty else {
            return LexaraRechtsgebietKatalog.kategorien
        }
        let q = suche.lowercased()
        return LexaraRechtsgebietKatalog.kategorien.compactMap { kat in
            let gebiete = kat.gebiete.filter {
                $0.label.lowercased().contains(q)
                    || $0.untergebiete.contains { $0.lowercased().contains(q) }
            }
            guard !gebiete.isEmpty else { return nil }
            return LexaraRechtsgebietKategorie(id: kat.id, titel: kat.titel, icon: kat.icon, accent: kat.accent, gebiete: gebiete)
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if bearbeitung {
                bearbeitungsModus
            } else {
                leseModus
            }
        }
    }
    @ViewBuilder
    private var leseModus: some View {
        if auswahl.istLeer {
            Text("Keine Rechtsgebiete gewählt")
                .font(FenlynineOSFont.caption)
                .foregroundStyle(.secondary)
        } else {
            VStack(alignment: .leading, spacing: 10) {
                if let primaer = auswahl.primaeresLabel {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.yellow)
                        Text("Primär: \(primaer)")
                            .font(FenlynineOSFont.caption.weight(.semibold))
                    }
                }
                ForEach(LexaraRechtsgebietKatalog.kategorien) { kat in
                    let ids = kat.gebiete.map(\.id).filter { auswahl.gewaehlteIds.contains($0) }
                    if !ids.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Label(kat.titel, systemImage: kat.icon)
                                .font(FenlynineOSFont.caption.weight(.semibold))
                                .foregroundStyle(kat.accent)
                            FlowLayout(spacing: 6) {
                                ForEach(ids, id: \.self) { id in
                                    rgChip(id: id, aktiv: true, accent: kat.accent, kompakt: true)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            ForEach(ids, id: \.self) { id in
                                if let f = auswahl.felder[id], f.hatInhalt {
                                    gebietDetailZeilen(id: id, felder: f)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    @ViewBuilder
    private func gebietDetailZeilen(id: String, felder: LexaraRechtsgebietFeldWerte) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            if !felder.untergebiet.isEmpty {
                detailZeile("Untergebiet", felder.untergebiet)
            }
            if !felder.schwerpunkt.isEmpty {
                detailZeile("Schwerpunkt", felder.schwerpunkt)
            }
            if !felder.relevanteNormen.isEmpty {
                detailZeile("Normen", felder.relevanteNormen)
            }
            if !felder.bemerkung.isEmpty {
                detailZeile("Bemerkung", felder.bemerkung)
            }
        }
        .padding(.leading, 8)
        .padding(.vertical, 4)
    }
    private func detailZeile(_ titel: String, _ wert: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("\(titel):")
                .font(FenlynineOSFont.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 72, alignment: .leading)
            Text(wert)
                .font(FenlynineOSFont.caption2)
        }
    }
    @ViewBuilder
    private var bearbeitungsModus: some View {
        auswahlLeiste
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Rechtsgebiet suchen …", text: $suche)
                .textFieldStyle(.plain)
                .font(FenlynineOSFont.body)
            if !suche.isEmpty {
                Button { suche = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
        VStack(spacing: 6) {
            ForEach(gefilterteKategorien) { kat in
                kategorieZeile(kat)
            }
        }
        if !auswahl.istLeer {
            primaerAuswahlBlock
        }
    }
    @ViewBuilder
    private var auswahlLeiste: some View {
        if auswahl.istLeer {
            Text("Kategorie aufklappen und Rechtsgebiete auswählen")
                .font(FenlynineOSFont.caption)
                .foregroundStyle(.secondary)
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Text("\(auswahl.gewaehlteIds.count) ausgewählt")
                    .font(FenlynineOSFont.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                FlowLayout(spacing: 6) {
                    ForEach(Array(auswahl.gewaehlteIds).sorted(), id: \.self) { id in
                        let kat = LexaraRechtsgebietKatalog.kategorie(fuer: id)
                        rgChip(id: id, aktiv: true, accent: kat?.accent ?? .blue, kompakt: true)
                            .onTapGesture { toggleGebiet(id) }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    @ViewBuilder
    private func kategorieZeile(_ kat: LexaraRechtsgebietKategorie) -> some View {
        let istOffen = expandedKategorien.contains(kat.id)
        let anzahl = kat.gebiete.filter { auswahl.gewaehlteIds.contains($0.id) }.count
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.22)) {
                    if istOffen { expandedKategorien.remove(kat.id) }
                    else { expandedKategorien.insert(kat.id) }
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: kat.icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(kat.accent)
                        .frame(width: 28, height: 28)
                        .background(kat.accent.opacity(0.12), in: Circle())
                    Text(kat.titel)
                        .font(FenlynineOSFont.body.weight(.medium))
                        .foregroundStyle(.primary)
                    if anzahl > 0 {
                        Text("\(anzahl)")
                            .font(FenlynineOSFont.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(kat.accent, in: Capsule())
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(istOffen ? 90 : 0))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            if istOffen {
                VStack(alignment: .leading, spacing: 8) {
                    FlowLayout(spacing: 8) {
                        ForEach(kat.gebiete) { gebiet in
                            rgChip(
                                id: gebiet.id,
                                aktiv: auswahl.gewaehlteIds.contains(gebiet.id),
                                accent: kat.accent,
                                kompakt: false
                            )
                            .onTapGesture { toggleGebiet(gebiet.id) }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    ForEach(kat.gebiete.filter { auswahl.gewaehlteIds.contains($0.id) }) { gebiet in
                        gebietDetailEditor(gebiet: gebiet, accent: kat.accent)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.primary.opacity(0.02), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
    @ViewBuilder
    private func rgChip(id: String, aktiv: Bool, accent: Color, kompakt: Bool) -> some View {
        let label = LexaraRechtsgebietKatalog.label(fuer: id)
        let icon = LexaraRechtsgebietKatalog.eintrag(fuer: id)?.icon ?? "doc"
        HStack(spacing: 4) {
            if !kompakt {
                Image(systemName: icon)
                    .font(.system(size: 10))
            }
            Text(label)
                .font(kompakt ? FenlynineOSFont.caption2 : FenlynineOSFont.caption)
                .lineLimit(1)
            if aktiv && auswahl.primaerId == id {
                Image(systemName: "star.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(.yellow)
            }
        }
        .padding(.horizontal, kompakt ? 8 : 10)
        .padding(.vertical, kompakt ? 4 : 6)
        .background(
            aktiv ? accent.opacity(0.18) : Color.primary.opacity(0.05),
            in: Capsule()
        )
        .overlay(
            Capsule().strokeBorder(aktiv ? accent.opacity(0.45) : Color.clear, lineWidth: 1)
        )
        .foregroundStyle(aktiv ? accent : .secondary)
    }
    @ViewBuilder
    private func gebietDetailEditor(gebiet: LexaraRechtsgebietEintrag, accent: Color) -> some View {
        let istOffen = expandedGebiet == gebiet.id
        let felder = Binding(
            get: { auswahl.felder[gebiet.id] ?? LexaraRechtsgebietFeldWerte() },
            set: {
                var a = auswahl
                a.felder[gebiet.id] = $0
                auswahl = a
            }
        )
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedGebiet = istOffen ? nil : gebiet.id
                }
            } label: {
                HStack {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 11))
                        .foregroundStyle(accent)
                    Text("Details: \(gebiet.label)")
                        .font(FenlynineOSFont.caption.weight(.medium))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .rotationEffect(.degrees(istOffen ? 90 : 0))
                        .foregroundStyle(.secondary)
                }
                .padding(8)
            }
            .buttonStyle(.plain)
            if istOffen {
                VStack(alignment: .leading, spacing: 8) {
                    if !gebiet.untergebiete.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Untergebiet")
                                .font(FenlynineOSFont.caption2)
                                .foregroundStyle(.secondary)
                            Picker("", selection: Binding(
                                get: { felder.wrappedValue.untergebiet },
                                set: {
                                    var f = felder.wrappedValue
                                    f.untergebiet = $0
                                    felder.wrappedValue = f
                                }
                            )) {
                                Text("—").tag("")
                                ForEach(gebiet.untergebiete, id: \.self) { u in
                                    Text(u).tag(u)
                                }
                            }
                            .labelsHidden()
                        }
                    }
                    rgFeld("Schwerpunkt", text: Binding(
                        get: { felder.wrappedValue.schwerpunkt },
                        set: {
                            var f = felder.wrappedValue
                            f.schwerpunkt = $0
                            felder.wrappedValue = f
                        }
                    ), placeholder: "z. B. Kündigungsschutzklage")
                    rgFeld("Relevante Normen", text: Binding(
                        get: { felder.wrappedValue.relevanteNormen },
                        set: {
                            var f = felder.wrappedValue
                            f.relevanteNormen = $0
                            felder.wrappedValue = f
                        }
                    ), placeholder: gebiet.normenHinweis ?? "§§ …")
                    rgFeld("Bemerkung", text: Binding(
                        get: { felder.wrappedValue.bemerkung },
                        set: {
                            var f = felder.wrappedValue
                            f.bemerkung = $0
                            felder.wrappedValue = f
                        }
                    ), placeholder: "Interne Notiz zum Schwerpunkt")
                    HStack {
                        Button("Als primär markieren") {
                            var a = auswahl
                            a.primaerId = gebiet.id
                            auswahl = a
                        }
                        .font(FenlynineOSFont.caption)
                        .disabled(auswahl.primaerId == gebiet.id)
                        Spacer()
                        Button("Entfernen", role: .destructive) {
                            toggleGebiet(gebiet.id)
                        }
                        .font(FenlynineOSFont.caption)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
                .transition(.opacity)
            }
        }
        .background(accent.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
    }
    private func rgFeld(_ titel: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(titel)
                .font(FenlynineOSFont.caption2)
                .foregroundStyle(.secondary)
            TextField(placeholder, text: text)
                .textFieldStyle(.roundedBorder)
                .font(FenlynineOSFont.caption)
        }
    }
    @ViewBuilder
    private var primaerAuswahlBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Primäres Rechtsgebiet")
                .font(FenlynineOSFont.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Picker("", selection: Binding(
                get: { auswahl.primaerId ?? auswahl.gewaehlteIds.first ?? "" },
                set: {
                    var a = auswahl
                    a.primaerId = $0.isEmpty ? nil : $0
                    auswahl = a
                }
            )) {
                ForEach(Array(auswahl.gewaehlteIds).sorted(), id: \.self) { id in
                    Text(LexaraRechtsgebietKatalog.label(fuer: id)).tag(id)
                }
            }
            .labelsHidden()
        }
        .padding(.top, 4)
    }
    private func toggleGebiet(_ id: String) {
        withAnimation(.easeInOut(duration: 0.18)) {
            var a = auswahl
            if a.gewaehlteIds.contains(id) {
                a.gewaehlteIds.remove(id)
                a.felder.removeValue(forKey: id)
                if a.primaerId == id {
                    a.primaerId = a.gewaehlteIds.first
                }
                if expandedGebiet == id { expandedGebiet = nil }
            } else {
                a.gewaehlteIds.insert(id)
                if a.primaerId == nil { a.primaerId = id }
                if let kat = LexaraRechtsgebietKatalog.kategorie(fuer: id) {
                    expandedKategorien.insert(kat.id)
                }
            }
            auswahl = a
        }
    }
}
extension LexaraRechtsgebietFeldWerte {
    var hatInhalt: Bool {
        !untergebiet.isEmpty || !relevanteNormen.isEmpty || !schwerpunkt.isEmpty || !bemerkung.isEmpty
    }
}
