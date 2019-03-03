//
//  Then.swift
//  InfiniteKit
//
//  Created by duan on 2019/02/09.
//

import Foundation


protocol Then {}

extension Then where Self: AnyObject {

    func then(_ block: (Self) throws -> Void) rethrows -> Self {
        try block(self)
        return self
    }

}

extension NSObject: Then {}
