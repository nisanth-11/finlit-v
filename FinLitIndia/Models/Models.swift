import Foundation

struct Lesson: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var title: String
    var description: String?
    var content: String?
    var moduleNumber: Int
    var sectionName: String
    var coinsReward: Int
    var orderIndex: Int

    enum CodingKeys: String, CodingKey {
        case id, title, description, content
        case moduleNumber = "module_number"
        case sectionName = "section_name"
        case coinsReward = "coins_reward"
        case orderIndex = "order_index"
    }
}

struct QuizQuestion: Identifiable, Codable, Equatable {
    let id: UUID
    var lessonId: UUID
    var question: String
    var option1: String
    var option2: String
    var option3: String
    var option4: String
    var correctOption: Int // 1-based, matches the database

    enum CodingKeys: String, CodingKey {
        case id, question
        case lessonId = "lesson_id"
        case option1 = "option_1"
        case option2 = "option_2"
        case option3 = "option_3"
        case option4 = "option_4"
        case correctOption = "correct_option"
    }

    var options: [String] { [option1, option2, option3, option4] }
    var correctIndex: Int { correctOption - 1 }
}

struct Profile: Codable, Equatable {
    var id: UUID
    var phone: String
    var name: String?
    var language: String?
    var streakCount: Int
    var coins: Int
    var lastActiveDate: String?
    var streakFreezeCount: Int
    var doubleCoinCount: Int
    var quizShieldCount: Int
    var doubleCoinActiveUntil: String?

    enum CodingKeys: String, CodingKey {
        case id, phone, name, language, coins
        case streakCount = "streak_count"
        case lastActiveDate = "last_active_date"
        case streakFreezeCount = "streak_freeze_count"
        case doubleCoinCount = "double_coin_count"
        case quizShieldCount = "quiz_shield_count"
        case doubleCoinActiveUntil = "double_coin_active_until"
    }
}

struct LessonProgress: Codable, Equatable {
    var userId: UUID
    var lessonId: UUID
    var isCompleted: Bool
    var completedAt: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case lessonId = "lesson_id"
        case isCompleted = "is_completed"
        case completedAt = "completed_at"
    }
}

struct QuizResultRecord: Codable, Equatable {
    var lessonId: UUID
    var score: Int

    enum CodingKeys: String, CodingKey {
        case lessonId = "lesson_id"
        case score
    }
}

struct Budget: Codable, Equatable {
    var userId: UUID
    var totalIncome: Double
    var food: Double
    var rent: Double
    var education: Double
    var transport: Double
    var savings: Double

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case totalIncome = "total_income"
        case food, rent, education, transport, savings
    }
}
