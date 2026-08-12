import SwiftUI
import UIKit

private let factCardBackground = Color(red: 0.910, green: 0.961, blue: 0.914)
private let factCardBorder = Color(red: 0.506, green: 0.780, blue: 0.518)
private let choiceBackground = Color(red: 0.941, green: 0.980, blue: 0.941)

struct LessonChatView: View {
    let messages: [DialogueMessage]
    let onComplete: () -> Void

    @State private var revealed: [ChatLine] = []
    @State private var pendingIndex = 0
    @State private var activeBranch: String?
    @State private var awaitingChoice: DialogueMessage?
    @State private var isTyping = false
    @State private var isComplete = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(revealed) { line in
                            chatRow(for: line)
                                .id(line.id)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity),
                                    removal: .opacity
                                ))
                        }
                        if isTyping {
                            typingIndicator.id("typing")
                        }
                    }
                    .padding(.vertical, 4)
                    .animation(.easeOut(duration: 0.25), value: revealed.count)
                }
                .onChange(of: revealed.count) { _, _ in scrollToBottom(proxy) }
                .onChange(of: isTyping) { _, _ in scrollToBottom(proxy) }
                .onChange(of: awaitingChoice?.id) { _, _ in scrollToBottom(proxy) }
            }

            if let choice = awaitingChoice {
                choicePanel(choice)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.25), value: awaitingChoice?.id)
        .task { await advance() }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        let target: String? = isTyping ? "typing" : revealed.last?.id.uuidString
        guard let target else { return }
        withAnimation(.easeOut(duration: 0.2)) {
            proxy.scrollTo(target, anchor: .bottom)
        }
    }

    // Walks the message list like the original LessonScreen.dart driver:
    // skip lines whose branch doesn't match the active one (unless it's the
    // "merge" reconvergence point), stop and wait at a choice, keep going
    // once the player taps an option.
    private func advance() async {
        while pendingIndex < messages.count {
            let item = messages[pendingIndex]
            pendingIndex += 1

            if item.type == "choice" {
                awaitingChoice = item
                return
            }

            if let branch = item.branch, branch != "merge", branch != activeBranch {
                continue
            }

            isTyping = true
            try? await Task.sleep(nanoseconds: 450_000_000)
            isTyping = false

            if let text = item.text {
                revealed.append(ChatLine(character: item.type == "fact_card" ? nil : item.character,
                                          text: text,
                                          isFactCard: item.type == "fact_card"))
            }
            try? await Task.sleep(nanoseconds: 200_000_000)
        }

        if !isComplete {
            isComplete = true
            onComplete()
        }
    }

    private func selectOption(_ option: DialogueOption) {
        guard awaitingChoice != nil else { return }
        activeBranch = option.branch
        awaitingChoice = nil
        revealed.append(ChatLine(character: "You", text: option.text, isFactCard: false))
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            await advance()
        }
    }

    @ViewBuilder
    private func chatRow(for line: ChatLine) -> some View {
        if line.isFactCard {
            factCard(line.text)
        } else if line.isUser {
            userBubble(line.text)
        } else {
            characterBubble(character: line.character ?? "", text: line.text)
        }
    }

    private func characterBubble(character: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(CharacterStyle.emoji(for: character))
                .font(.system(size: 26))
            VStack(alignment: .leading, spacing: 4) {
                Text(character)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(.systemBackground))
                    .clipShape(BubbleShape(isUser: false))
                    .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
            }
            Spacer(minLength: 52)
        }
        .padding(.horizontal, 16)
    }

    private func userBubble(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Spacer(minLength: 52)
            VStack(alignment: .trailing, spacing: 4) {
                Text("You")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(brandGreen)
                    .clipShape(BubbleShape(isUser: true))
                    .shadow(color: brandGreen.opacity(0.3), radius: 4, y: 2)
            }
        }
        .padding(.horizontal, 16)
    }

    private func factCard(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("⭐").font(.system(size: 18))
            Text(text)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color(red: 0.180, green: 0.490, blue: 0.196))
        }
        .padding(14)
        .background(factCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(factCardBorder, lineWidth: 1.5))
        .padding(.horizontal, 16)
    }

    private func choicePanel(_ choice: DialogueMessage) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Choose your response")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            ForEach(choice.options ?? [], id: \.branch) { option in
                Button {
                    selectOption(option)
                } label: {
                    Text(option.text)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color(red: 0.180, green: 0.490, blue: 0.196))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(choiceBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(brandGreen, lineWidth: 1.5))
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground).shadow(color: .black.opacity(0.06), radius: 8, y: -2))
    }

    private var typingIndicator: some View {
        HStack {
            TypingDots()
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
            Spacer()
        }
        .padding(.horizontal, 16)
    }
}

private struct BubbleShape: Shape {
    let isUser: Bool

    func path(in rect: CGRect) -> Path {
        var corners: UIRectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]
        corners.remove(isUser ? .topRight : .topLeft)
        return Path(UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: 16, height: 16)
        ).cgPath)
    }
}

private struct TypingDots: View {
    @State private var phase = 0.0

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color(.systemGray3))
                    .frame(width: 7, height: 7)
                    .offset(y: bounce(for: i))
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                phase = 1.0
            }
        }
    }

    private func bounce(for index: Int) -> CGFloat {
        let delay = Double(index) * 0.15
        let t = max(0, min(1, phase - delay))
        return -4 * sin(t * .pi)
    }
}
