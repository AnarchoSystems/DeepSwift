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


public struct ChainedLayers<L1 : Layer, L2: Layer> : Layer where L1.Output == L2.Input {
    
    public typealias AuxiliaryData = (L1.Output?, L2.AuxiliaryData?, L1.AuxiliaryData?)
    public typealias Adjustment = (L1.Adjustment?, L2.Adjustment?)
    
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
        var adj : Adjustment = (nil, nil)
        let b2 : L2.Input.Adjustment
        let b1 : L1.Input.Adjustment
        (adj.1, b2) = second.adjustment(input: auxiliaryData.0.unsafelyUnwrapped, auxiliaryData: auxiliaryData.1.unsafelyUnwrapped, gradient: gradient)
        (adj.0, b1) = first.adjustment(input: input, auxiliaryData: auxiliaryData.2.unsafelyUnwrapped, gradient: b2)
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
        first.move(adjustment.0.unsafelyUnwrapped)
        second.move(adjustment.1.unsafelyUnwrapped)
    }
    
}


// MARK: Boilerplate types


public struct Chain3<L1 : Layer, L2 : Layer, L3 : Layer> : Layer where L2.Input == L1.Output, L3.Input == L2.Output {
    
    public typealias AuxiliaryData = (L2.Output?, L3.AuxiliaryData?, L1.Output?, L2.AuxiliaryData?, L1.AuxiliaryData?)
    public typealias Adjustment = (L1.Adjustment?, L2.Adjustment?, L3.Adjustment?)
    
    @usableFromInline
    var l1 : L1
    @usableFromInline
    var l2 : L2
    @usableFromInline
    var l3 : L3
    
    public init(_ l1: L1, _ l2: L2, _ l3: L3) {
        (self.l1, self.l2, self.l3) = (l1, l2, l3)
    }
    
    @inlinable
    public func apply(_ input: L1.Input) -> L3.Output {
        l3.apply(l2.apply(l1.apply(input)))
    }
    
    @inlinable
    public func inspectableApply(_ input: L1.Input) -> (result: L3.Output, auxiliaryData: AuxiliaryData) {
        var aux : AuxiliaryData = (nil, nil, nil, nil, nil)
        let o3 : L3.Output
        (aux.2, aux.4) = l1.inspectableApply(input)
        (aux.0, aux.3) = l2.inspectableApply(aux.2.unsafelyUnwrapped)
        (o3, aux.1) = l3.inspectableApply(aux.0.unsafelyUnwrapped)
        return (o3, aux)
    }
    
    @inlinable
    public func auxData(at input: L1.Input) -> AuxiliaryData {
        var aux : AuxiliaryData = (nil, nil, nil, nil, nil)
        (aux.2, aux.4) = l1.inspectableApply(input)
        (aux.0, aux.3) = l2.inspectableApply(aux.2.unsafelyUnwrapped)
        aux.1 = l3.auxData(at: aux.0.unsafelyUnwrapped)
        return aux
    }
    
    @inlinable
    public func adjustment(input: L1.Input,
                           auxiliaryData: AuxiliaryData,
                           gradient: L3.Output.Adjustment) -> (adjustment: Adjustment, backprop: L1.Input.Adjustment) {
        var adj : Adjustment = (nil, nil, nil)
        let bp3 : L3.Input.Adjustment
        let bp2 : L2.Input.Adjustment
        let bp1 : L1.Input.Adjustment
        (adj.2, bp3) = l3.adjustment(input: auxiliaryData.0.unsafelyUnwrapped, auxiliaryData: auxiliaryData.1.unsafelyUnwrapped, gradient: gradient)
        (adj.1, bp2) = l2.adjustment(input: auxiliaryData.2.unsafelyUnwrapped, auxiliaryData: auxiliaryData.3.unsafelyUnwrapped, gradient: bp3)
        (adj.0, bp1) = l1.adjustment(input: input, auxiliaryData: auxiliaryData.4.unsafelyUnwrapped, gradient: bp2)
        return (adj, bp1)
    }
    
    @inlinable
    public func backprop(input: L1.Input, auxiliaryData: (L2.Output?, L3.AuxiliaryData?, L1.Output?, L2.AuxiliaryData?, L1.AuxiliaryData?), gradient: L3.Output.Adjustment) -> L1.Input.Adjustment {
        l1.backprop(input: input,
                    auxiliaryData: auxiliaryData.4.unsafelyUnwrapped,
                    gradient: l2.backprop(input: auxiliaryData.2.unsafelyUnwrapped,
                                          auxiliaryData: auxiliaryData.3.unsafelyUnwrapped,
                                          gradient: l3.backprop(input: auxiliaryData.0.unsafelyUnwrapped,
                                                                auxiliaryData: auxiliaryData.1.unsafelyUnwrapped,
                                                                gradient: gradient)))
    }
    
    @inlinable
    public mutating func move(_ adjustment: Adjustment) {
        l1.move(adjustment.0.unsafelyUnwrapped)
        l2.move(adjustment.1.unsafelyUnwrapped)
        l3.move(adjustment.2.unsafelyUnwrapped)
    }
    
}

// to be continued ...
