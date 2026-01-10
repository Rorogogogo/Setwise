import SwiftUI
import AppKit

struct StatusBanner: Identifiable {
    enum Kind {
        case success
        case error
    }

    let id = UUID()
    let kind: Kind
    let message: String
}

struct StatusBannerView: View {
    let banner: StatusBanner

    private var tintColor: Color {
        switch banner.kind {
        case .success: return Color(nsColor: .systemGreen)
        case .error: return Color(nsColor: .systemRed)
        }
    }

    private var iconName: String {
        switch banner.kind {
        case .success: return "checkmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }

    var body: some View {
        Label {
            Text(banner.message)
        } icon: {
            Image(systemName: iconName)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(tintColor.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(tintColor.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 1)
    }
}
