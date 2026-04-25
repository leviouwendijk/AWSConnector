import Foundation
import Primitives

enum BedrockFlowEventStream {
    static func stream(
        _ messages: Data...
    ) -> Data {
        var data = Data()

        for message in messages {
            data.append(
                message
            )
        }

        return data
    }

    static func event(
        _ eventType: String,
        payload: [String: JSONValue]
    ) throws -> Data {
        try message(
            headers: [
                ":message-type": "event",
                ":event-type": eventType,
                ":content-type": "application/json"
            ],
            payload: JSONEncoder().encode(
                JSONValue.object(payload)
            )
        )
    }

    static func exception(
        _ exceptionType: String,
        payload: [String: JSONValue]
    ) throws -> Data {
        try message(
            headers: [
                ":message-type": "exception",
                ":exception-type": exceptionType,
                ":content-type": "application/json"
            ],
            payload: JSONEncoder().encode(
                JSONValue.object(payload)
            )
        )
    }
}

private extension BedrockFlowEventStream {
    static func message(
        headers: [String: String],
        payload: Data
    ) throws -> Data {
        let headerData = try headers
            .sorted {
                $0.key < $1.key
            }
            .reduce(
                into: Data()
            ) { data, header in
                try data.appendHeader(
                    name: header.key,
                    value: header.value
                )
            }

        let total = UInt32(
            12 + headerData.count + payload.count + 4
        )
        let headersLength = UInt32(
            headerData.count
        )

        var data = Data()
        data.appendUInt32BE(
            total
        )
        data.appendUInt32BE(
            headersLength
        )
        data.appendUInt32BE(
            0
        )
        data.append(
            headerData
        )
        data.append(
            payload
        )
        data.appendUInt32BE(
            0
        )

        return data
    }
}

private extension Data {
    mutating func appendHeader(
        name: String,
        value: String
    ) throws {
        let nameBytes = [UInt8](
            name.utf8
        )
        let valueBytes = [UInt8](
            value.utf8
        )

        guard nameBytes.count <= Int(UInt8.max) else {
            throw BedrockFlowEventStreamError.headerNameTooLong(
                name
            )
        }

        guard valueBytes.count <= Int(UInt16.max) else {
            throw BedrockFlowEventStreamError.headerValueTooLong(
                name
            )
        }

        append(
            contentsOf: [
                UInt8(nameBytes.count)
            ]
        )
        append(
            contentsOf: nameBytes
        )

        append(
            contentsOf: [
                7
            ]
        )
        appendUInt16BE(
            UInt16(valueBytes.count)
        )
        append(
            contentsOf: valueBytes
        )
    }

    mutating func appendUInt16BE(
        _ value: UInt16
    ) {
        append(
            contentsOf: [
                UInt8((value >> 8) & 0xff),
                UInt8(value & 0xff)
            ]
        )
    }

    mutating func appendUInt32BE(
        _ value: UInt32
    ) {
        append(
            contentsOf: [
                UInt8((value >> 24) & 0xff),
                UInt8((value >> 16) & 0xff),
                UInt8((value >> 8) & 0xff),
                UInt8(value & 0xff)
            ]
        )
    }
}

enum BedrockFlowEventStreamError: Error {
    case headerNameTooLong(String)
    case headerValueTooLong(String)
}
