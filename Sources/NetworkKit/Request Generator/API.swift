//
//  API.swift
//
//

import Foundation

/// An API. This will be used as our baseURL when building URLRequests.
public protocol API {
    var baseURL: URL { get }
}
