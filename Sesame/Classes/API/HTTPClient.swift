//
//  HTTPClient.swift
//  Sesame
//
//  Created by Akash Desai on 2/21/18.
//

import Foundation

internal class HTTPClient: NSObject {

    private let session: URLSessionProtocol

    public init(session: URLSessionProtocol = URLSession.shared) {
        self.session = session
    }

    func post(url: URL, jsonObject: [String: Any], timeout: TimeInterval = 3.0, completion: @escaping ([String: Any]?) -> Void) -> URLSessionDataTaskProtocol {

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.timeoutInterval = timeout
        do {
            let httpBody = try JSONSerialization.data(withJSONObject: jsonObject)
            request.httpBody = httpBody
            Logger.info("Sending request to <\(url.absoluteString)>")
            if Logger.level == .verbose {
                Logger.verbose("with payload:\n<\(String(data: httpBody, encoding: .utf8) as AnyObject)>...")
            }
        } catch {
            Logger.error("Canceled request to \(url.absoluteString) for non-JSON request <\(jsonObject as AnyObject)>")
        }
        return session.send(request: request) { responseData, responseURL, error in
            Logger.info("Received response from <\(request.url?.absoluteString ?? "url:nil")>")
            if Logger.level == .verbose {
                if let responseData = responseData {
                    Logger.verbose("with response body <\(String(data: responseData, encoding: .utf8) ?? "nil")>")
                } else {
                    Logger.verbose("Received no response data from <\(request.url?.absoluteString ?? "url:nil")>")
                }
            }
            let response = self.convertResponseToJSON(url, responseData, responseURL, error)
            completion(response)
        }
    }

    fileprivate func convertResponseToJSON(_ url: URL, _ responseData: Data?, _ responseURL: URLResponse?, _ error: Error?) -> [String: Any]? {
        guard responseURL != nil else {
            Logger.error("\(url.absoluteString) call got invalid response with error:<\(error as AnyObject)>")
            return nil
        }

        guard let response = responseData else {
            Logger.verbose("\(url.absoluteString) call got no response data")
            return nil
        }

        if response.isEmpty {
            Logger.verbose("\(url.absoluteString) called and got empty response")
            return nil
        } else if let jsonResponse = try? JSONSerialization.jsonObject(with: response) as? [String: AnyObject] {
            Logger.verbose("\(url.absoluteString) call got json response")
            return jsonResponse
        } else {
            let dataString = responseData.flatMap({ NSString(data: $0, encoding: String.Encoding.utf8.rawValue) }) ?? ""
            Logger.error("\(url.absoluteString) call got invalid response\n\t<\(dataString)>")
            return nil
        }
    }
}

protocol URLSessionProtocol {
    func send(request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol
}

extension URLSession: URLSessionProtocol {
    func send(request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol {
        return dataTask(with: request, completionHandler: completionHandler)
    }
}

protocol URLSessionDataTaskProtocol {
    func start()
}

extension URLSessionDataTask: URLSessionDataTaskProtocol {
    func start() {
        resume()
    }
}
