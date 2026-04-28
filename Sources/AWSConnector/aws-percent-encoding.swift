import Primitives

internal func awsPercentEncode(
    _ value: String
) -> String {
    PercentEncodingProfiles.rfc3986Unreserved.encode(
        value
    )
}
