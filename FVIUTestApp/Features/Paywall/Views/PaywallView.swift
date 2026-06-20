import SwiftUI

struct PaywallView: View {
    @Environment(\.openURL) private var openURL
    @StateObject private var viewModel: PaywallViewModel
    @State private var showsCloseButton = false

    init(viewModel: PaywallViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            Color(red: 0.043, green: 0.027, blue: 0.055)
                .ignoresSafeArea()

            switch viewModel.state {
            case .idle, .loading:
                LoadingStateView(title: L10n.paywallLoading)
            case .success(let paywall):
                paywallContent(paywall)
            case .error(let error):
                ErrorStateView(error: error) {
                    Task { await viewModel.load() }
                }
            }
        }
        .statusBarHidden(false)
        .task {
            if case .idle = viewModel.state {
                await viewModel.load()
            }
            await revealCloseButton()
        }
    }

    private func paywallContent(_ paywall: Paywall) -> some View {
        GeometryReader { proxy in
            let scale = min(1, proxy.size.width / 390, proxy.size.height / 844)

            ZStack(alignment: .top) {
                PaywallBackground()
                    .frame(width: proxy.size.width, height: proxy.size.height)

                PaywallCanvas(
                    paywall: paywall,
                    viewModel: viewModel,
                    showsCloseButton: showsCloseButton,
                    openURL: openURL
                )
                .frame(width: 390, height: 844, alignment: .topLeading)
                .scaleEffect(scale, anchor: .center)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea()
    }

    private func revealCloseButton() async {
        guard !showsCloseButton else { return }
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        showsCloseButton = true
    }
}

private struct PaywallCanvas: View {
    let paywall: Paywall
    @ObservedObject var viewModel: PaywallViewModel
    let showsCloseButton: Bool
    let openURL: OpenURLAction

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.clear
                .frame(width: 390, height: 844)

            closeButton
                .position(x: 28, y: 90)

            Text(paywall.title)
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(AppColors.primaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(0)
                .frame(width: 267, height: 82)
                .position(x: 195, y: 253)

            benefitRows

            productRows

            if case .error(let error) = viewModel.purchaseState {
                PaywallErrorBanner(error: error)
                    .frame(width: 358)
                    .position(x: 195, y: 681)
            }

            cancelAnytime
                .position(x: 195, y: 699)

            unlockButton
                .position(x: 195, y: 746)

            footerLinks
                .frame(width: 358)
                .position(x: 195, y: 796)
        }
    }

    private var closeButton: some View {
        Button {
            viewModel.close()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(AppColors.primaryText.opacity(0.35))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(showsCloseButton ? 1 : 0)
        .animation(.easeInOut(duration: 0.22), value: showsCloseButton)
    }

    private var benefitRows: some View {
        Group {
            PaywallFeatureRow(assetName: "PaywallGenerate", title: L10n.paywallFeatureFast)
                .frame(width: 312, alignment: .leading)
                .position(x: 210, y: 339.5)

            PaywallFeatureRow(assetName: "PaywallMagicPencil", title: L10n.paywallFeatureWriting)
                .frame(width: 312, alignment: .leading)
                .position(x: 210, y: 379)

            PaywallFeatureRow(assetName: "PaywallPrompt", title: L10n.paywallFeatureSimplify)
                .frame(width: 312, alignment: .leading)
                .position(x: 210, y: 419.05)

            PaywallFeatureRow(assetName: "PaywallImageToImage", title: L10n.paywallFeatureTemplates)
                .frame(width: 312, alignment: .leading)
                .position(x: 210, y: 459)
        }
    }

    private var productRows: some View {
        VStack(spacing: 12) {
            ForEach(paywall.products.prefix(2)) { product in
                PaywallProductRow(
                    product: product,
                    isSelected: product == viewModel.selectedProduct
                ) {
                    viewModel.select(product)
                }
                .frame(width: 358, height: 72)
            }
        }
        .position(x: 195, y: 585)
    }

    private var cancelAnytime: some View {
        Button {
            openURL(AppConfig.subscriptionManagementURL)
        } label: {
            HStack(spacing: 7) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 19, weight: .regular))

                Text(L10n.cancelAnytime)
                    .font(.system(size: 12, weight: .regular))
            }
            .foregroundStyle(AppColors.primaryText.opacity(0.4))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.settingsManageSubscription)
    }

    private var unlockButton: some View {
        Button {
            Task { await viewModel.purchaseSelectedProduct() }
        } label: {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.596, green: 0.776, blue: 0.969),
                        Color(red: 0.922, green: 0.357, blue: 0.573)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )

                if viewModel.purchaseState.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(L10n.continueButton)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppColors.primaryText)
                }
            }
            .frame(width: 358, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(viewModel.purchaseState.isLoading)
    }

    private var footerLinks: some View {
        HStack {
            Button(L10n.privacyPolicy) {
                openURL(AppConfig.privacyPolicyURL)
            }

            Spacer()

            Button(L10n.restorePurchases) {
                Task { await viewModel.restorePurchases() }
            }

            Spacer()

            Button(L10n.termsOfUse) {
                openURL(AppConfig.termsOfUseURL)
            }
        }
        .font(.system(size: 11, weight: .regular))
        .foregroundStyle(AppColors.primaryText.opacity(0.4))
    }
}

private struct PaywallErrorBanner: View {
    let error: AppError

    var body: some View {
        HStack(spacing: AppSpacing.small) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(AppColors.error)

            VStack(alignment: .leading, spacing: 2) {
                Text(error.title)
                    .font(AppTypography.caption.weight(.semibold))
                    .foregroundStyle(AppColors.primaryText)

                Text(error.message)
                    .font(AppTypography.badge)
                    .foregroundStyle(AppColors.secondaryText)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(AppSpacing.small)
        .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: AppRadius.small))
    }
}
