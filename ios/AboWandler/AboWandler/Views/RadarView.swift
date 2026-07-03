import SwiftUI

struct RadarView: View {
    var body: some View {
        NavigationStack {
            List(RadarTopic.all) { topic in
                NavigationLink {
                    RadarTopicView(topic: topic)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: topic.icon)
                            .font(.title3)
                            .foregroundStyle(.blue)
                            .frame(width: 32)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(topic.title).font(.subheadline.weight(.semibold))
                            Text(topic.intro).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                        }
                    }
                }
            }
            .navigationTitle("Finanz-Radar")
        }
    }
}

struct RadarTopicView: View {
    let topic: RadarTopic

    var body: some View {
        List {
            Section(footer: Text("Allgemeine Informationen und Modellbeispiele — keine Rechts-, Steuer- oder Anlageberatung. Steuerliche Gestaltungen immer mit Steuerberater:in umsetzen.")) {
                ForEach(topic.tips) { tip in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(tip.title).font(.subheadline.weight(.semibold))
                            Spacer()
                            if let saving = tip.saving {
                                Text("💰 \(saving)")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.green)
                            }
                        }
                        Text(tip.text).font(.callout).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle(topic.title)
    }
}
