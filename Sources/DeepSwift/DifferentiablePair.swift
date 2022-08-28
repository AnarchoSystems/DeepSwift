//
//  DifferentiablePair.swift
//  
//
//  Created by Markus Kasperczyk on 16.05.22.
//


public struct DifferentiablePair<S : DiffArithmetic, T: DiffArithmetic> : DiffArithmetic {
    
    public var first : S
    public var second : T
    
    public init(_ first: S, _ second: T) {(self.first, self.second) = (first, second)}
    
    public mutating func move(_ adjustment: DifferentiablePair<S, T>) {
        first.move(adjustment.first)
        second.move(adjustment.second)
    }
    
    public static func * (lhs: Double, rhs: DifferentiablePair<S, T>) -> DifferentiablePair<S, T> {
        DifferentiablePair(lhs * rhs.first, lhs * rhs.second)
    }
    public static prefix func - (arg: DifferentiablePair<S, T>) -> DifferentiablePair<S, T> {
        DifferentiablePair(-arg.first, -arg.second)
    }
    
}
