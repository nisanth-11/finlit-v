import SwiftUI

struct QuizResultsView: View {
    let total: Int
    let correct: Int
    let coinsEarned: Int
    let onBackToRoadmap: () -> Void
    let onRetry: () -> Void
    let onUseShield: (() async -> Void)?

    @ObservedObject private var lang = LanguageManager.shared
    @State private var usingShield = false

    private var isPass: Bool { correct >= total - 1 }
    private var title: String {
        if correct == total { return "Perfect!" }
        if correct == total - 1 { return "Great job! 😊" }
        if correct == total - 2 { return "Good try, but try again 🙁" }
        return "Try again 😔"
    }

    var body: some View {
        VStack(spacing: 16) {
            if isPass {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.yellow)
            }
            Text(title).font(.title2.bold())
            Text("\(lang.t("you_scored")) \(correct) \(lang.t("out_of")) \(total)")
                .foregroundStyle(.secondary)

            HStack {
                Image(systemName: "dollarsign.circle.fill").foregroundStyle(.yellow)
                Text("\(lang.t("you_earned")) \(coinsEarned) \(lang.t("coins_reward"))")
                    .fontWeight(.bold)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.yellow.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 14))

            if isPass {
                Button(action: onBackToRoadmap) {
                    Text(lang.t("back_to_roadmap"))
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(brandGreen)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            } else {
                HStack(spacing: 12) {
                    Button(action: onRetry) {
                        Text(lang.t("try_again"))
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    if let onUseShield {
                        Button {
                            usingShield = true
                            Task {
                                await onUseShield()
                                usingShield = false
                            }
                        } label: {
                            Group {
                                if usingShield {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Use Quiz Shield 🛡️").fontWeight(.bold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        }
                        .background(brandGreen)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
        }
        .padding(28)
        .presentationDetents([.medium])
    }
}
