//
//  Frozen.swift
//  
//
//  Created by Markus Kasperczyk on 14.05.22.
//

public extension Layer {
    
    func frozen() -> Frozen<Self> {
        Frozen(wrapped: self)
    }
    
}

public struct Frozen<L : Layer> : Layer {
    
    public typealias Adjustment = NoAdjustment<L.Adjustment.Scalar>
    
    
    public typealias Input = L.Input
    public typealias Output = L.Output
    public typealias AuxiliaryData = L.AuxiliaryData
    
    @usableFromInline
    let wrapped : L
    
    @usableFromInline
    init(wrapped: L) {self.wrapped = wrapped}
    
    @inlinable
    public func apply(_ input: Input) -> Output {
        wrapped.apply(input)
    }
    
    @inlinable
    public func inspectableApply(_ input: Input) -> (result: Output, auxiliaryData: AuxiliaryData) {
        wrapped.inspectableApply(input)
    }
    
    @inlinable
    public func auxData(at input: Input) -> AuxiliaryData {
        wrapped.auxData(at: input)
    }
    
    @inlinable
    public func adjustment(input: Input, auxiliaryData: AuxiliaryData, gradient: Output.Adjustment) -> (adjustment: NoAdjustment<L.Adjustment.Scalar>, backprop: Input.Adjustment) {
        (NoAdjustment(), wrapped.backprop(input: input, auxiliaryData: auxiliaryData, gradient: gradient))
    }
    
    @inlinable
    public func backprop(input: L.Input, auxiliaryData: L.AuxiliaryData, gradient: L.Output.Adjustment) -> L.Input.Adjustment {
        wrapped.backprop(input: input, auxiliaryData: auxiliaryData, gradient: gradient)
    }
    
}


// make model-freezing transparent for encoding/decoding

public extension Frozen {

 init(from decoder: Decoder) throws {
    wrapped = try .init(from: decoder)
}

 func encode(to encoder: Encoder) throws {
     try wrapped.encode(to: encoder)
}

}
