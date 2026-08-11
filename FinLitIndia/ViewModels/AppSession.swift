import Foundation

@MainActor
final class AppSession: ObservableObject {
    @Published var profile: Profile?
    @Published var isBootstrapping = true

    var isRegistered: Bool { profile != nil }

    private let api = ApiService.shared

    func bootstrap() async {
        isBootstrapping = true
        defer { isBootstrapping = false }
        do {
            let userId = try await api.ensureSignedIn()
            profile = try await api.fetchProfile(userId: userId)
        } catch {
            print("Bootstrap failed: \(error)")
        }
    }

    func register(phone: String, name: String, language: String) async throws {
        let newProfile = try await api.registerOrFetchProfile(phone: phone)
        try await api.updateProfile(name: name, language: language)
        var updated = newProfile
        updated.name = name
        updated.language = language
        profile = updated
    }

    func refreshProfile() async {
        guard let userId = profile?.id else { return }
        if let updated = try? await api.fetchProfile(userId: userId) {
            profile = updated
        }
    }
}
