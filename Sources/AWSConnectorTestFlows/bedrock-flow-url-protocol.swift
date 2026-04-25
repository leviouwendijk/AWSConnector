import Foundation

struct BedrockFlowHTTPResponse {
    var status: Int
    var headers: [String: String]
    var body: Data

    init(
        status: Int = 200,
        headers: [String: String] = [
            "Content-Type": "application/vnd.amazon.eventstream"
        ],
        body: Data
    ) {
        self.status = status
        self.headers = headers
        self.body = body
    }
}

struct BedrockFlowHTTPRequest {
    var request: URLRequest
    var body: Data
}

final class BedrockFlowURLProtocol: URLProtocol {
    private static let lock = NSLock()
    private nonisolated(unsafe) static var response: BedrockFlowHTTPResponse?
    private nonisolated(unsafe) static var requests: [BedrockFlowHTTPRequest] = []

    static func configure(
        response: BedrockFlowHTTPResponse
    ) {
        lock.lock()
        defer {
            lock.unlock()
        }

        self.response = response
        self.requests = []
    }

    static func recorded() -> [BedrockFlowHTTPRequest] {
        lock.lock()
        defer {
            lock.unlock()
        }

        return requests
    }

    override class func canInit(
        with request: URLRequest
    ) -> Bool {
        true
    }

    override class func canonicalRequest(
        for request: URLRequest
    ) -> URLRequest {
        request
    }

    override func startLoading() {
        Self.lock.lock()
        let response = Self.response
        Self.requests.append(
            .init(
                request: request,
                body: Self.body(
                    from: request
                )
            )
        )
        Self.lock.unlock()

        guard let response,
              let url = request.url,
              let http = HTTPURLResponse(
                url: url,
                statusCode: response.status,
                httpVersion: "HTTP/1.1",
                headerFields: response.headers
              )
        else {
            client?.urlProtocol(
                self,
                didFailWithError: URLError(.badServerResponse)
            )
            return
        }

        client?.urlProtocol(
            self,
            didReceive: http,
            cacheStoragePolicy: .notAllowed
        )
        client?.urlProtocol(
            self,
            didLoad: response.body
        )
        client?.urlProtocolDidFinishLoading(
            self
        )
    }

    override func stopLoading() {}
}

private extension BedrockFlowURLProtocol {
    static func body(
        from request: URLRequest
    ) -> Data {
        if let body = request.httpBody {
            return body
        }

        guard let stream = request.httpBodyStream else {
            return Data()
        }

        stream.open()
        defer {
            stream.close()
        }

        var data = Data()
        var buffer = [UInt8](
            repeating: 0,
            count: 4096
        )

        while stream.hasBytesAvailable {
            let count = stream.read(
                &buffer,
                maxLength: buffer.count
            )

            guard count > 0 else {
                break
            }

            data.append(
                contentsOf: buffer.prefix(count)
            )
        }

        return data
    }
}
