import SwiftUI

struct RegistrationView: View {
    @EnvironmentObject private var session: AppSession
    @ObservedObject private var lang = LanguageManager.shared

    @State private var name = ""
    @State private var phone = ""
    @State private var isLoading = false
    @State private var errorText: String?
    @State private var nameErrorText: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Spacer(minLength: 40)

                RoundedRectangle(cornerRadius: 24)
                    .fill(brandGreen)
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: "banknote.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.white)
                    )

                VStack(spacing: 10) {
                    Text("FinLit India")
                        .font(.system(size: 34, weight: .bold))
                    Text("Learn smart money habits\none step at a time")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text(lang.t("your_name"))
                        .font(.headline)
                    TextField(lang.t("name_hint"), text: $name)
                        .textInputAutocapitalization(.words)
                        .accessibilityIdentifier("nameField")
                        .padding(20)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(nameErrorText != nil ? .red : Color(.separator), lineWidth: 1)
                        )
                    if let nameErrorText {
                        Text(nameErrorText).font(.caption).foregroundStyle(.red)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text(lang.t("enter_phone"))
                        .font(.headline)
                    HStack {
                        Text("+91")
                            .foregroundStyle(.secondary)
                        TextField("98765 43210", text: $phone)
                            .keyboardType(.numberPad)
                            .accessibilityIdentifier("phoneField")
                            .onChange(of: phone) {
                                phone = String(phone.filter(\.isNumber).prefix(10))
                            }
                    }
                    .padding(20)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(errorText != nil ? .red : Color(.separator), lineWidth: 1)
                    )
                    if let errorText {
                        Text(errorText).font(.caption).foregroundStyle(.red)
                    }
                }

                Button {
                    Task { await submit() }
                } label: {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text(lang.t("continue_btn"))
                            .font(.system(size: 18, weight: .bold))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(brandGreen)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .disabled(isLoading)
                .accessibilityIdentifier("continueButton")

                Text("Your phone number will only be used\nto save your progress.")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding(28)
        }
    }

    private func submit() async {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        var hasError = false
        if trimmedName.isEmpty {
            nameErrorText = lang.t("name_hint")
            hasError = true
        } else {
            nameErrorText = nil
        }
        if phone.count < 10 {
            errorText = lang.t("phone_error")
            hasError = true
        } else {
            errorText = nil
        }
        if hasError { return }

        isLoading = true
        defer { isLoading = false }
        do {
            try await session.register(phone: phone, name: trimmedName, language: lang.languageCode)
        } catch {
            errorText = error.localizedDescription
        }
    }
}
