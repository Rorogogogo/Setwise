import SwiftUI

struct OrganizerSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(OrganizerPreferences.classifyByTypeKey) private var classifyByType = true
    @AppStorage(OrganizerPreferences.classifyByDateKey) private var classifyByDate = true

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Organizer Options")
                    .font(.title3)
                    .bold()
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Close")
            }

            Toggle("Group by media type (Pics / Videos)", isOn: $classifyByType)
            Toggle("Group by date (YYYY-MM-DD)", isOn: $classifyByDate)

            Text("At least one option must be enabled.")
                .font(.callout)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding(20)
        .frame(width: 380, height: 200)
    }
}
