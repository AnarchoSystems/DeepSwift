//
//  DifferentiableArray.swift
//  
//
//  Created by Markus Kasperczyk on 16.05.22.
//

public struct DifferentiableArray<Element : Movable> : Movable {
    public typealias Adjustment = DifferentiableArray<Element.Adjustment>
    
    public var content : [Element]
    
    @inlinable
    public init(_ content: [Element]) {self.content = content}
    
    @inlinable
    public mutating func move(_ adjustment: DifferentiableArray<Element.Adjustment>) {
        for idx in content.indices {
            content[idx].move(adjustment.content[idx])
        }
    }
    
}

extension DifferentiableArray : DiffArithmetic where Element : DiffArithmetic {
    
    public typealias Scalar = Element.Scalar
    
    public static prefix func - (arg: DifferentiableArray<Element>) -> DifferentiableArray<Element> {
        DifferentiableArray(arg.content.map(-))
    }
    
    public static func * (lhs: Element.Scalar, rhs: DifferentiableArray<Element>) -> DifferentiableArray<Element> {
        DifferentiableArray(rhs.content.map{lhs * $0})
    }
    
}
