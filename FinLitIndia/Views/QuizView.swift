import SwiftUI

struct QuizView: View {
    let lesson: Lesson
    let questions: [QuizQuestion]
    let isReplay: Bool
    let onFinished: () async -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: AppSession
    @ObservedObject private var lang = LanguageManager.shared

    @State private var selectedAnswers: [Int?]
    @State private var currentIndex = 0
    @State private var isSubmitted = false
    @State private var isSubmitting = false
    @State private var showingResults = false
    @State private var coinsEarned = 0
    @State private var resultCorrectCount = 0

    init(lesson: Lesson, questions: [QuizQuestion], isReplay: Bool, onFinished: @escaping () async -> Void) {
        self.lesson = lesson
        self.questions = questions
        self.isReplay = isReplay
        self.onFinished = onFinished
        _selectedAnswers = State(initialValue: Array(repeating: nil, count: questions.count))
    }

    private var question: QuizQuestion { questions[currentIndex] }
    private var hasSelection: Bool { selectedAnswers[currentIndex] != nil }
    private var isLastQuestion: Bool { currentIndex == questions.count - 1 }

    private var correctCount: Int {
        var count = 0
        for i in 0..<questions.count where selectedAnswers[i] == questions[i].correctIndex {
            count += 1
        }
        return count
    }

    var body: some View {
        VStack(spacing: 0) {
            ProgressView(value: Double(currentIndex + 1), total: Double(questions.count))
                .tint(brandGreen)
                .padding()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Q\(currentIndex + 1). \(question.question)")
                        .font(.title3.weight(.semibold))

                    ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                        optionRow(index: index, text: option)
                    }

                    if isSubmitted, let selected = selectedAnswers[currentIndex], selected != question.correctIndex {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(brandGreen)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(lang.t("correct_answer_was")).font(.caption.bold()).foregroundStyle(brandGreen)
                                Text(question.options[question.correctIndex]).fontWeight(.semibold)
                            }
                        }
                        .padding()
                        .background(brandGreen.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(20)
            }

            Button {
                advance()
            } label: {
                Text(buttonLabel)
                    .font(.system(size: 18, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .background(hasSelection ? (isSubmitted ? brandGreen : Color.blue) : Color(.systemGray4))
            .foregroundStyle(.white)
            .disabled(!hasSelection || isSubmitting)
            .padding()
        }
        .navigationTitle("\(currentIndex + 1)/\(questions.count)")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .sheet(isPresented: $showingResults) {
            QuizResultsView(
                total: questions.count,
                correct: resultCorrectCount,
                coinsEarned: coinsEarned,
                onBackToRoadmap: {
                    showingResults = false
                    dismiss()
                },
                onRetry: {
                    showingResults = false
                    selectedAnswers = Array(repeating: nil, count: questions.count)
                    currentIndex = 0
                    isSubmitted = false
                    isSubmitting = false
                },
                onUseShield: resultCorrectCount == 3 ? { await useShieldAndFinish() } : nil
            )
            .interactiveDismissDisabled()
        }
    }

    private var buttonLabel: String {
        if !isSubmitted { return lang.t("check_answer") }
        return isLastQuestion ? lang.t("finish_quiz") : lang.t("next")
    }

    private func optionRow(index: Int, text: String) -> some View {
        let isSelected = selectedAnswers[currentIndex] == index
        let isCorrect = question.correctIndex == index
        var bg = Color(.secondarySystemBackground)
        var border = Color(.separator)
        if isSubmitted && isCorrect {
            bg = brandGreen.opacity(0.15); border = brandGreen
        } else if isSubmitted && isSelected && !isCorrect {
            bg = Color.red.opacity(0.1); border = .red
        } else if isSelected {
            bg = Color.blue.opacity(0.12); border = .blue
        }

        return Button {
            guard !isSubmitted else { return }
            selectedAnswers[currentIndex] = index
        } label: {
            HStack {
                ZStack {
                    Circle().fill(isSelected || (isSubmitted && isCorrect) ? border : Color(.systemGray5))
                        .frame(width: 30, height: 30)
                    Text(["A", "B", "C", "D"][index])
                        .font(.caption.bold())
                        .foregroundStyle(isSelected || (isSubmitted && isCorrect) ? Color.white : Color.secondary)
                }
                Text(text).foregroundStyle(.primary)
                Spacer()
                if isSubmitted && isCorrect {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(brandGreen)
                } else if isSubmitted && isSelected {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
                }
            }
            .padding()
            .background(bg)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(border, lineWidth: 2))
        }
        .disabled(isSubmitted)
    }

    private func advance() {
        if !isSubmitted {
            isSubmitted = true
        } else if isLastQuestion {
            Task { await submitQuiz() }
        } else {
            currentIndex += 1
            isSubmitted = false
        }
    }

    private func submitQuiz() async {
        guard !isSubmitting else { return }
        isSubmitting = true
        let correct = correctCount
        resultCorrectCount = correct

        if correct < 4 {
            coinsEarned = 0
            isSubmitting = false
            showingResults = true
            return
        }

        do {
            let answers = selectedAnswers.map { $0 ?? -1 }
            let earned = try await ApiService.shared.submitQuiz(lessonId: lesson.id, answers: answers, isReplay: isReplay)
            try await ApiService.shared.saveProgress(lessonId: lesson.id, isCompleted: true)
            coinsEarned = earned
            await session.refreshProfile()
        } catch {
            coinsEarned = 0
        }
        isSubmitting = false
        showingResults = true
    }

    private func useShieldAndFinish() async {
        do {
            try await ApiService.shared.useShopItem("quiz_shield")
            try await ApiService.shared.saveProgress(lessonId: lesson.id, isCompleted: true)
            await session.refreshProfile()
            showingResults = false
            dismiss()
        } catch {
            print("Quiz shield unavailable: \(error)")
        }
    }
}
