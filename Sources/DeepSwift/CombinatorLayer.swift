//
//  CombinatorLayer.swift
//  
//
//  Created by Markus Kasperczyk on 15.05.22.
//

public protocol CombinatorLayer : Codable where
Lhs.Input == Rhs.Input, Input == Lhs.Input, Lhs.Adjustment.Scalar == Rhs.Adjustment.Scalar {
    
    associatedtype Input = Lhs.Input
    associatedtype Lhs : Layer
    associatedtype Rhs : Layer
    associatedtype AdditionalAuxiliaries = Void
    associatedtype Output : Movable
    
    var lhs : Lhs {get set}
    var rhs : Rhs {get set}
    func combine(_ lhs: Lhs.Output, _ rhs: Rhs.Output) -> Output
    func inspectableCombine(_ lhs: Lhs.Output, _ rhs: Rhs.Output) -> (result: Output, aux: AdditionalAuxiliaries)
    func adjustments(_ outLhs: Lhs.Output, _ outRhs: Rhs.Output, auxiliaryData: AdditionalAuxiliaries, gradient: Output.Adjustment) -> (dLhs: Lhs.Output.Adjustment, dRhs: Rhs.Output.Adjustment)
    
}

public extension CombinatorLayer where AdditionalAuxiliaries == Void {
    
    @inlinable
    func inspectableCombine(_ lhs: Lhs.Output, _ rhs: Rhs.Output) -> (result: Output, aux: ()) {
        (combine(lhs, rhs), ())
    }
    
}

public struct Combinator<C : CombinatorLayer> : Layer {
    
    public typealias AuxiliaryData = (C.Lhs.Output, C.Rhs.Output, C.AdditionalAuxiliaries, C.Lhs.AuxiliaryData, C.Rhs.AuxiliaryData)
    public typealias Adjustment = DifferentiablePair<C.Lhs.Adjustment, C.Rhs.Adjustment>
    
    @usableFromInline
    var combinator : C
    
    public init(_ combinator: C) {self.combinator = combinator}
    
}

public extension Combinator {
    
    @inlinable
    func apply(_ input: C.Lhs.Input) -> C.Output {
        combinator.combine(combinator.lhs.apply(input), combinator.rhs.apply(input))
    }
    
    @inlinable
    func inspectableApply(_ input: C.Lhs.Input) -> (result: C.Output, auxiliaryData: AuxiliaryData) {
        let (l, dl) = combinator.lhs.inspectableApply(input)
        let (r, dr) = combinator.rhs.inspectableApply(input)
        let (c, dc) = combinator.inspectableCombine(l, r)
        return (c, (l, r, dc, dl, dr))
    }
    
    @inlinable
    func adjustment(input: C.Lhs.Input, auxiliaryData: AuxiliaryData, gradient: C.Output.Adjustment) -> (adjustment: Adjustment, backprop: C.Lhs.Input.Adjustment) {
        let (adj1, adj2) : (dLhs: C.Lhs.Output.Adjustment, dRhs: C.Rhs.Output.Adjustment) = combinator.adjustments(auxiliaryData.0, auxiliaryData.1, auxiliaryData: auxiliaryData.2, gradient: gradient)
        let (dLhs, bp1) = combinator.lhs.adjustment(input: input, auxiliaryData: auxiliaryData.3, gradient: adj1)
        let (dRhs, bp2) = combinator.rhs.adjustment(input: input, auxiliaryData: auxiliaryData.4, gradient: adj2)
        return (DifferentiablePair(dLhs, dRhs), bp1 + bp2)
    }
    
    @inlinable
    func backprop(input: C.Input, auxiliaryData: AuxiliaryData, gradient: C.Output.Adjustment) -> C.Input.Adjustment {
        let (adj1, adj2) : (dLhs: C.Lhs.Output.Adjustment, dRhs: C.Rhs.Output.Adjustment) = combinator.adjustments(auxiliaryData.0, auxiliaryData.1, auxiliaryData: auxiliaryData.2, gradient: gradient)
        return combinator.lhs.backprop(input: input, auxiliaryData: auxiliaryData.3, gradient: adj1)
        + combinator.rhs.backprop(input: input, auxiliaryData: auxiliaryData.4, gradient: adj2)
    }
    
    @inlinable
    mutating func move(_ adjustment: Adjustment) {
        combinator.lhs.move(adjustment.first)
            combinator.rhs.move(adjustment.second)
    }
    
}
