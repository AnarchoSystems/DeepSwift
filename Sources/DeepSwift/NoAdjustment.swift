//
//  NoAdjustment.swift
//  
//
//  Created by Markus Kasperczyk on 16.05.22.
//


public struct NoAdjustment : DiffArithmetic {
    
    @inlinable
    public init() {}
    
    @inlinable
    public static prefix func -(arg: Self) -> Self {
        arg
    }
    
    @inlinable
    public static func * (lhs: Double, rhs: NoAdjustment) -> NoAdjustment {
        rhs
    }
    
}

public extension Movable {
    
    func move(_ adjustment: NoAdjustment) {}
    
}
