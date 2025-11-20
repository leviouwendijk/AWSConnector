import Foundation

public struct SESv2Client: Sendable {
    public let region: String
    public let credentials: AWSCredentials
    public let host: String
    public let session: URLSession

    public init(
        region: String,
        credentials: AWSCredentials,
        host: String? = nil,
        session: URLSession = .shared
    ) {
        self.region = region
        self.credentials = credentials
        self.host = host ?? "email.\(region).amazonaws.com"
        self.session = session
    }

    public func sendEmail(_ request: SESv2SendEmailRequest) async throws -> SESv2SendEmailResponse {
        let encoder = JSONEncoder()
        let bodyData = try encoder.encode(request)

        let urlString = "https://\(host)/v2/email/outbound-emails"
        guard let url = URL(string: urlString) else {
            throw SESV2Error.invalidURL(urlString)
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = bodyData
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(host, forHTTPHeaderField: "Host")

        let signer = AWSSigV4Signer(
            credentials: credentials,
            region: region,
            service: "ses"
        )

        try signer.sign(request: &urlRequest, body: bodyData)

        let (data, response) = try await session.data(for: urlRequest)

        guard let http = response as? HTTPURLResponse else {
            throw SESV2Error.invalidResponse
        }

        guard http.statusCode == 200 else {
            let bodySnippet = String(data: data, encoding: .utf8) ?? "<non-UTF8 body>"
            throw SESV2Error.httpError(status: http.statusCode, body: bodySnippet)
        }

        do {
            let decoded = try JSONDecoder().decode(SESv2SendEmailResponse.self, from: data)
            return decoded
        } catch {
            throw SESV2Error.decodeError(error.localizedDescription)
        }
    }
}
