//
//  Movable.swift
//  
//
//  Created by Markus Kasperczyk on 14.05.22.
//

public protocol Movable where Adjustment : DiffArithmetic {
    associatedtype Adjustment
    mutating func move(_ adjustment: Adjustment)
    static func +(lhs: Self, rhs: Adjustment) -> Self
    static func +=(lhs: inout Self, rhs: Adjustment)
    static func -(lhs: Self, rhs: Adjustment) -> Self
    static func -=(lhs: inout Self, rhs: Adjustment)
}

public extension Movable {
    
    static func +=(lhs: inout Self, rhs: Adjustment) {
        lhs.move(rhs)
    }
    
    static func +(lhs: Self, rhs: Adjustment) -> Self {
        var lhs = lhs
        lhs += rhs
        return lhs
    }
    
    static func -=(lhs: inout Self, rhs: Adjustment) {
        lhs.move(-rhs)
    }
    
    static func -(lhs: Self, rhs: Adjustment) -> Self {
        var lhs = lhs
        lhs -= rhs
        return lhs
    }
    
}

public protocol DiffArithmetic : Movable where Scalar.Scalar == Scalar, Adjustment == Self {
    associatedtype Scalar : DiffArithmetic
    static func *(lhs: Scalar, rhs: Self) -> Self
    static prefix func -(arg: Self) -> Self
}

extension Float : DiffArithmetic, Movable {
    public typealias Scalar = Float
    public mutating func move(_ adjustment: Self) {
        self += adjustment
    }
}
extension Double : DiffArithmetic, Movable {
    public typealias Scalar = Double
    public mutating func move(_ adjustment: Self) {
        self += adjustment
    }
}
extension Int : DiffArithmetic, Movable {
    public typealias Scalar = Int
    public mutating func move(_ adjustment: Self) {
        self += adjustment
    }
}
