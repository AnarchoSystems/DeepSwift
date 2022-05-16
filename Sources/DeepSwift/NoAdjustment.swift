//
//  NoAdjustment.swift
//  
//
//  Created by Markus Kasperczyk on 16.05.22.
//


public struct NoAdjustment<Scalar : DiffArithmetic> : DiffArithmetic where Scalar.Scalar == Scalar {
    
    @inlinable
    public init() {}
    
    @inlinable
    public static prefix func -(arg: Self) -> Self {
        arg
    }
    
    @inlinable
    public static func * (lhs: Scalar, rhs: NoAdjustment<Scalar>) -> NoAdjustment<Scalar> {
        rhs
    }
    
}

public extension Movable {
    
    func move<Scalar : DiffArithmetic>(_ adjustment: NoAdjustment<Scalar>) {}
    
}
