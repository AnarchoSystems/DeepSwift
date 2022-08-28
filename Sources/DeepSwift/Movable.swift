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

public protocol DiffArithmetic : Movable where Adjustment == Self {
    static func *(lhs: Double, rhs: Self) -> Self
    static prefix func -(arg: Self) -> Self
}

extension Float : DiffArithmetic, Movable {
    public static func * (lhs: Double, rhs: Float) -> Float {
        Float(lhs * Double(rhs))
    }
    public mutating func move(_ adjustment: Self) {
        self += adjustment
    }
}
extension Double : DiffArithmetic, Movable {
    public mutating func move(_ adjustment: Self) {
        self += adjustment
    }
}
extension Int : DiffArithmetic, Movable {
    public static func * (lhs: Double, rhs: Int) -> Int {
        Int(lhs * Double(rhs))
    }
    public mutating func move(_ adjustment: Self) {
        self += adjustment
    }
}
