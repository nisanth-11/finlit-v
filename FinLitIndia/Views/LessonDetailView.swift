import SwiftUI

struct LessonDetailView: View {
    let lesson: Lesson
    let isReplay: Bool
    let onCompleted: () async -> Void
    let onReturnToRoadmap: () -> Void

    @State private var questions: [QuizQuestion] = []
    @State private var isLoading = true
    @State private var loadError = false
    @State private var dialogueComplete = false
    @ObservedObject private var lang = LanguageManager.shared

    private var dialogueMessages: [DialogueMessage] {
        guard let content = lesson.content, !content.isEmpty else { return [] }
        return DialogueScript.decode(content)
    }

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
                VStack(spacing: 0) {
                    HStack {
                        Text("Module \(lesson.moduleNumber) · \(lesson.sectionName)")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(brandGreen.opacity(0.15))
                            .foregroundStyle(brandGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                    if dialogueMessages.isEmpty {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 16) {
                                if let description = lesson.description, !description.isEmpty {
                                    Text(description).font(.body)
                                }
                            }
                            .padding(20)
                        }
                        .onAppear { dialogueComplete = true }
                    } else {
                        LessonChatView(messages: dialogueMessages) {
                            dialogueComplete = true
                        }
                    }

                    if dialogueComplete {
                        NavigationLink {
                            QuizView(lesson: lesson, questions: questions, isReplay: isReplay, onFinished: {
                                // Refresh the roadmap's data, then collapse the whole pushed
                                // stack (this lesson screen + QuizView) back to RoadmapView by
                                // clearing its selection state directly -- more reliable than
                                // chaining dismiss() across navigation levels from inside a
                                // sheet's dismiss handler, which raced and silently no-opped.
                                await onCompleted()
                                onReturnToRoadmap()
                            })
                        } label: {
                            Text("\(lang.t("start_quiz"))  →")
                                .font(.system(size: 18, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(brandGreen)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(16)
                        .background(Color(.systemBackground).shadow(color: .black.opacity(0.06), radius: 8, y: -2))
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .animation(.easeOut(duration: 0.3), value: dialogueComplete)
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
