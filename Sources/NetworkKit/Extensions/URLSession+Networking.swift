//
//  MockURLSession.swift
//
//

import Combine
import Foundation

extension URLSession {
    func publisher<Request: APIRequest>(for request: Request, frequency: PollingFrequency = .once, decoder: JSONDecoder) -> APIRequestPublisher<Request> {
        APIRequestPublisher(request: request, frequency: frequency, decoder: decoder, urlSession: self)
    }
    
    func decodableTypePublisher<T: Decodable>(for urlRequest: URLRequest, decoder: JSONDecoder = JSONDecoder()) -> AnyPublisher<Result<T, APIError>, Never> {
        dataTaskPublisher(for: urlRequest)
            .map { $0.data }
            .decode(type: T.self, decoder: decoder)
            .map { Result.success($0) }
            .catch { return $0.convertToAPIErrorPublisher() }
            .eraseToAnyPublisher()
    }

    func decodableTypePublisher<T: Decodable>(for url: URL) -> AnyPublisher<Result<T, APIError>, Never> {
        decodableTypePublisher(for: URLRequest(url: url))
    }
}
