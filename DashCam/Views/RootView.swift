import SwiftUI

struct RootView: View {
    @EnvironmentObject private var app: AppState

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Theme.bg.ignoresSafeArea()
                switch app.tab {
                case .home:
                    NavigationStack { HomeView() }
                case .gallery:
                    NavigationStack { GalleryView() }
                case .live:
                    NavigationStack { LiveView() }
                case .saved:
                    NavigationStack { SavedView() }
                case .settings:
                    NavigationStack { SettingsView() }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            TabBar()
        }
        .background(Theme.bg.ignoresSafeArea())
        .overlay(alignment: .top) {
            if let message = app.toast {
                ToastView(message: message)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}

struct TabBar: View {
    @EnvironmentObject private var app: AppState

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            item(.home, "Home", "house")
            item(.gallery, "Gallery", "square.grid.2x2")
            live
            item(.saved, "Saved", "arrow.down.to.line")
            item(.settings, "Settings", "slider.horizontal.3")
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 2)
        .background(Theme.tabBar.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) {
            Rectangle().fill(Color(hex: 0x22272F)).frame(height: 1)
        }
    }

    private func item(_ tab: AppState.Tab, _ title: String, _ icon: String) -> some View {
        let on = app.tab == tab
        return Button {
            Haptics.tap()
            app.tab = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 20, weight: .semibold))
                Text(title).font(.system(size: 11, weight: .bold))
            }
            .foregroundStyle(on ? Theme.teal : Theme.text3)
            .frame(maxWidth: .infinity, minHeight: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
        .overlay(alignment: .topTrailing) {
            if tab == .saved && app.isDownloading {
                Circle().fill(Theme.teal).frame(width: 8, height: 8).offset(x: -22, y: 2)
            }
        }
    }

    private var live: some View {
        let on = app.tab == .live
        return Button {
            Haptics.tap()
            app.tab = .live
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    Circle().fill(Theme.teal)
                    Image(systemName: "video.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Theme.onTeal)
                }
                .frame(width: 56, height: 56)
                .overlay(Circle().stroke(Theme.tabBar, lineWidth: 4))
                .overlay(Circle().stroke(on ? Theme.teal : Color.clear, lineWidth: 2).padding(-4))
                .offset(y: -18)
                .padding(.bottom, -18)
                Text("Live")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(on ? Theme.teal : Theme.text3)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Live view")
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}
