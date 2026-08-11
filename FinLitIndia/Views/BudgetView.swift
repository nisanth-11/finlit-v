import SwiftUI

struct BudgetView: View {
    @EnvironmentObject private var session: AppSession
    @ObservedObject private var lang = LanguageManager.shared

    @State private var incomeText = ""
    @State private var foodText = ""
    @State private var rentText = ""
    @State private var educationText = ""
    @State private var transportText = ""
    @State private var savingsText = ""

    private var income: Double { Double(incomeText) ?? 0 }
    private var totalAllocated: Double {
        (Double(foodText) ?? 0) + (Double(rentText) ?? 0) + (Double(educationText) ?? 0)
            + (Double(transportText) ?? 0) + (Double(savingsText) ?? 0)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Image(systemName: "wallet.bifold.fill").foregroundStyle(brandGreen)
                    Text(lang.t("budget_management")).font(.title.bold())
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(lang.t("monthly_income")).font(.subheadline.bold())
                    TextField("e.g. 15000", text: $incomeText)
                        .keyboardType(.numberPad)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                VStack(alignment: .leading, spacing: 16) {
                    Text(lang.t("categories")).font(.title3.bold())
                    categoryField(label: lang.t("food"), text: $foodText, color: brandGreen)
                    categoryField(label: lang.t("rent"), text: $rentText, color: .blue)
                    categoryField(label: lang.t("education"), text: $educationText, color: .orange)
                    categoryField(label: lang.t("transport"), text: $transportText, color: .purple)
                    categoryField(label: lang.t("savings"), text: $savingsText, color: .red)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(spacing: 12) {
                    summaryRow(label: lang.t("total_income"), value: income)
                    summaryRow(label: lang.t("total_allocated"), value: totalAllocated)
                    Divider()
                    summaryRow(label: lang.t("remaining_balance"), value: income - totalAllocated, bold: true)
                    if totalAllocated > income {
                        Text(lang.t("budget_exceeds")).font(.caption.bold()).foregroundStyle(.red)
                    }
                }
                .padding()
                .background(brandGreen.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(brandGreen, lineWidth: 2))

                if income > 0 {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(lang.t("suggested_breakdown")).font(.title3.bold())
                        Text(lang.t("suggested_desc")).font(.caption).foregroundStyle(.secondary)
                        summaryRow(label: "\(lang.t("food")) + \(lang.t("rent")) (50%)", value: income * 0.5)
                        summaryRow(label: "\(lang.t("education")) + \(lang.t("transport")) (30%)", value: income * 0.3)
                        summaryRow(label: "\(lang.t("savings")) (20%)", value: income * 0.2)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                HStack(spacing: 16) {
                    Button(lang.t("reset_budget")) {
                        Task { await reset() }
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)

                    Button(lang.t("save_budget")) {
                        Task { await save() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(20)
        }
        .task { await load() }
    }

    private func categoryField(label: String, text: Binding<String>, color: Color) -> some View {
        HStack {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(label).fontWeight(.semibold)
            Spacer()
            TextField("0", text: text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 100)
        }
    }

    private func summaryRow(label: String, value: Double, bold: Bool = false) -> some View {
        HStack {
            Text(label).fontWeight(bold ? .bold : .semibold)
            Spacer()
            Text("₹\(Int(value))").fontWeight(.bold).foregroundStyle(bold ? Color.primary : brandGreen)
        }
    }

    private func load() async {
        guard let userId = session.profile?.id else { return }
        if let budget = try? await ApiService.shared.fetchBudget(userId: userId) {
            incomeText = String(Int(budget.totalIncome))
            foodText = String(Int(budget.food))
            rentText = String(Int(budget.rent))
            educationText = String(Int(budget.education))
            transportText = String(Int(budget.transport))
            savingsText = String(Int(budget.savings))
        }
    }

    private func save() async {
        guard let userId = session.profile?.id else { return }
        let budget = Budget(
            userId: userId,
            totalIncome: income,
            food: Double(foodText) ?? 0,
            rent: Double(rentText) ?? 0,
            education: Double(educationText) ?? 0,
            transport: Double(transportText) ?? 0,
            savings: Double(savingsText) ?? 0
        )
        try? await ApiService.shared.saveBudget(budget)
    }

    private func reset() async {
        incomeText = ""
        foodText = ""
        rentText = ""
        educationText = ""
        transportText = ""
        savingsText = ""
        guard let userId = session.profile?.id else { return }
        let budget = Budget(userId: userId, totalIncome: 0, food: 0, rent: 0, education: 0, transport: 0, savings: 0)
        try? await ApiService.shared.saveBudget(budget)
    }
}
