import SwiftUI

struct ChatHistoryView: View {
    @StateObject private var viewModel: ChatHistoryViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: ChatHistoryViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            AppColors.screenBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                chatHistoryHeader

                if viewModel.hasSessions {
                    historyList
                } else {
                    ChatHistoryEmptyView()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            viewModel.reload()
        }
    }

    private var chatHistoryHeader: some View {
        ZStack {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppColors.primaryText)
                        .frame(width: 28, height: 38)
                }
                .accessibilityLabel(L10n.back)

                Spacer()
            }

            Text(L10n.chatHistoryTitle)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(AppColors.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 56)
        }
        .padding(.horizontal, AppSpacing.screen)
        .padding(.top, 16)
        .padding(.bottom, AppSpacing.small)
        .background(.black.opacity(0.18))
    }

    private var historyList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: AppSpacing.large) {
                historySection(title: L10n.today, sessions: todaysSessions)
                historySection(title: L10n.yesterday, sessions: yesterdaysSessions)
                ForEach(olderSessionGroups) { group in
                    historySection(title: group.title, sessions: group.sessions)
                }
            }
            .padding(AppSpacing.screen)
        }
    }

    @ViewBuilder
    private func historySection(title: String, sessions: [ChatSession]) -> some View {
        if !sessions.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppColors.primaryText)

                // Figma "Frame 1597881446": rows are stacked with a 12pt gap.
                VStack(spacing: 12) {
                    ForEach(sessions) { session in
                        ChatHistoryRow(session: session) {
                            viewModel.open(session)
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                viewModel.delete(session)
                            } label: {
                                Label(L10n.delete, systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
    }

    private var todaysSessions: [ChatSession] {
        viewModel.sessions.filter { Calendar.current.isDateInToday($0.updatedAt) }
    }

    private var yesterdaysSessions: [ChatSession] {
        viewModel.sessions.filter { Calendar.current.isDateInYesterday($0.updatedAt) }
    }

    private var olderSessions: [ChatSession] {
        viewModel.sessions.filter {
            !Calendar.current.isDateInToday($0.updatedAt) && !Calendar.current.isDateInYesterday($0.updatedAt)
        }
    }

    private var olderSessionGroups: [ChatHistorySectionGroup] {
        Dictionary(grouping: olderSessions) { session in
            Calendar.current.startOfDay(for: session.updatedAt)
        }
        .sorted { $0.key > $1.key }
        .map { date, sessions in
            ChatHistorySectionGroup(
                date: date,
                title: Self.sectionTitle(for: date),
                sessions: sessions.sorted { $0.updatedAt > $1.updatedAt }
            )
        }
    }

    private static func sectionTitle(for date: Date) -> String {
        if Calendar.current.isDate(date, equalTo: .now, toGranularity: .year) {
            return date.formatted(.dateTime.month(.wide).day())
        }
        return date.formatted(.dateTime.month(.wide).day().year())
    }
}

private struct ChatHistorySectionGroup: Identifiable {
    let date: Date
    let title: String
    let sessions: [ChatSession]

    var id: Date { date }
}

/// Matches the Figma "icon/Generate B" row spec exactly: 72pt tall, 24pt corner radius,
/// 16/24 vertical/horizontal padding, "#1F191F66" background fill, 28x28 icon (no circular
/// backdrop), 20px semibold title, and a 14px regular timestamp at 50% opacity white.
private struct ChatHistoryRow: View {
    let session: ChatSession
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.medium) {
                Image("ChatHistorySessionIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(session.title)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(AppColors.primaryText)
                        .lineLimit(1)

                    Text(session.updatedAt.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(Color.white.opacity(0.5))
                }

                Spacer()
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .frame(height: 72)
            .background(AppColors.historyCardBackground, in: RoundedRectangle(cornerRadius: AppRadius.control))
        }
        .buttonStyle(.plain)
    }
}

private struct ChatHistoryEmptyView: View {
    var body: some View {
        VStack(spacing: AppSpacing.medium) {
            Spacer()

            Image("ChatEmptyStateIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)

            Text(L10n.noChatsTitle)
                .font(AppTypography.title)
                .foregroundStyle(AppColors.primaryText)

            Text(L10n.noChatsMessage)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.secondaryText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 240)

            Spacer()
        }
        .padding(AppSpacing.screen)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
