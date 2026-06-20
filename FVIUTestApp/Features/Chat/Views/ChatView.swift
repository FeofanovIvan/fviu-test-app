import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel: ChatViewModel
    @StateObject private var keyboard = KeyboardObserver()
    @FocusState private var isInputFocused: Bool
    @Environment(\.dismiss) private var dismiss

    /// `.task` re-runs every time this view re-becomes the top of the NavigationStack (e.g.
    /// when popping back from Chat History), which would otherwise re-trigger the focus delay
    /// below on every return trip. This flag makes the auto-focus-on-open behavior fire only
    /// once, the first time the screen is actually opened.
    @State private var hasAutoFocusedOnce = false

    init(viewModel: ChatViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            AppColors.screenBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                chatHeader

                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: AppSpacing.medium) {
                            if shouldShowWelcome {
                                ChatWelcomeView()
                                    .opacity(hasDraftText ? 0 : 1)
                                    .animation(.easeOut(duration: 0.18), value: hasDraftText)
                            }

                            ForEach(visibleMessages) { message in
                                ChatBubbleView(message: message)
                                    .id(message.id)
                            }

                            if viewModel.state.isLoading {
                                TypingIndicatorView()
                                    .id("typing")
                            }

                            if case .error(let error) = viewModel.state {
                                ChatErrorBanner(error: error)
                            }
                        }
                        .padding(AppSpacing.screen)
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        scrollToBottom(proxy)
                    }
                    .onChange(of: viewModel.state.isLoading) { _ in
                        scrollToBottom(proxy)
                    }
                }

                // The bar is always part of the VStack — it is never conditionally hidden.
                // SwiftUI's automatic keyboard-avoidance safe-area inset proved unreliable here
                // (it could settle at zero after a navigation push/pop, leaving the bar rendered
                // under the keyboard), so the bottom inset is ignored entirely and the bar's
                // position is driven manually from real keyboard-frame notifications instead.
                ChatInputBar(
                    text: $viewModel.draft,
                    isFocused: $isInputFocused,
                    isSendEnabled: viewModel.canSend,
                    isKeyboardVisible: keyboard.height > 0
                ) {
                    Task {
                        await viewModel.send()
                        // Once the AI has finished responding, dismiss the keyboard automatically.
                        // The input bar itself always stays visible — its position no longer
                        // depends on focus state at all.
                        isInputFocused = false
                    }
                }
                .padding(.bottom, keyboard.height)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            guard !hasAutoFocusedOnce else { return }
            hasAutoFocusedOnce = true
            try? await Task.sleep(nanoseconds: 300_000_000)
            isInputFocused = true
        }
    }

    private var chatHeader: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColors.primaryText)
                    .frame(width: 28, height: 38)
            }
            .accessibilityLabel(L10n.back)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [AppColors.gradientBlue, AppColors.gradientPink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 32, height: 32)
                .overlay {
                    Image("ChatGenerateIconWhite")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                }

            VStack(alignment: .leading, spacing: 1) {
                Text(L10n.chatTitle)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppColors.primaryText)

                Text(Self.currentDateString)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(AppColors.primaryText.opacity(0.3))
            }

            Spacer()

            Button {
                isInputFocused = false
                viewModel.openHistory()
            } label: {
                Image("ChatHistoryIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .frame(width: 38, height: 38)
            }
            .accessibilityLabel(L10n.chatHistoryTitle)
        }
        .padding(.horizontal, AppSpacing.screen)
        .padding(.top, 16)
        .padding(.bottom, AppSpacing.small)
        .background(.black.opacity(0.18))
    }

    private static let currentDateString: String = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: Date())
    }()

    private var visibleMessages: [ChatMessage] {
        shouldShowWelcome ? viewModel.messages.filter { $0.role != .assistant || $0.text != L10n.chatWelcomeMessage } : viewModel.messages
    }

    private var shouldShowWelcome: Bool {
        viewModel.messages.count == 1 && viewModel.messages.first?.role == .assistant
    }

    private var hasDraftText: Bool {
        !viewModel.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.24)) {
            if viewModel.state.isLoading {
                proxy.scrollTo("typing", anchor: .bottom)
            } else if let lastID = viewModel.messages.last?.id {
                proxy.scrollTo(lastID, anchor: .bottom)
            }
        }
    }
}

private struct ChatWelcomeView: View {
    var body: some View {
        VStack(spacing: AppSpacing.small) {
            Spacer(minLength: 110)

            HStack(spacing: 0) {
                Text("Your ")
                    .foregroundStyle(AppColors.primaryText)

                Text("AI assistant")
                    .foregroundStyle(.white)
                    .overlay {
                        LinearGradient(
                            colors: [AppColors.gradientBlue, AppColors.gradientPink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .mask(
                            Text("AI assistant")
                                .font(.system(size: 20, weight: .semibold))
                        )
                    }

                Text(" for anything")
                    .foregroundStyle(AppColors.primaryText)
            }
            .font(.system(size: 20, weight: .semibold))
            .multilineTextAlignment(.center)
            .frame(width: 285)

            Text("Ask questions, get answers, and explore ideas in seconds")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(AppColors.primaryText.opacity(0.5))
                .multilineTextAlignment(.center)
                .frame(width: 344)

            Spacer(minLength: 80)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ChatBubbleView: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top) {
            if message.role == .assistant {
                assistantBubble
                Spacer(minLength: 44)
            } else {
                Spacer(minLength: 44)
                userBubble
            }
        }
    }

    private var assistantBubble: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text(message.text)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(AppColors.primaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .background(AppColors.chatAssistantBubble)
        .clipShape(
            CornerRadiusShape(topLeft: 24, topRight: 24, bottomLeft: 0, bottomRight: 24)
        )
    }

    private var userBubble: some View {
        Text(message.text)
            .font(.system(size: 16, weight: .regular))
            .foregroundStyle(.white)
            .fixedSize(horizontal: false, vertical: true)
            .padding(16)
            .background {
                LinearGradient(
                    colors: [
                        AppColors.gradientBlue.opacity(0.9),
                        AppColors.gradientPink.opacity(0.9)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
            .clipShape(
                CornerRadiusShape(topLeft: 24, topRight: 24, bottomLeft: 24, bottomRight: 0)
            )
    }
}

private struct ChatInputBar: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    let isSendEnabled: Bool
    /// The on-screen keyboard already has its own dictation/mic button, so our mic icon
    /// is only shown in the "collapsed" (keyboard-hidden) state — never alongside the keyboard.
    let isKeyboardVisible: Bool
    let onSend: () -> Void

    private var hasText: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        HStack(spacing: AppSpacing.small) {
            TextField("", text: $text, axis: .vertical)
                .placeholder(when: text.isEmpty) {
                    Text("Ask anything...")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(Color(red: 0x60 / 255.0, green: 0x60 / 255.0, blue: 0x60 / 255.0))
                }
                .lineLimit(1...4)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(AppColors.primaryText)
                .padding(.horizontal, AppSpacing.medium)
                .padding(.vertical, 12)
                .focused(isFocused)

            HStack(spacing: 8) {
                if hasText {
                    Button(action: onSend) {
                        Image("ChatSendIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .frame(width: 40, height: 40)
                            .background {
                                if isSendEnabled {
                                    LinearGradient(
                                        colors: [AppColors.gradientBlue, AppColors.gradientPink],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                } else {
                                    AppColors.elevatedBackground
                                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                }
                            }
                    }
                    .disabled(!isSendEnabled)
                    .accessibilityLabel(L10n.send)
                    .transition(.scale.combined(with: .opacity))
                } else {
                    if !isKeyboardVisible {
                        Button {} label: {
                            Image("ChatMicIcon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                        }
                        .accessibilityLabel("Voice input")
                        .transition(.scale.combined(with: .opacity))
                    }

                    Button {} label: {
                        Image("ChatDownloadIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                    }
                    .accessibilityLabel("Attach")
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.trailing, AppSpacing.small)
            .animation(.easeInOut(duration: 0.18), value: hasText)
            .animation(.easeInOut(duration: 0.18), value: isKeyboardVisible)
        }
        .padding(.vertical, AppSpacing.small)
        .padding(.horizontal, AppSpacing.small)
        .background(AppColors.glassDark, in: RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous))
        .padding(.horizontal, AppSpacing.screen)
        .padding(.top, AppSpacing.small)
        .padding(.bottom, AppSpacing.medium)
        .background(
            Color(red: 0x1F / 255.0, green: 0x19 / 255.0, blue: 0x1F / 255.0)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(.white.opacity(0.08))
                        .frame(height: 1)
                }
                .clipShape(CornerRadiusShape(topLeft: AppRadius.control, topRight: AppRadius.control, bottomLeft: 0, bottomRight: 0))
        )
    }
}

private extension View {
    @ViewBuilder
    func placeholder<Content: View>(when shouldShow: Bool, alignment: Alignment = .leading, @ViewBuilder placeholder: () -> Content) -> some View {
        ZStack(alignment: alignment) {
            if shouldShow {
                placeholder()
            }
            self
        }
    }
}

private struct TypingIndicatorView: View {
    var body: some View {
        HStack(alignment: .top) {
            HStack(spacing: 4) {
                TypingDot(size: 19, isAccent: true, delay: 0)
                TypingDot(size: 15, isAccent: false, delay: 0.15)
                TypingDot(size: 10, isAccent: false, delay: 0.3)
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .background(AppColors.chatAssistantBubble)
            .clipShape(
                CornerRadiusShape(topLeft: 24, topRight: 24, bottomLeft: 0, bottomRight: 24)
            )

            Spacer(minLength: 44)
        }
    }
}

/// A single dot in the typing indicator. The accent dot carries the Figma gradient fill
/// and the other two stay dim white, while all three gently bounce in a staggered wave —
/// the conventional "AI is typing" animation.
private struct TypingDot: View {
    let size: CGFloat
    let isAccent: Bool
    let delay: Double

    @State private var isBouncing = false

    var body: some View {
        Circle()
            .fill(fill)
            .frame(width: size, height: size)
            .scaleEffect(isBouncing ? 1.0 : 0.6)
            .opacity(isBouncing ? 1.0 : 0.4)
            .animation(
                .easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(delay),
                value: isBouncing
            )
            .onAppear { isBouncing = true }
    }

    private var fill: AnyShapeStyle {
        if isAccent {
            AnyShapeStyle(
                LinearGradient(
                    colors: [AppColors.gradientBlue, AppColors.gradientPink],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        } else {
            AnyShapeStyle(Color.white.opacity(0.1))
        }
    }
}

private struct ChatErrorBanner: View {
    let error: AppError

    var body: some View {
        HStack(spacing: AppSpacing.small) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AppColors.error)

            VStack(alignment: .leading, spacing: 2) {
                Text(error.title)
                    .font(AppTypography.caption.weight(.semibold))
                    .foregroundStyle(AppColors.primaryText)

                Text(error.message)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.secondaryText)
            }

            Spacer()
        }
        .padding(AppSpacing.medium)
        .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: AppRadius.medium))
    }
}
