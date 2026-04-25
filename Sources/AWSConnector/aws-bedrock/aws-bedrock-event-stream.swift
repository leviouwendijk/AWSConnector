import Foundation

struct AWSEventStreamMessage: Sendable, Hashable {
    var headers: [String: AWSEventStreamHeaderValue]
    var payload: Data

    var eventType: String? {
        string(":event-type")
    }

    var messageType: String? {
        string(":message-type")
    }

    var exceptionType: String? {
        string(":exception-type")
    }

    func string(
        _ name: String
    ) -> String? {
        guard case .string(let value) = headers[name] else {
            return nil
        }

        return value
    }
}

enum AWSEventStreamHeaderValue: Sendable, Hashable {
    case bool(Bool)
    case byte(Int8)
    case int16(Int16)
    case int32(Int32)
    case int64(Int64)
    case bytes(Data)
    case string(String)
    case timestamp(Int64)
    case uuid(UUID)
}

struct AWSEventStreamDecoder: Sendable {
    private var buffer: [UInt8] = []

    init() {}

    mutating func append(
        _ byte: UInt8
    ) throws -> [AWSEventStreamMessage] {
        buffer.append(
            byte
        )

        return try drain()
    }
}

private extension AWSEventStreamDecoder {
    mutating func drain() throws -> [AWSEventStreamMessage] {
        var messages: [AWSEventStreamMessage] = []

        while true {
            guard buffer.count >= 12 else {
                return messages
            }

            let total = Int(
                uint32BE(
                    buffer,
                    at: 0
                )
            )
            let headersLength = Int(
                uint32BE(
                    buffer,
                    at: 4
                )
            )

            guard total >= 16 else {
                throw BedrockRuntimeError.eventstream(
                    "Invalid message length \(total)."
                )
            }

            guard headersLength <= total - 16 else {
                throw BedrockRuntimeError.eventstream(
                    "Invalid headers length \(headersLength)."
                )
            }

            guard buffer.count >= total else {
                return messages
            }

            let headersStart = 12
            let headersEnd = headersStart + headersLength
            let payloadEnd = total - 4

            messages.append(
                .init(
                    headers: try headers(
                        Array(
                            buffer[headersStart..<headersEnd]
                        )
                    ),
                    payload: Data(
                        buffer[headersEnd..<payloadEnd]
                    )
                )
            )

            buffer.removeFirst(
                total
            )
        }
    }

    func headers(
        _ bytes: [UInt8]
    ) throws -> [String: AWSEventStreamHeaderValue] {
        var result: [String: AWSEventStreamHeaderValue] = [:]
        var index = 0

        while index < bytes.count {
            let nameLength = Int(
                bytes[index]
            )
            index += 1

            try require(
                index + nameLength <= bytes.count,
                "Unexpected end of header name."
            )

            guard let name = String(
                bytes: bytes[index..<index + nameLength],
                encoding: .utf8
            ) else {
                throw BedrockRuntimeError.eventstream(
                    "Invalid UTF-8 header name."
                )
            }

            index += nameLength

            try require(
                index < bytes.count,
                "Unexpected end of header type."
            )

            let type = bytes[index]
            index += 1

            result[name] = try value(
                type: type,
                bytes: bytes,
                index: &index
            )
        }

        return result
    }

    func value(
        type: UInt8,
        bytes: [UInt8],
        index: inout Int
    ) throws -> AWSEventStreamHeaderValue {
        switch type {
        case 0:
            return .bool(true)

        case 1:
            return .bool(false)

        case 2:
            try require(
                index + 1 <= bytes.count,
                "Unexpected end of byte header."
            )

            let value = Int8(
                bitPattern: bytes[index]
            )
            index += 1

            return .byte(value)

        case 3:
            try require(
                index + 2 <= bytes.count,
                "Unexpected end of int16 header."
            )

            let value = Int16(
                bitPattern: uint16BE(
                    bytes,
                    at: index
                )
            )
            index += 2

            return .int16(value)

        case 4:
            try require(
                index + 4 <= bytes.count,
                "Unexpected end of int32 header."
            )

            let value = Int32(
                bitPattern: uint32BE(
                    bytes,
                    at: index
                )
            )
            index += 4

            return .int32(value)

        case 5:
            try require(
                index + 8 <= bytes.count,
                "Unexpected end of int64 header."
            )

            let value = Int64(
                bitPattern: uint64BE(
                    bytes,
                    at: index
                )
            )
            index += 8

            return .int64(value)

        case 6:
            return .bytes(
                try lengthPrefixedData(
                    bytes: bytes,
                    index: &index
                )
            )

        case 7:
            let data = try lengthPrefixedData(
                bytes: bytes,
                index: &index
            )

            guard let value = String(
                data: data,
                encoding: .utf8
            ) else {
                throw BedrockRuntimeError.eventstream(
                    "Invalid UTF-8 string header."
                )
            }

            return .string(value)

        case 8:
            try require(
                index + 8 <= bytes.count,
                "Unexpected end of timestamp header."
            )

            let value = Int64(
                bitPattern: uint64BE(
                    bytes,
                    at: index
                )
            )
            index += 8

            return .timestamp(value)

        case 9:
            try require(
                index + 16 <= bytes.count,
                "Unexpected end of UUID header."
            )

            let uuid = uuid(
                Data(
                    bytes[index..<index + 16]
                )
            )
            index += 16

            return .uuid(uuid)

        default:
            throw BedrockRuntimeError.eventstream(
                "Unsupported header type \(type)."
            )
        }
    }

    func lengthPrefixedData(
        bytes: [UInt8],
        index: inout Int
    ) throws -> Data {
        try require(
            index + 2 <= bytes.count,
            "Unexpected end of length-prefixed header."
        )

        let length = Int(
            uint16BE(
                bytes,
                at: index
            )
        )
        index += 2

        try require(
            index + length <= bytes.count,
            "Unexpected end of length-prefixed header value."
        )

        let data = Data(
            bytes[index..<index + length]
        )
        index += length

        return data
    }

    func require(
        _ condition: Bool,
        _ message: String
    ) throws {
        guard condition else {
            throw BedrockRuntimeError.eventstream(
                message
            )
        }
    }
}

private func uint16BE(
    _ bytes: [UInt8],
    at index: Int
) -> UInt16 {
    (UInt16(bytes[index]) << 8)
        | UInt16(bytes[index + 1])
}

private func uint32BE(
    _ bytes: [UInt8],
    at index: Int
) -> UInt32 {
    (UInt32(bytes[index]) << 24)
        | (UInt32(bytes[index + 1]) << 16)
        | (UInt32(bytes[index + 2]) << 8)
        | UInt32(bytes[index + 3])
}

private func uint64BE(
    _ bytes: [UInt8],
    at index: Int
) -> UInt64 {
    (UInt64(bytes[index]) << 56)
        | (UInt64(bytes[index + 1]) << 48)
        | (UInt64(bytes[index + 2]) << 40)
        | (UInt64(bytes[index + 3]) << 32)
        | (UInt64(bytes[index + 4]) << 24)
        | (UInt64(bytes[index + 5]) << 16)
        | (UInt64(bytes[index + 6]) << 8)
        | UInt64(bytes[index + 7])
}

private func uuid(
    _ data: Data
) -> UUID {
    let bytes = [UInt8](
        data
    )

    return UUID(
        uuid: (
            bytes[0],
            bytes[1],
            bytes[2],
            bytes[3],
            bytes[4],
            bytes[5],
            bytes[6],
            bytes[7],
            bytes[8],
            bytes[9],
            bytes[10],
            bytes[11],
            bytes[12],
            bytes[13],
            bytes[14],
            bytes[15]
        )
    )
}
