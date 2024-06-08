import Foundation

// MARK: Login

public struct LoginRequest: Codable {
    public var code: String
    public var token: OTPToken

    public init(code: String, token: OTPToken) {
        self.code = code
        self.token = token
    }
}

public enum LoginResponse {
    case invalid(reason: String = "OTP code isn't the one that was sent.")
    case expired(reason: String = "OTP token has expired.")
    case success(Success)

    public enum Success: Equatable, Hashable, Codable {
        case registrationRequired(registrationToken: RegistrationToken, phone: PhoneNumber)
        case existingLogin(sessionToken: SessionToken, userID: UserID)
    }

    public enum ErrorKind: String, RawRepresentable, Codable {
        case invalid, expired
    }
}

// MARK: Request OTP

public struct OTPRequest: Codable {
    public let phone: String

    public init(phone: PhoneNumber) {
        self.phone = phone.rawValue
    }
}

public enum OTPResponse {
    case invalidPhoneNumber(
        reason: String = "Provided phone number doesn't follow the expected format.")
    case success(Success)

    public enum ErrorKind: String, RawRepresentable, Codable {
        case invalidPhoneNumber
    }

    public struct Success: Codable, Hashable {
        public var otpToken: OTPToken

        public init(otpToken: OTPToken) {
            self.otpToken = otpToken
        }
    }
}

// MARK: Register user

//public typealias RegistrationResponse = Result<RegistrationSuccess, RegistrationFailure>

public enum RegistrationResponse {
    case invalidToken(reason: String = "Registration token is invalid or has expired")
    case success(Success)

    public enum ErrorKind: String, RawRepresentable, Codable {
        case invalidToken
    }

    public struct Success: Codable {
        public var sessionToken: SessionToken
        public var userID: UserID

        public init(sessionToken: SessionToken, userID: UserID) {
            self.sessionToken = sessionToken
            self.userID = userID
        }
    }
}

public struct RegistrationRequest<BodyRepr: Codable>: Codable {
    public var registrationToken: RegistrationToken
    public var username: String
    public var avatar: FileForUpload<BodyRepr>?
}

public struct FileForUpload<BodyRepr: Codable>: Codable {
    public var bytes: BodyRepr
    public var contentType: MIMEType

    public init(bytes: BodyRepr, contentType: MIMEType) {
        self.bytes = bytes
        self.contentType = contentType
    }
}

public struct MIMEType: StringNewtype {
    public typealias StringLiteralType = String
    public var rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

// MARK: Fetch private chats

public struct User: Equatable, Identifiable, Codable {
    public var id: UserID
    public var username: String

    public init(id: UserID, username: String) {
        self.id = id
        self.username = username
    }
}

public enum FetchPrivateChatsResponse {
    case unauthorized
    case success([User])
}

// MARK: Find user by phone

public enum FindUserResponse {
    case unauthorized
    case absent
    case invalidPhoneNumber(
        reason: String = "Provided phone number doesn't follow the expected format.")
    case found(User)

    public enum ErrorKind: String, Codable {
        case unauthorized, absent, invalidPhoneNumber
    }
}

// MARK: Fetch avatar

public enum FetchAvatarResponse {
    case unauthorized
    case notFound
    case success(Data, contentType: MIMEType)

    public enum ErrorKind: String, Codable {
        case unauthorized, notFound
    }
}

// MARK: Send message

public struct Message: Codable {
    public var id: MessageID
    public var sentAt: Date
    public var author: UserID

    public init(id: MessageID, sentAt: Date, author: UserID) {
        self.id = id
        self.sentAt = sentAt
        self.author = author
    }
}

public enum NewMessageResponse {
    case unauthorized
    case invalidRecipient(reason: String)
    case success(Message)

    public enum ErrorKind: String, Codable {
        case unauthorized, invalidRecipient
    }
}
