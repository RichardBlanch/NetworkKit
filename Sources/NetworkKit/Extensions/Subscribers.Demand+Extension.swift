//
//  Subscribers.Demand+Extension.swift
//  HackerNews
//
//  Created by Richard Blanchard on 10/8/19.
//  Copyright © 2019 Richard Blanchard. All rights reserved.
//

import Combine
import Foundation

extension Subscribers.Demand {
    var value: Int? {
        if let max = self.max {
            return max
        }
        
        switch self {
        case .none: return 0
        case .unlimited: return Int.max
        default: return nil
        }
    }
}
