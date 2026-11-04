import SwiftUI

@main
struct SealLifeApp: App {
    @State private var store = GameStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .tint(Theme.oceanDeep)
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { store.onForeground() }
                }
        }
    }
}

struct RootView: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        ZStack {
            Theme.cream.ignoresSafeArea()
            if store.profile.onboarded {
                MainView()
                    .transition(.asymmetric(insertion: .scale(scale: 1.05).combined(with: .opacity), removal: .opacity))
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.7, dampingFraction: 0.85), value: store.profile.onboarded)
        .preferredColorScheme(.light)
    }
}

// MARK: - Fanebjælke

enum AppTab: String, CaseIterable, Identifiable {
    case home, stats, shop, me
    var id: String { rawValue }
    var title: String {
        switch self {
        case .home: return "Hjem"
        case .stats: return "Statistik"
        case .shop: return "Butik"
        case .me: return "Mig"
        }
    }
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .stats: return "chart.bar.fill"
        case .shop: return "bag.fill"
        case .me: return "face.smiling.inverse"
        }
    }
}

struct MainView: View {
    @Environment(GameStore.self) private var store
    @State private var tab: AppTab = .home
    @Namespace private var ns

    var body: some View {
        @Bindable var store = store
        ZStack {
            switch tab {
            case .home: HomeView().transition(.opacity.combined(with: .move(edge: .leading)))
            case .stats: StatsView().transition(.opacity.combined(with: .scale(scale: 0.97)))
            case .shop: ShopView().transition(.opacity.combined(with: .scale(scale: 0.97)))
            case .me: SettingsView().transition(.opacity.combined(with: .move(edge: .trailing)))
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { tabBar }
        .sheet(isPresented: $store.showStory) {
            StoryView().presentationDetents([.large]).presentationCornerRadius(32)
        }
        .sheet(isPresented: $store.showWelcomeHome) {
            WelcomeHomeView().presentationDetents([.medium]).presentationCornerRadius(32)
        }
    }

    private var tabBar: some View {
        HStack(spacing: 4) {
            ForEach(AppTab.allCases) { t in
                Button {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) { tab = t }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: t.icon)
                            .font(.system(size: 20, weight: .bold))
                            .symbolEffect(.bounce, value: tab == t)
                        Text(t.title).font(.rounded(11, .bold))
                    }
                    .foregroundStyle(tab == t ? Theme.oceanDark : Theme.inkSoft)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background {
                        if tab == t {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Theme.oceanLight)
                                .matchedGeometryEffect(id: "tabPill", in: ns)
                        }
                    }
                }
                .buttonStyle(BouncyStyle())
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(.white)
                .shadow(color: Theme.oceanDark.opacity(0.12), radius: 14, x: 0, y: 4)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
    }
}
