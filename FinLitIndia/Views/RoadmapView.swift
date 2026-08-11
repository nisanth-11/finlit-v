import SwiftUI

struct RoadmapView: View {
    @EnvironmentObject private var session: AppSession
    @ObservedObject private var lang = LanguageManager.shared

    @State private var lessons: [Lesson] = []
    @State private var completedLessonIds: Set<UUID> = []
    @State private var perfectLessonIds: Set<UUID> = []
    @State private var isLoading = true

    private var lessonsByModule: [(module: Int, section: String, lessons: [Lesson])] {
        var groups: [Int: (section: String, lessons: [Lesson])] = [:]
        for lesson in lessons {
            groups[lesson.moduleNumber, default: (lesson.sectionName, [])].lessons.append(lesson)
        }
        return groups.keys.sorted().map { key in (key, groups[key]!.section, groups[key]!.lessons) }
    }

    private func isLocked(_ lesson: Lesson) -> Bool {
        guard let index = lessons.firstIndex(of: lesson), index > 0 else { return false }
        return !completedLessonIds.contains(lessons[index - 1].id)
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView().tint(brandGreen)
            } else if lessons.isEmpty {
                ContentUnavailableView("No lessons yet", systemImage: "book.closed")
            } else {
                List {
                    ForEach(lessonsByModule, id: \.module) { group in
                        Section {
                            ForEach(group.lessons) { lesson in
                                lessonRow(lesson)
                            }
                        } header: {
                            Text("Module \(group.module) · \(group.section)")
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("FinLit India")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 8) {
                    statChip(icon: "flame.fill", color: .orange, value: session.profile?.streakCount ?? 0)
                    statChip(icon: "dollarsign.circle.fill", color: .yellow, value: session.profile?.coins ?? 0)
                }
            }
        }
        .task { await loadData() }
        .refreshable { await loadData() }
    }

    private func statChip(icon: String, color: Color, value: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).foregroundStyle(color)
            Text("\(value)").fontWeight(.bold)
        }
        .font(.subheadline)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }

    @ViewBuilder
    private func lessonRow(_ lesson: Lesson) -> some View {
        let completed = completedLessonIds.contains(lesson.id)
        let perfect = perfectLessonIds.contains(lesson.id)
        let locked = isLocked(lesson)
        let index = (lessons.firstIndex(of: lesson) ?? 0) + 1

        if locked {
            HStack {
                statusCircle(completed: false, perfect: false, locked: true, index: index)
                Text(lesson.title).foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "lock.fill").foregroundStyle(.secondary)
            }
        } else {
            NavigationLink {
                LessonDetailView(lesson: lesson, isReplay: perfect, onCompleted: { await loadData() })
            } label: {
                HStack {
                    statusCircle(completed: completed, perfect: perfect, locked: false, index: index)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(lesson.title).fontWeight(.semibold)
                        Text("Module \(lesson.moduleNumber) · \(lesson.sectionName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if perfect {
                        Image(systemName: "star.fill").foregroundStyle(.yellow)
                    } else if completed {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(brandGreen)
                    }
                }
            }
        }
    }

    private func statusCircle(completed: Bool, perfect: Bool, locked: Bool, index: Int) -> some View {
        let color: Color = perfect ? .yellow : (completed ? brandGreen : (locked ? Color.gray.opacity(0.4) : brandGreen))
        return ZStack {
            Circle().fill(color).frame(width: 40, height: 40)
            Text("\(index)").font(.headline).foregroundStyle(.white)
        }
    }

    private func loadData() async {
        if lessons.isEmpty { isLoading = true }
        do {
            let fetchedLessons = try await ApiService.shared.fetchLessons()
            var completed: Set<UUID> = []
            var perfect: Set<UUID> = []
            if let userId = session.profile?.id {
                let progress = try await ApiService.shared.fetchProgress(userId: userId)
                completed = Set(progress.filter(\.isCompleted).map(\.lessonId))
                let results = try await ApiService.shared.fetchQuizResults(userId: userId)
                perfect = Set(results.filter { $0.score == 100 }.map(\.lessonId))
            }
            lessons = fetchedLessons.sorted { $0.orderIndex < $1.orderIndex }
            completedLessonIds = completed
            perfectLessonIds = perfect
            await session.refreshProfile()
        } catch {
            print("Failed to load roadmap: \(error)")
        }
        isLoading = false
    }
}
