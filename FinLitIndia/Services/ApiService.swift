import Foundation
import Supabase

enum ApiError: LocalizedError {
    case message(String)
    var errorDescription: String? {
        switch self {
        case .message(let text): return text
        }
    }
}

final class ApiService {
    static let shared = ApiService()
    private let client = SupabaseService.shared.client

    // MARK: - Auth

    @discardableResult
    func ensureSignedIn() async throws -> UUID {
        if let session = try? await client.auth.session {
            return session.user.id
        }
        let session = try await client.auth.signInAnonymously()
        return session.user.id
    }

    private struct AuthUpsertBody: Encodable { let phone: String }
    private struct AuthUpsertResponse: Decodable { let user_id: UUID; let user: Profile }

    func registerOrFetchProfile(phone: String) async throws -> Profile {
        do {
            let response: AuthUpsertResponse = try await client.functions.invoke(
                "auth-upsert",
                options: FunctionInvokeOptions(body: AuthUpsertBody(phone: phone))
            )
            return response.user
        } catch {
            throw extractApiError(error, fallback: "Failed to register. Check connection.")
        }
    }

    private struct UpdateProfileBody: Encodable { let name: String; let language: String }
    private struct EmptyDecodable: Decodable {}

    func updateProfile(name: String, language: String) async throws {
        let _: EmptyDecodable = try await client.functions.invoke(
            "update-profile",
            options: FunctionInvokeOptions(body: UpdateProfileBody(name: name, language: language))
        )
    }

    // MARK: - Profile

    func fetchProfile(userId: UUID) async throws -> Profile? {
        let profiles: [Profile] = try await client.from("profiles")
            .select()
            .eq("id", value: userId)
            .execute()
            .value
        return profiles.first
    }

    // MARK: - Lessons

    func fetchLessons() async throws -> [Lesson] {
        try await client.from("lessons")
            .select()
            .order("order_index")
            .execute()
            .value
    }

    func fetchQuestions(lessonId: UUID) async throws -> [QuizQuestion] {
        try await client.from("questions")
            .select()
            .eq("lesson_id", value: lessonId)
            .execute()
            .value
    }

    // MARK: - Progress

    func fetchProgress(userId: UUID) async throws -> [LessonProgress] {
        try await client.from("progress")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value
    }

    private struct SaveProgressBody: Encodable { let lesson_id: UUID; let is_completed: Bool }
    private struct SaveProgressResponse: Decodable { let bonus_coins_earned: Int }

    @discardableResult
    func saveProgress(lessonId: UUID, isCompleted: Bool) async throws -> Int {
        let response: SaveProgressResponse = try await client.functions.invoke(
            "save-progress",
            options: FunctionInvokeOptions(body: SaveProgressBody(lesson_id: lessonId, is_completed: isCompleted))
        )
        return response.bonus_coins_earned
    }

    // MARK: - Quiz

    private struct SubmitQuizBody: Encodable { let lesson_id: UUID; let answers: [Int]; let is_replay: Bool }
    private struct SubmitQuizResponse: Decodable { let coins_earned: Int }

    func submitQuiz(lessonId: UUID, answers: [Int], isReplay: Bool) async throws -> Int {
        let response: SubmitQuizResponse = try await client.functions.invoke(
            "submit-quiz",
            options: FunctionInvokeOptions(body: SubmitQuizBody(lesson_id: lessonId, answers: answers, is_replay: isReplay))
        )
        return response.coins_earned
    }

    func fetchQuizResults(userId: UUID) async throws -> [QuizResultRecord] {
        try await client.from("quiz_results")
            .select("lesson_id, score")
            .eq("user_id", value: userId)
            .execute()
            .value
    }

    // MARK: - Shop

    private struct ShopBuyBody: Encodable { let item: String }
    private struct ShopBuyResponse: Decodable { let remaining_coins: Int }

    func buyShopItem(_ item: String) async throws -> Int {
        do {
            let response: ShopBuyResponse = try await client.functions.invoke(
                "shop-buy",
                options: FunctionInvokeOptions(body: ShopBuyBody(item: item))
            )
            return response.remaining_coins
        } catch {
            throw extractApiError(error, fallback: "Purchase failed")
        }
    }

    private struct ActivateDoubleCoinResponse: Decodable { let active_until: String }

    func activateDoubleCoin() async throws -> String {
        struct Empty: Encodable {}
        do {
            let response: ActivateDoubleCoinResponse = try await client.functions.invoke(
                "shop-activate-double-coin",
                options: FunctionInvokeOptions(body: Empty())
            )
            return response.active_until
        } catch {
            throw extractApiError(error, fallback: "Activation failed")
        }
    }

    private struct ShopUseBody: Encodable { let item: String }

    func useShopItem(_ item: String) async throws {
        do {
            let _: EmptyDecodable = try await client.functions.invoke(
                "shop-use",
                options: FunctionInvokeOptions(body: ShopUseBody(item: item))
            )
        } catch {
            throw extractApiError(error, fallback: "None available")
        }
    }

    // MARK: - Budget

    func fetchBudget(userId: UUID) async throws -> Budget? {
        let budgets: [Budget] = try await client.from("budgets")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value
        return budgets.first
    }

    func saveBudget(_ budget: Budget) async throws {
        try await client.from("budgets").upsert(budget).execute()
    }

    // MARK: - Error extraction

    private struct EdgeFunctionError: Decodable { let error: String }

    private func extractApiError(_ error: Error, fallback: String) -> ApiError {
        if case FunctionsError.httpError(_, let data) = error,
           let decoded = try? JSONDecoder().decode(EdgeFunctionError.self, from: data) {
            return .message(decoded.error)
        }
        return .message(fallback)
    }
}
