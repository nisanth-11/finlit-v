import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var session: AppSession
    @ObservedObject private var lang = LanguageManager.shared

    @State private var totalLessons = 0
    @State private var completedCount = 0
    @State private var doubleCoinActiveUntil: Date?
    @State private var isLoading = true
    @State private var activatingDoubleCoin = false
    @State private var showingSettings = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack {
                    Text(lang.t("my_profile")).font(.largeTitle.bold())
                    Spacer()
                    Button { showingSettings = true } label: {
                        Image(systemName: "gearshape.fill").font(.title2).foregroundStyle(.secondary)
                    }
                }

                Circle()
                    .fill(brandGreen.opacity(0.15))
                    .frame(width: 100, height: 100)
                    .overlay(Circle().stroke(brandGreen, lineWidth: 3))
                    .overlay(Image(systemName: "person.fill").font(.system(size: 44)).foregroundStyle(brandGreen))

                Text(session.profile?.name ?? "Learner").font(.title2.bold())

                if isLoading {
                    ProgressView().tint(brandGreen).padding(.vertical, 40)
                } else {
                    HStack(spacing: 12) {
                        statCard(icon: "flame.fill", color: .orange, label: lang.t("streak"), value: session.profile?.streakCount ?? 0)
                        statCard(icon: "dollarsign.circle.fill", color: .yellow, label: lang.t("coins"), value: session.profile?.coins ?? 0)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("\(completedCount) / \(totalLessons) \(lang.t("lessons_completed"))")
                            .font(.subheadline.bold())
                        ProgressView(value: totalLessons > 0 ? Double(completedCount) / Double(totalLessons) : 0)
                            .tint(brandGreen)
                    }
                    .padding()
                    .background(brandGreen.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    ownedItemsSection
                }
            }
            .padding(20)
        }
        .task { await load() }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }

    private func statCard(icon: String, color: Color, label: String, value: Int) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).foregroundStyle(color).font(.title2)
            Text("\(value)").font(.title3.bold())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var ownedItemsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(lang.t("my_items")).font(.headline)

            HStack {
                Image(systemName: "snowflake").foregroundStyle(.blue)
                Text(lang.t("streak_freeze")).fontWeight(.semibold)
                Spacer()
                Text("x\(session.profile?.streakFreezeCount ?? 0)").foregroundStyle(.secondary).fontWeight(.bold)
            }

            HStack {
                Image(systemName: "arrow.right.circle.fill").foregroundStyle(.orange)
                Text(lang.t("double_coin")).fontWeight(.semibold)
                Spacer()
                Text("x\(session.profile?.doubleCoinCount ?? 0)").foregroundStyle(.secondary).fontWeight(.bold)
                doubleCoinTrailing
            }

            HStack {
                Image(systemName: "shield.fill").foregroundStyle(brandGreen)
                Text(lang.t("quiz_shield")).fontWeight(.semibold)
                Spacer()
                Text("x\(session.profile?.quizShieldCount ?? 0)").foregroundStyle(.secondary).fontWeight(.bold)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private var doubleCoinTrailing: some View {
        if let until = doubleCoinActiveUntil {
            Text("\(lang.t("active_until")): \(until.formatted(date: .numeric, time: .omitted))")
                .font(.caption.bold())
                .foregroundStyle(.orange)
        } else if (session.profile?.doubleCoinCount ?? 0) > 0 {
            Button {
                Task { await activateDoubleCoin() }
            } label: {
                if activatingDoubleCoin {
                    ProgressView()
                } else {
                    Text(lang.t("activate")).font(.caption.bold())
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .disabled(activatingDoubleCoin)
        }
    }

    private func load() async {
        guard let userId = session.profile?.id else {
            isLoading = false
            return
        }
        do {
            let progress = try await ApiService.shared.fetchProgress(userId: userId)
            completedCount = progress.filter(\.isCompleted).count
            let lessons = try await ApiService.shared.fetchLessons()
            totalLessons = lessons.count
            updateDoubleCoinExpiry(from: session.profile?.doubleCoinActiveUntil)
        } catch {
            print("Failed to load profile stats: \(error)")
        }
        isLoading = false
    }

    private func updateDoubleCoinExpiry(from raw: String?) {
        guard let raw, let date = ISO8601DateFormatter.withFractionalSeconds.date(from: raw), date > Date() else {
            doubleCoinActiveUntil = nil
            return
        }
        doubleCoinActiveUntil = date
    }

    private func activateDoubleCoin() async {
        activatingDoubleCoin = true
        defer { activatingDoubleCoin = false }
        do {
            let activeUntil = try await ApiService.shared.activateDoubleCoin()
            updateDoubleCoinExpiry(from: activeUntil)
            await session.refreshProfile()
        } catch {
            print("Activation failed: \(error)")
        }
    }
}
