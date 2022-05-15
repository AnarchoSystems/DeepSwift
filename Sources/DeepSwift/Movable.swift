//
//  Movable.swift
//  
//
//  Created by Markus Kasperczyk on 14.05.22.
//

public protocol Movable {
    associatedtype Adjustment
    mutating func move(_ adjustment: Adjustment)
}


public extension Movable where Adjustment == Void {
    
    func move(_ adjustment: Adjustment) {}
    
}
