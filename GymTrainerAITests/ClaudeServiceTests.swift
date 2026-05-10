import XCTest
@testable import GymTrainerAI

// MARK: - URLProtocol stub

/// Intercepts all URLSession.shared requests made during aiServicetests.
/// Configure `MockURLProtocol.requestHandler` before each test.
final class MockURLProtocol: URLProtocol {

    /// Set this before each test. Receives the outgoing URLRequest and returns
    /// (Data, HTTPURLResponse) or throws to simulate a network error.
    static var requestHandler: ((URLRequest) throws -> (Data, HTTPURLResponse))?

    /// Capture the last intercepted request so tests can inspect it.
    static var lastCapturedRequest: URLRequest?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        // URLSession strips httpBody before handing the request to URLProtocol;
        // read it back from httpBodyStream so tests can inspect the body.
        var captured = request
        if let stream = request.httpBodyStream {
            stream.open()
            var data = Data()
            var buf = [UInt8](repeating: 0, count: 4096)
            while stream.hasBytesAvailable {
                let n = stream.read(&buf, maxLength: buf.count)
                if n > 0 { data.append(&buf, count: n) }
            }
            stream.close()
            captured.httpBody = data
        }
        MockURLProtocol.lastCapturedRequest = captured
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }
        do {
            let (data, response) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

// MARK: - aiService test suite

final class aiServiceTests: XCTestCase {

    // MARK: setUp / tearDown

    override class func setUp() {
        super.setUp()
        // Register our protocol stub for all subsequent URLSession.shared requests.
        URLProtocol.registerClass(MockURLProtocol.self)
    }

    override class func tearDown() {
        URLProtocol.unregisterClass(MockURLProtocol.self)
        super.tearDown()
    }

    override func setUp() {
        super.setUp()
        // Reset shared state between tests.
        MockURLProtocol.requestHandler = nil
        MockURLProtocol.lastCapturedRequest = nil

        // Inject a non-empty (but invalid) API key via Keychain so aiService
        // passes its early-exit guard and reaches the network layer.
        KeychainService.save("CLAUDE_API_KEY", value: "test-invalid-key")
    }

    override func tearDown() {
        KeychainService.delete("CLAUDE_API_KEY")
        super.tearDown()
    }

    // MARK: - Test 1: network error produces a non-empty fallback string

    /// aiService.ask() must return a non-empty string when the network
    /// fails — it must never crash or return an empty string silently.
    func testAskReturnsStringOnNetworkError() async {
        // Arrange: stub that always throws a connection error.
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        let service = AIService()

        // Act
        let result = await service.ask(
            userMessage: "How many reps should I do?",
            conversationHistory: []
        )

        // Assert: result must be a non-empty string (the "Error: …" fallback).
        XCTAssertFalse(
            result.isEmpty,
            "ask() should return a non-empty fallback string on network error, got empty string."
        )
        XCTAssertTrue(
            result.lowercased().contains("error"),
            "Expected fallback to contain 'error' but got: '\(result)'"
        )
    }

    // MARK: - Test 2: conversation history is correctly structured in the request body

    /// The request body sent to the Anthropic API must include a "messages"
    /// array where each entry has "role" and "content" keys, and the new
    /// user message is appended after any existing history.
    func testConversationHistoryFormat() async {
        // Arrange: capture the outgoing request body; respond with a minimal
        // valid Anthropic payload so the parsing branch is exercised too.
        let expectedReply = "Keep going!"
        let validResponsePayload: [String: Any] = [
            "content": [
                ["type": "text", "text": expectedReply]
            ]
        ]
        let responseData = try! JSONSerialization.data(withJSONObject: validResponsePayload)

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (responseData, response)
        }

        let existingHistory: [[String: String]] = [
            ["role": "user",      "content": "I just finished my warm-up."],
            ["role": "assistant", "content": "Great, let's get started!"]
        ]
        let newUserMessage = "Starting my first set of squats."

        let service = AIService()

        // Act
        let result = await service.ask(
            userMessage: newUserMessage,
            conversationHistory: existingHistory
        )

        // Assert — parse the body that was actually sent.
        guard let sentRequest = MockURLProtocol.lastCapturedRequest else {
            XCTFail("No request was intercepted — MockURLProtocol may not be registered.")
            return
        }

        guard let bodyData = sentRequest.httpBody else {
            XCTFail("Request had no HTTP body.")
            return
        }

        guard
            let json = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any],
            let messages = json["messages"] as? [[String: Any]]
        else {
            XCTFail("Could not decode request body as JSON with a 'messages' array.")
            return
        }

        // The messages array must contain the history + the new user message.
        let expectedCount = existingHistory.count + 1
        XCTAssertEqual(
            messages.count, expectedCount,
            "Expected \(expectedCount) messages (history + new), got \(messages.count)."
        )

        // Every message must have "role" and "content" string keys.
        for (index, message) in messages.enumerated() {
            XCTAssertNotNil(
                message["role"] as? String,
                "messages[\(index)] is missing a String 'role' key."
            )
            XCTAssertNotNil(
                message["content"] as? String,
                "messages[\(index)] is missing a String 'content' key."
            )
        }

        // The last message must be the new user turn.
        let lastMessage = messages.last!
        XCTAssertEqual(lastMessage["role"] as? String, "user")
        XCTAssertEqual(lastMessage["content"] as? String, newUserMessage)

        // The prior messages must preserve existing history order and values.
        XCTAssertEqual(messages[0]["role"] as? String, "user")
        XCTAssertEqual(messages[0]["content"] as? String, existingHistory[0]["content"])
        XCTAssertEqual(messages[1]["role"] as? String, "assistant")
        XCTAssertEqual(messages[1]["content"] as? String, existingHistory[1]["content"])

        // Bonus: verify the reply was correctly parsed from the mocked response.
        XCTAssertEqual(
            result, expectedReply,
            "Expected parsed reply '\(expectedReply)', got '\(result)'."
        )
    }
}
