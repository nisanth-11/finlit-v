import SwiftUI

struct LessonDetailView: View {
    let lesson: Lesson
    let isReplay: Bool
    let onCompleted: () async -> Void

    @State private var questions: [QuizQuestion] = []
    @State private var isLoading = true
    @State private var loadError = false
    @ObservedObject private var lang = LanguageManager.shared

    var body: some View {
        Group {
            if isLoading {
                ProgressView().tint(brandGreen)
            } else if loadError {
                ContentUnavailableView(
                    lang.t("quiz_load_error"),
                    systemImage: "wifi.slash",
                    description: Text(lang.t("quiz_load_error_desc"))
                )
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Module \(lesson.moduleNumber) · \(lesson.sectionName)")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(brandGreen.opacity(0.15))
                            .foregroundStyle(brandGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                        Text(lesson.title)
                            .font(.largeTitle.bold())

                        if let content = lesson.content, !content.isEmpty {
                            Text(content).font(.body)
                        } else if let description = lesson.description, !description.isEmpty {
                            Text(description).font(.body)
                        }

                        NavigationLink {
                            QuizView(lesson: lesson, questions: questions, isReplay: isReplay, onFinished: onCompleted)
                        } label: {
                            Text("\(lang.t("start_quiz"))  →")
                                .font(.system(size: 18, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(brandGreen)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.top, 12)
                    }
                    .padding(20)
                }
            }
        }
        .navigationTitle(lesson.title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private func load() async {
        do {
            questions = try await ApiService.shared.fetchQuestions(lessonId: lesson.id)
            loadError = questions.isEmpty
        } catch {
            loadError = true
        }
        isLoading = false
    }
}
