import Foundation

enum LeetCodeError: Error, LocalizedError {
    case invalidResponse
    case httpError(Int)
    case decodingFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid response from LeetCode"
        case .httpError(let code): return "HTTP error: \(code)"
        case .decodingFailed(let msg): return "Decoding failed: \(msg)"
        }
    }
}

actor LeetCodeService {
    private let session: URLSession
    private let listURL = URL(string: "https://leetcode.com/api/problems/all/")!
    private let graphqlURL = URL(string: "https://leetcode.com/graphql")!

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchProblems() async throws -> [LeetCodeProblem] {
        var request = URLRequest(url: listURL)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw LeetCodeError.httpError(code)
        }

        let decoded: LeetCodeProblemListResponse
        do {
            decoded = try JSONDecoder().decode(LeetCodeProblemListResponse.self, from: data)
        } catch {
            throw LeetCodeError.decodingFailed(error.localizedDescription)
        }

        return decoded.stat_status_pairs.map { pair in
            let acs = Double(pair.stat.total_acs)
            let subs = Double(pair.stat.total_submitted)
            let acceptance = (subs > 0) ? (acs / subs) * 100.0 : nil
            let difficulty: LeetCodeProblem.Difficulty = {
                switch pair.difficulty.level {
                case 1: return .easy
                case 2: return .medium
                case 3: return .hard
                default: return .easy
                }
            }()
            return LeetCodeProblem(
                id: pair.stat.question_id,
                title: pair.stat.question__title,
                slug: pair.stat.question__title_slug,
                difficulty: difficulty,
                isPaid: pair.paid_only,
                acceptance: acceptance
            )
        }
    }

    func fetchProblemContent(slug: String) async throws -> String {
        let body: [String: Any] = [
            "query": """
            query questionContent($titleSlug: String!) {
              question(titleSlug: $titleSlug) {
                questionId
                title
                titleSlug
                content
                difficulty
              }
            }
            """,
            "variables": ["titleSlug": slug]
        ]

        var request = URLRequest(url: graphqlURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw LeetCodeError.httpError(code)
        }

        let decoded = try JSONDecoder().decode(LeetCodeProblemDetail.self, from: data)
        return decoded.data?.question?.content ?? "<p>No content</p>"
    }
}
