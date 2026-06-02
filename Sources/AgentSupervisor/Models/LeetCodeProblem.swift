import Foundation

struct LeetCodeProblem: Identifiable, Codable, Hashable {
    let id: Int
    let title: String
    let slug: String
    let difficulty: Difficulty
    let isPaid: Bool
    let acceptance: Double?

    enum Difficulty: String, Codable, Hashable {
        case easy = "Easy"
        case medium = "Medium"
        case hard = "Hard"
    }
}

struct LeetCodeProblemListResponse: Codable {
    let stat_status_pairs: [StatStatusPair]

    struct StatStatusPair: Codable {
        let stat: Stat
        let difficulty: Difficulty
        let paid_only: Bool

        enum CodingKeys: String, CodingKey {
            case stat, difficulty
            case paid_only
        }

        struct Stat: Codable {
            let question_id: Int
            let question__title: String
            let question__title_slug: String
            let total_acs: Int
            let total_submitted: Int

            enum CodingKeys: String, CodingKey {
                case question_id
                case question__title
                case question__title_slug
                case total_acs
                case total_submitted
            }
        }

        struct Difficulty: Codable {
            let level: Int
        }
    }
}

struct LeetCodeProblemDetail: Codable {
    let data: QuestionData?

    struct QuestionData: Codable {
        let question: Question?

        struct Question: Codable {
            let questionId: Int
            let title: String
            let titleSlug: String
            let content: String?
            let difficulty: String?
        }
    }
}
