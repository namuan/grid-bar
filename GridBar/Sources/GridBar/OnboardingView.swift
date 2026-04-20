import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var permissions: PermissionManager

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().padding(.horizontal, 40)
            permissionSection
            Spacer()
            footer
        }
        .frame(width: 520)
        .onAppear { permissions.startPolling() }
        .onDisappear { permissions.stopPolling() }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(
                        LinearGradient(
                            colors: [Color.accentColor.opacity(0.85), Color.accentColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 88, height: 88)
                    .shadow(color: Color.accentColor.opacity(0.4), radius: 12, y: 6)

                Image(systemName: "menubar.rectangle")
                    .font(.system(size: 42, weight: .medium))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 6) {
                Text("Welcome to GridBar")
                    .font(.system(size: 26, weight: .bold))

                Text("Before you start, GridBar needs one permission\nto open menu bar items when you click them.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top, 48)
        .padding(.bottom, 36)
        .padding(.horizontal, 40)
    }

    // MARK: - Permissions

    private var permissionSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Required Permission")
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.6)
                .padding(.bottom, 10)

            permissionRow(
                icon: "accessibility",
                iconColor: .blue,
                title: "Accessibility",
                description: "Lets GridBar click menu bar items on your behalf when you tap an icon.",
                granted: permissions.accessibilityGranted,
                action: { permissions.requestAccessibility() }
            )
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 28)
    }

    @ViewBuilder
    private func permissionRow(
        icon: String,
        iconColor: Color,
        title: String,
        description: String,
        granted: Bool,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 16) {
            // Icon badge
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(iconColor)
            }

            // Text
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            // Status / Action
            Group {
                if granted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(.green)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Button("Allow", action: action)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)
                }
            }
            .animation(.spring(duration: 0.35), value: granted)
            .frame(width: 90, alignment: .trailing)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(nsColor: .controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(
                            granted ? Color.green.opacity(0.4) : Color.gray.opacity(0.18),
                            lineWidth: 1
                        )
                )
        )
        .animation(.easeInOut(duration: 0.25), value: granted)
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 12) {
            if !permissions.allGranted {
                Text("You can grant permissions later in System Settings → Privacy & Security.")
                    .font(.footnote)
                    .foregroundStyle(Color.secondary.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button {
                permissions.stopPolling()
            } label: {
                Text(permissions.allGranted ? "Get Started" : "Continue Without Permission")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(permissions.allGranted ? .accentColor : .gray)
            .padding(.horizontal, 40)
        }
        .padding(.bottom, 36)
    }
}
