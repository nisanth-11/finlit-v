import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var session: AppSession
    @ObservedObject private var lang = LanguageManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var isSaving = false

    private let languages: [(code: String, label: String)] = [
        ("en", "English"), ("hi", "हिन्दी"), ("kn", "ಕನ್ನಡ")
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section(lang.t("edit_name")) {
                    TextField(lang.t("name_hint"), text: $name)
                }
                Section(lang.t("select_language")) {
                    Picker(lang.t("language"), selection: $lang.languageCode) {
                        ForEach(languages, id: \.code) { language in
                            Text(language.label).tag(language.code)
                        }
                    }
                    .pickerStyle(.inline)
                }
            }
            .navigationTitle(lang.t("settings"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(lang.t("save")) {
                        Task { await save() }
                    }
                    .disabled(isSaving)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { name = session.profile?.name ?? "" }
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        do {
            try await ApiService.shared.updateProfile(name: name, language: lang.languageCode)
            await session.refreshProfile()
            dismiss()
        } catch {
            print("Failed to save settings: \(error)")
        }
    }
}
