
import SwiftUI

struct SettingsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "pawprint.fill")
                .font(.system(size: 40))

            Text("Buddy")
                .font(.title.bold())

            Text("Reminder settings will be added soon.")
                .foregroundStyle(.secondary)
        }
        .frame(width: 400, height: 250)
        .padding()
    }
}

#Preview {
    SettingsView()
}
