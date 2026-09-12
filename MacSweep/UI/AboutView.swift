import AppKit
import SwiftUI

/// The custom About window, opened from the app menu.
struct AboutView: View {
    static let windowID = "about"

    var body: some View {
        VStack(spacing: 14) {
            Image(.sweep)
                .resizable()
                .scaledToFit()
                .frame(width: 92, height: 92)

            VStack(spacing: 3) {
                Text(AppInfo.name)
                    .font(.largeTitle.bold())
                Text(AppInfo.versionDescription)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Text(AppInfo.tagline)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Divider()
                .padding(.vertical, 2)

            VStack(alignment: .leading, spacing: 8) {
                infoRow(icon: "building.2", title: "Made by", value: AppInfo.developer)
                linkRow(icon: "globe", title: "Website", value: "grayhawks.com", url: AppInfo.websiteURL)
                linkRow(icon: "envelope", title: "Support", value: AppInfo.emailAddress, url: AppInfo.emailURL)
                linkRow(icon: "chevron.left.forwardslash.chevron.right", title: "GitHub", value: "arintsohaib/MacSweep", url: AppInfo.githubURL)
                linkRow(icon: "doc.text.magnifyingglass", title: "Help", value: "README & guides", url: AppInfo.helpURL)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text("MacSweep recommends; you decide. Nothing is permanently deleted — selected items move to the Trash.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)

            HStack(spacing: 10) {
                Button("Website") { NSWorkspace.shared.open(AppInfo.websiteURL) }
                Button("Email") { NSWorkspace.shared.open(AppInfo.emailURL) }
                Button("GitHub") { NSWorkspace.shared.open(AppInfo.githubURL) }
            }
            .controlSize(.regular)
        }
        .padding(28)
        .frame(width: 420)
    }

    private func infoRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 18)
            Text(title)
                .foregroundStyle(.secondary)
                .frame(width: 64, alignment: .leading)
            Text(value)
                .textSelection(.enabled)
            Spacer(minLength: 0)
        }
        .font(.callout)
    }

    private func linkRow(icon: String, title: String, value: String, url: URL) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 18)
            Text(title)
                .foregroundStyle(.secondary)
                .frame(width: 64, alignment: .leading)
            Button(value) {
                NSWorkspace.shared.open(url)
            }
            .buttonStyle(.link)
            Spacer(minLength: 0)
        }
        .font(.callout)
    }
}
