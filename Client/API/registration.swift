import Foundation
import UniformTypeIdentifiers
import MessengerInterface

extension API {
    func registerUser(registrationToken token: RegistrationToken, username: String, avatar: FileForUpload<Data>?) async throws -> RegistrationResponse {
        var parts: [MultipartPart] = [
            .field(name: "registrationToken", value: token.rawValue),
            .field(name: "username", value: username),
        ]
        if let avatar = avatar {
            parts.append(.file(name: "avatar", bytes: avatar.bytes, contentType: avatar.contentType))
        }
        
        let (requestBody, contentTypeHeader) = multipartEncode(parts)
        
        var request = URLRequest(url: endpoint.appending(component: "registration"))
        request.httpMethod = "POST"
        request.httpBody = requestBody
        request.setValue(contentTypeHeader, forHTTPHeaderField: "Content-Type")
        
        let (body, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ServerRequestError.nonHTTPResponse(got: Mirror(reflecting: response).subjectType)
        }
        API.logger.info("registration status code -- \(httpResponse.statusCode)")
        guard httpResponse.statusCode != 400 else {
            let errorResponse = try JSONDecoder().decode(ErrorResponse<RegistrationResponse.ErrorKind>.self, from: body)
            return .invalidToken(reason: errorResponse.reason)
        }
        guard httpResponse.statusCode == 200 else {
            throw ServerRequestError(fromResponse: httpResponse, data: body)
        }
        let decoded = try JSONDecoder().decode(RegistrationResponse.Success.self, from: body)
        return .success(decoded)
    }
}

// MARK: Multipart encoding bits

extension UTType {
    var mimeType: MIMEType? {
        self.preferredMIMEType.map { MIMEType(rawValue: $0) }
    }
}

enum MultipartPart {
    case field(name: String, value: String)
    case file(name: String, bytes: Data, contentType: MIMEType, filename: String? = nil)
}

private func multipartEncode(_ values: [MultipartPart]) -> (body: Data, contentTypeHeader: String) {
    assert(!values.isEmpty)
    
    let boundary = UUID().uuidString
    
    let header = "multipart/form-data; boundary=\(boundary)"
    var data = Data()
    
    for part in values {
        switch part {
        case .field(name: let name, value: let value):
            data.append(contentsOf: "--\(boundary)\r\n".utf8)
            data.append(contentsOf: "Content-Disposition: form-data; name=\(String(reflecting: name))\r\n\r\n".utf8)
            data.append(contentsOf: value.utf8)
        case .file(name: let name, bytes: let bytes, contentType: let contentType, filename: let filename):
            data.append(contentsOf: "\r\n--\(boundary)\r\n".utf8)
            data.append(contentsOf: "Content-Disposition: form-data; name=\(String(reflecting: name))".utf8)
            if let filename = filename {
                data.append(contentsOf: "; filename=\(String(reflecting: filename))".utf8)
            }
            data.append(contentsOf: "\r\n".utf8)
            data.append(contentsOf: "Content-Type: \(contentType)\r\n\r\n".utf8)
            data.append(bytes)
        }
    }
    
    data.append(contentsOf: "\r\n--\(boundary)\r\n".utf8)
    
    return (data, header)
}
