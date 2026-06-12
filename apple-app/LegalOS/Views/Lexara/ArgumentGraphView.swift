//
//  ArgumentGraphView.swift
//  Konversion von src/components/lexara/ArgumentGraphiOS.jsx (Name geändert).
//  iOS/macOS-optimierte Argument-Graph-Visualisierung mit Touch/Click-Interaktion.
//

import SwiftUI

struct ArgumentGraphView: View {
    let args: [Argument]
    let evidence: [Evidence]
    var onSelect: ((Argument) -> Void)? = nil

    @State private var selected: Argument?
    @State private var zoomLevel: Double = 1.0

    var body: some View {
        VStack {
            HStack {
                Text("Argument-Graph").font(.headline)
                Spacer()
                Slider(value: $zoomLevel, in: 0.5...2.0).frame(width: 120)
                Text("Zoom \(String(format: "%.1f", zoomLevel))x").font(.caption2).foregroundColor(.secondary)
            }.padding(.horizontal)
            ScrollView([.horizontal, .vertical]) {
                ZStack {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 12) {
                        ForEach(args) { arg in
                            argNode(arg)
                                .onTapGesture {
                                    selected = arg
                                    onSelect?(arg)
                                }
                        }
                    }
                    .scaleEffect(zoomLevel)
                    .padding(20)
                }
            }
            .frame(maxHeight: 400)
            if let s = selected { detailPanel(s) }
        }
    }

    private func argNode(_ arg: Argument) -> some View {
        let isSelected = selected?.id == arg.id
        let strength = arg.kiStrength ?? arg.strength ?? 5
        let strColor: Color = strength >= 7 ? .green : strength >= 4 ? .orange : .red
        let argEvidence = evidence.filter { $0.argumentId == arg.id }
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(arg.side == .eigen ? "EIGEN" : "GEGNER").font(.system(size: 9, weight: .bold))
                    .padding(.horizontal, 4).padding(.vertical, 2)
                    .background((arg.side == .eigen ? Color.blue : Color.red).opacity(0.15))
                    .foregroundColor(arg.side == .eigen ? .blue : .red)
                    .clipShape(Capsule())
                Spacer()
                Text("\(Int(strength))/10").font(.caption2.weight(.bold)).foregroundColor(strColor)
            }
            Text(arg.title).font(.caption.weight(.semibold)).lineLimit(3)
            HStack(spacing: 4) {
                Image(systemName: "doc.text").font(.system(size: 9))
                Text("\(argEvidence.count)").font(.system(size: 9))
            }.foregroundColor(.secondary)
        }
        .frame(width: 160, height: 100, alignment: .topLeading)
        .padding(8)
        .background(arg.side == .eigen ? Color.blue.opacity(0.05) : Color.red.opacity(0.05))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(isSelected ? Color.primary : Color.secondary.opacity(0.2), lineWidth: 2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func detailPanel(_ arg: Argument) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 6) {
                Text(arg.title).font(.subheadline.weight(.semibold))
                if let d = arg.argDescription { Text(d).font(.caption).foregroundColor(.secondary) }
                if let r = arg.kiReasoning { Label(r, systemImage: "brain").font(.caption2).foregroundColor(.purple) }
            }.padding(8)
        }
    }
}
