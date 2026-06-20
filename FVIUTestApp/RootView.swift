import SwiftUI

struct RootView: View {
    @EnvironmentObject private var container: AppContainer
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack(path: $appState.navigationPath) {
            HomeView()
            .navigationDestination(for: AppRoute.self) { route in
                destination(for: route)
            }
            .fullScreenCover(isPresented: $appState.isPaywallPresented) {
                PaywallView(viewModel: container.makePaywallViewModel())
            }
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .chat:
            ChatView(viewModel: container.makeChatViewModel())
        case .chatSession(let sessionID):
            ChatView(viewModel: container.makeChatViewModel(sessionID: sessionID))
        case .chatHistory:
            ChatHistoryView(viewModel: container.makeChatHistoryViewModel())
        case .videoGenerator:
            VideoCatalogView(viewModel: container.makeVideoCatalogViewModel())
        case .videoHistory:
            VideoHistoryView(viewModel: container.makeVideoHistoryViewModel())
        case .videoTemplateDetail(let id):
            VideoGeneratorView(viewModel: container.makeVideoGeneratorViewModel(templateID: id))
        case .paywall:
            PaywallView(viewModel: container.makePaywallViewModel())
        case .settings:
            SettingsView(viewModel: container.makeSettingsViewModel())
        }
    }
}

private struct HomeView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ZStack {
            PaywallBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: AppSpacing.large) {
                    topBar
                    hero
                    askBar
                    functions

                    Spacer(minLength: AppSpacing.large)
                }
                .padding(.horizontal, 16)
                .padding(.top, AppSpacing.medium)
            }
        }
    }

    private var topBar: some View {
        HStack {
            Spacer()

            Button {
                appState.navigate(to: .settings)
            } label: {
                Image("SettingsIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .frame(width: 40, height: 40)
                    .background(AppColors.glassDarkLight, in: RoundedRectangle(cornerRadius: AppRadius.control))
            }
            .buttonStyle(.plain)
        }
    }

    private var hero: some View {
        VStack(spacing: AppSpacing.medium) {
            Image("HomeHeroIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)

            Text(L10n.homeHeroTitle)
                .font(.system(size: 28, weight: .bold))
                .tracking(0.4)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppColors.primaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AppSpacing.large)
    }

    private var askBar: some View {
        Button {
            appState.navigateToPremiumRoute(.chat)
        } label: {
            HStack(spacing: AppSpacing.medium) {
                Image("AskBarIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .frame(width: 24, height: 24)

                Text(L10n.homeAskPlaceholder)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(AppColors.primaryText)

                Spacer()
            }
            .padding(.horizontal, AppSpacing.medium)
            .frame(height: 56)
            .background(AppColors.glassDarkLight, in: RoundedRectangle(cornerRadius: AppRadius.control))
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.control)
                    .stroke(
                        LinearGradient(
                            colors: [AppColors.gradientBlue, AppColors.gradientPink],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 2
                    )
            }
        }
        .buttonStyle(.plain)
    }

    /// Figma reference widths for the functions row (390pt canvas): 172 + 8 gap + 178 = 358.
    /// The actual on-screen width varies per device, so the two columns are sized as a
    /// proportion of whatever width is available rather than hard-coded points — this keeps
    /// the row visually aligned with the (flexible-width) ask bar above it on every device.
    private static let primaryCardRatio: CGFloat = 172.0 / 350.0
    private static let secondaryColumnRatio: CGFloat = 178.0 / 350.0
    private static let functionsGap: CGFloat = 8
    private static let functionsHeight: CGFloat = 313
    private static let smallCardHeight: CGFloat = 152.5

    private var functions: some View {
        GeometryReader { proxy in
            let columnsWidth = proxy.size.width - Self.functionsGap
            let primaryWidth = columnsWidth * Self.primaryCardRatio
            let secondaryWidth = columnsWidth * Self.secondaryColumnRatio

            HStack(alignment: .top, spacing: Self.functionsGap) {
                HomePrimaryToolCard {
                    appState.navigateToPremiumRoute(.videoGenerator)
                }
                .frame(width: primaryWidth, height: Self.functionsHeight)

                VStack(spacing: Self.functionsGap) {
                    HomeSmallToolCard(
                        assetName: "PaywallMagicPencil",
                        title: L10n.homeWritingCardTitle,
                        subtitle: L10n.homeWritingCardSubtitle
                    ) {
                        appState.navigateToPremiumRoute(.chat)
                    }
                    .frame(height: Self.smallCardHeight)

                    HomeSmallToolCard(
                        assetName: "PaywallPrompt",
                        title: L10n.homeUnderstandCardTitle,
                        subtitle: L10n.homeUnderstandCardSubtitle
                    ) {
                        appState.navigateToPremiumRoute(.chat)
                    }
                    .frame(height: Self.smallCardHeight)
                }
                .frame(width: secondaryWidth, height: Self.functionsHeight)
            }
        }
        .frame(height: Self.functionsHeight)
    }
}

private struct HomePrimaryToolCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Image("SparkleAccent")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .frame(width: 36, height: 36)
                    .background(AppColors.glassWhite, in: RoundedRectangle(cornerRadius: AppRadius.control))

                Text(L10n.homeVideoCardTitle)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(L10n.homeVideoCardSubtitle)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.white.opacity(0.7))

                Spacer()

                HStack(spacing: 6) {
                    Text(L10n.homeVideoCardCTA)
                        .font(.system(size: 12, weight: .regular))
                        .tracking(0.06)
                    Image(systemName: "play.fill")
                        .font(.system(size: 16, weight: .regular))
                }
                .foregroundStyle(.white)
                .frame(width: 149, height: 32)
                .background(.white.opacity(0.3), in: RoundedRectangle(cornerRadius: AppRadius.control))
            }
            .padding(.top, AppSpacing.large)
            .padding(.horizontal, AppSpacing.medium)
            .padding(.bottom, AppSpacing.medium)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background {
                ZStack {
                    LinearGradient(
                        colors: [AppColors.gradientBlue, AppColors.gradientPink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    Image("HomeVideoCardBackground")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                        .offset(y: 28)
                        .opacity(0.55)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.control))
        }
        .buttonStyle(.plain)
    }
}

private struct HomeSmallToolCard: View {
    let assetName: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Image(assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .frame(width: 36, height: 36)
                    .background(AppColors.glassWhiteLight, in: RoundedRectangle(cornerRadius: AppRadius.control))

                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppColors.primaryText)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .tracking(0.06)
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Spacer(minLength: 0)
            }
            .padding(AppSpacing.medium)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(AppColors.glassDark, in: RoundedRectangle(cornerRadius: AppRadius.control))
        }
        .buttonStyle(.plain)
    }
}
