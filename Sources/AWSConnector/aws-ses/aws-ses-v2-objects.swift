import Foundation
import plate

public struct SESv2Destination: Encodable {
    public let ToAddresses: [String]?
    public let CcAddresses: [String]?
    public let BccAddresses: [String]?

    public init(
        ToAddresses: [String]? = nil,
        CcAddresses: [String]? = nil,
        BccAddresses: [String]? = nil
    ) {
        self.ToAddresses = ToAddresses
        self.CcAddresses = CcAddresses
        self.BccAddresses = BccAddresses
    }
}

public struct SESv2BodyPart: Encodable {
    public let Charset: String
    public let Data: String

    public init(
        Charset: String = "UTF-8",
        Data: String
    ) {
        self.Charset = Charset
        self.Data = Data
    }
}

public struct SESv2Body: Encodable {
    public let Html: SESv2BodyPart?
    public let Text: SESv2BodyPart?

    public init(
        Html: SESv2BodyPart? = nil,
        Text: SESv2BodyPart? = nil
    ) {
        self.Html = Html
        self.Text = Text
    }
}

public struct SESv2Subject: Encodable {
    public let Charset: String
    public let Data: String

    public init(
        Charset: String = "UTF-8",
        Data: String
    ) {
        self.Charset = Charset
        self.Data = Data
    }
}

public struct SESv2SimpleContent: Encodable {
    public let Subject: SESv2Subject
    public let Body: SESv2Body

    public init(
        Subject: SESv2Subject,
        Body: SESv2Body
    ) {
        self.Subject = Subject
        self.Body = Body
    }
    // Attachments + Headers omitted for now
}

public struct SESv2Content: Encodable {
    public let Simple: SESv2SimpleContent

    public init(Simple: SESv2SimpleContent) {
        self.Simple = Simple
    }
}

public struct SESv2SendEmailRequest: Encodable {
    public let FromEmailAddress: String
    public let Destination: SESv2Destination
    public let ReplyToAddresses: [String]?
    public let Content: SESv2Content

    public init(
        FromEmailAddress: String,
        Destination: SESv2Destination,
        ReplyToAddresses: [String]? = nil,
        Content: SESv2Content
    ) {
        self.FromEmailAddress = FromEmailAddress
        self.Destination = Destination
        self.ReplyToAddresses = ReplyToAddresses
        self.Content = Content
    }
}

public struct SESv2SendEmailResponse: Decodable {
    public let MessageId: String

    public init(MessageId: String) {
        self.MessageId = MessageId
    }
}
