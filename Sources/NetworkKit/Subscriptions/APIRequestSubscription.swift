//
//  APIRequestSubscription.swift
//  HackerNews
//
//  Created by Richard Blanchard on 10/8/19.
//  Copyright © 2019 Richard Blanchard. All rights reserved.
//

import Combine
import Foundation

final  class APIRequestSubscription<S: Subscriber, Request: APIRequest> where S.Input == Result<Request.Output, APIError>, S.Failure == Never {
    private var subscriber: S?
    private let request: Request
    private let frequency: PollingFrequency
    private let decoder: JSONDecoder
    private unowned let urlSession: URLSession
    private let doesBreakpointOnError: Bool

    private let dispatchQueue = DispatchQueue(label: "com.APIRequestSubscription")
    private var _count: Int = Int.max
    private var count: Int {
        get {
            return dispatchQueue.sync { return _count }
        }
        
        set {
            dispatchQueue.sync { _count = newValue }
        }
    }
    
    private var subscriptions: Set<AnyCancellable> = []

    init (subscriber: S,
         request: Request,
         frequency: PollingFrequency,
         decoder: JSONDecoder,
         urlSession: URLSession,
         doesBreakpointOnError: Bool
    ) throws {
        self.subscriber = subscriber
        self.request = request
        self.frequency = frequency
        self.decoder = decoder
        self.urlSession = urlSession
        self.doesBreakpointOnError = doesBreakpointOnError
        
        do {
            try setUpSubscription()
        } catch {
            throw error
        }
    }
    
    private func setUpSubscription() throws {
        let publisher: AnyPublisher<Result<Request.Output, APIError>, Never>
        let isOneTimePublisher: Bool
        
        switch frequency {
        case .once:
            publisher = try oneTimePublisher()
            isOneTimePublisher = true
        case .continuous(let interval):
            publisher = try continuousPollingPublisher(at: interval)
            isOneTimePublisher = false
        }
        
        
        publisher.sink(receiveCompletion: { [weak self] (completion) in
            switch completion {
            case .failure(let error):
                // NEED TO CHECK ERROR HERE...
                if let newDemand = self?.subscriber?.receive(.failure(.generic(error))) {
                    self?.count = newDemand.value ?? Int.max
                }
            default: break
            }
        }, receiveValue: { [weak self, isOneTimePublisher] value in
            do {
                _ = try value.get()
            } catch {
                let apiError = error.mapToAPIError()
                let url = try! self!.request.makeRequest().url
                apiError.printError(at: url)
            }
            // NEED TO CHECK ERROR HERE...
            if let newDemand = self?.subscriber?.receive(value) {
                self?.count = newDemand.value ?? Int.max
            }
            
            if isOneTimePublisher {
                self?.finish(with: .finished)
            }
        })
        .store(in: &subscriptions)
    }
    
    private func finish(with completion: Subscribers.Completion<Never>) {
        subscriber?.receive(completion: completion)
    }
    
    private func oneTimePublisher() throws -> AnyPublisher<Result<Request.Output, APIError>, Never> {
        let urlRequest = try request.makeRequest()
        return urlSession.decodableTypePublisher(for: urlRequest, doesBreakpointOnError: doesBreakpointOnError).eraseToAnyPublisher()
    }
    
    private func continuousPollingPublisher(at interval: TimeInterval) throws -> AnyPublisher<Result<Request.Output, APIError>, Never> {
        let urlRequest = try request.makeRequest()
        
        // Will create our initial fetch
        let decodableTypePublisher: AnyPublisher<Result<Request.Output, APIError>, Never> = urlSession.decodableTypePublisher(for: urlRequest, doesBreakpointOnError: doesBreakpointOnError)
            .eraseToAnyPublisher()
        
        // Will fetch request every X seconds where X == interval
        let pollingPublisher = Timer.publish(every: interval, on: RunLoop.main, in: .common)
        .autoconnect()
            .flatMap { [weak self] _ -> AnyPublisher<Result<Request.Output, APIError>, Never> in
                guard let self = self else { return APIError.unknown.convertToResultPublisher().eraseToAnyPublisher() }
    
                return self.urlSession.decodableTypePublisher(for: urlRequest, doesBreakpointOnError: self.doesBreakpointOnError)
        }
        .eraseToAnyPublisher()
        
        return decodableTypePublisher.merge(with: pollingPublisher).eraseToAnyPublisher()
    }

    func request(_ demand: Subscribers.Demand) {
        if let value = demand.value {
            count = value
        }
    }

    func cancel() {
        subscriber = nil
    }
    
    private func finish(with input: S.Input) {
        _ = subscriber?.receive(input)
    }
}

extension APIRequestSubscription: Subscription, Cancellable {}
