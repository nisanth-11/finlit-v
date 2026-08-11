import SwiftUI

struct ShopView: View {
    @EnvironmentObject private var session: AppSession
    @ObservedObject private var lang = LanguageManager.shared
    @State private var buyingItem: String?
    @State private var errorMessage: String?

    private let items: [(key: String, icon: String, color: Color, price: Int)] = [
        ("streak_freeze", "snowflake", .blue, 200),
        ("double_coin", "arrow.right.circle.fill", .orange, 50),
        ("quiz_shield", "shield.fill", brandGreen, 100),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text(lang.t("shop")).font(.largeTitle.bold())
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "dollarsign.circle.fill").foregroundStyle(.yellow)
                        Text("\(session.profile?.coins ?? 0)").fontWeight(.bold)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.yellow.opacity(0.15))
                    .clipShape(Capsule())
                }
                Text(lang.t("spend_coins")).foregroundStyle(.secondary)

                ForEach(items, id: \.key) { item in
                    shopItemCard(item)
                }
            }
            .padding(20)
        }
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func shopItemCard(_ item: (key: String, icon: String, color: Color, price: Int)) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: item.icon).font(.system(size: 32)).foregroundStyle(item.color)
            VStack(alignment: .leading, spacing: 4) {
                Text(lang.t(item.key)).font(.headline)
                Text(lang.t("\(item.key)_desc")).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                Task { await buy(item.key) }
            } label: {
                if buyingItem == item.key {
                    ProgressView()
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "dollarsign.circle.fill").font(.caption)
                        Text("\(item.price)").fontWeight(.bold)
                    }
                }
            }
            .buttonStyle(.bordered)
            .tint(brandGreen)
            .disabled(buyingItem != nil)
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func buy(_ item: String) async {
        buyingItem = item
        defer { buyingItem = nil }
        do {
            _ = try await ApiService.shared.buyShopItem(item)
            await session.refreshProfile()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
