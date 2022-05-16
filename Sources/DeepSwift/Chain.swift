//
//  Chain.swift
//  
//
//  Created by Markus Kasperczyk on 14.05.22.
//

infix operator |> : AssignmentPrecedence

public extension Layer {
    
    func chaining<Other : Layer>(_ next: Other) -> ChainedLayers<Self, Other> {
        ChainedLayers(first: self, second: next)
    }
    
    @inlinable
    static func |><Other : Layer>(lhs: Self, rhs: Other) -> ChainedLayers<Self, Other> {
        lhs.chaining(rhs)
    }
    
}

public struct UnsafeOptional<T : DiffArithmetic> : DiffArithmetic {
   
    public typealias Scalar = T.Scalar
    
    // deliberately internal
    
    @usableFromInline
    var wrapped : T?
    
    // deliberately no public initializer
    
    @usableFromInline
    init() {self.wrapped = nil}
    
    @usableFromInline
    init(wrapped: T?) {self.wrapped = wrapped}
    
    @inlinable
    public mutating func move(_ adjustment: UnsafeOptional<T>) {
        wrapped!.move(adjustment.wrapped.unsafelyUnwrapped)
    }
    
    @inlinable
    public static func * (lhs: T.Scalar, rhs: UnsafeOptional<T>) -> UnsafeOptional<T> {
        UnsafeOptional(wrapped: lhs * rhs.wrapped.unsafelyUnwrapped)
    }
    
    @inlinable
    public static prefix func - (arg: UnsafeOptional<T>) -> UnsafeOptional<T> {
        UnsafeOptional(wrapped: -arg.wrapped.unsafelyUnwrapped)
    }
    
}

public struct ChainedLayers<L1 : Layer, L2: Layer> : Layer where L1.Output == L2.Input, L1.Adjustment.Scalar == L2.Adjustment.Scalar {
    
    public typealias AuxiliaryData = (L1.Output?, L2.AuxiliaryData?, L1.AuxiliaryData?)
    public typealias Adjustment = DifferentiablePair<UnsafeOptional<L1.Adjustment>, UnsafeOptional<L2.Adjustment>>
    
    @usableFromInline
    var first : L1
    @usableFromInline
    var second : L2
    
    @usableFromInline
    init(first: L1, second: L2) {self.first = first; self.second = second}
    
    @inlinable
    public func apply(_ input: L1.Input) -> L2.Output {
        second.apply(first.apply(input))
    }
    
    @inlinable
    public func inspectableApply(_ input: L1.Input) -> (result: L2.Output, auxiliaryData: AuxiliaryData) {
        var aux : AuxiliaryData = (nil, nil, nil)
        let r2 : L2.Output
        (aux.0, aux.2) = first.inspectableApply(input)
        (r2, aux.1) = second.inspectableApply(aux.0.unsafelyUnwrapped)
        return (r2, aux)
    }
    
    @inlinable
    public func auxData(at input: L1.Input) -> (L1.AuxiliaryData, L1.Output, L2.AuxiliaryData) {
        let (r, dr) = first.inspectableApply(input)
        return (dr, r, second.auxData(at: r))
    }
    
    @inlinable
    public func adjustment(input: L1.Input, auxiliaryData: AuxiliaryData, gradient: L2.Output.Adjustment) -> (adjustment: Adjustment, backprop: L1.Input.Adjustment) {
        var adj : Adjustment = DifferentiablePair(UnsafeOptional(), UnsafeOptional())
        let b2 : L2.Input.Adjustment
        let b1 : L1.Input.Adjustment
        (adj.second.wrapped, b2) = second.adjustment(input: auxiliaryData.0.unsafelyUnwrapped, auxiliaryData: auxiliaryData.1.unsafelyUnwrapped, gradient: gradient)
        (adj.first.wrapped, b1) = first.adjustment(input: input, auxiliaryData: auxiliaryData.2.unsafelyUnwrapped, gradient: b2)
        return (adj, b1)
    }
    
    @inlinable
    public func backprop(input: L1.Input, auxiliaryData: (L1.Output?, L2.AuxiliaryData?, L1.AuxiliaryData?), gradient: L2.Output.Adjustment) -> L1.Input.Adjustment {
        first.backprop(input: input,
                       auxiliaryData: auxiliaryData.2.unsafelyUnwrapped,
                       gradient: second.backprop(input: auxiliaryData.0.unsafelyUnwrapped,
                                                 auxiliaryData: auxiliaryData.1.unsafelyUnwrapped,
                                                 gradient: gradient))
    }
    
    @inlinable
    public mutating func move(_ adjustment: Adjustment) {
        first.move(adjustment.first.wrapped.unsafelyUnwrapped)
        second.move(adjustment.second.wrapped.unsafelyUnwrapped)
    }
    
}
