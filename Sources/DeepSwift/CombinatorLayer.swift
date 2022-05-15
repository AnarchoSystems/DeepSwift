//
//  CombinatorLayer.swift
//  
//
//  Created by Markus Kasperczyk on 15.05.22.
//

public protocol DiffArithmetic where Scalar.Scalar == Scalar, Scalar : Movable, Scalar.Adjustment == Scalar {
    associatedtype Scalar : DiffArithmetic
    static func *(lhs: Scalar, rhs: Self) -> Self
    static func +(lhs: Self, rhs: Self) -> Self
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

public protocol CombinatorLayer : Layer where
Lhs.Input == Rhs.Input, Input == Lhs.Input, Input.Adjustment : DiffArithmetic,
AuxiliaryData == (Lhs.Output, Rhs.Output, AdditionalAuxiliaries, Lhs.AuxiliaryData, Rhs.AuxiliaryData),
Adjustment == (Lhs.Adjustment, Rhs.Adjustment) {
    
    associatedtype Input = Lhs.Input
    associatedtype Lhs : Layer
    associatedtype Rhs : Layer
    associatedtype AdditionalAuxiliaries = Void
    associatedtype AuxiliaryData = (Lhs.Output, Rhs.Output, AdditionalAuxiliaries, Lhs.AuxiliaryData, Rhs.AuxiliaryData)
    associatedtype Adjustment = (Lhs.Adjustment, Rhs.Adjustment)
    associatedtype Output
    
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

public extension CombinatorLayer {
    
    @inlinable
    func apply(_ input: Lhs.Input) -> Output {
        combine(lhs.apply(input), rhs.apply(input))
    }
    
    @inlinable
    func inspectableApply(_ input: Input) -> (result: Output, auxiliaryData: AuxiliaryData) {
        let (l, dl) = lhs.inspectableApply(input)
        let (r, dr) = rhs.inspectableApply(input)
        let (c, dc) = inspectableCombine(l, r)
        return (c, (l, r, dc, dl, dr))
    }
    
    @inlinable
    func adjustment(input: Input, auxiliaryData: AuxiliaryData, gradient: Output.Adjustment) -> (adjustment: Adjustment, backprop: Input.Adjustment) {
        let (adj1, adj2) : (dLhs: Lhs.Output.Adjustment, dRhs: Rhs.Output.Adjustment) = adjustments(auxiliaryData.0, auxiliaryData.1, auxiliaryData: auxiliaryData.2, gradient: gradient)
        let (dLhs, bp1) = lhs.adjustment(input: input, auxiliaryData: auxiliaryData.3, gradient: adj1)
        let (dRhs, bp2) = rhs.adjustment(input: input, auxiliaryData: auxiliaryData.4, gradient: adj2)
        return ((dLhs, dRhs), bp1 + bp2)
    }
    
    @inlinable
    func backprop(input: Input, auxiliaryData: AuxiliaryData, gradient: Output.Adjustment) -> Input.Adjustment {
        let (adj1, adj2) : (dLhs: Lhs.Output.Adjustment, dRhs: Rhs.Output.Adjustment) = adjustments(auxiliaryData.0, auxiliaryData.1, auxiliaryData: auxiliaryData.2, gradient: gradient)
        return lhs.backprop(input: input, auxiliaryData: auxiliaryData.3, gradient: adj1)
                + rhs.backprop(input: input, auxiliaryData: auxiliaryData.4, gradient: adj2)
    }
    
    @inlinable
    mutating func move(_ adjustment: Adjustment) {
        lhs.move(adjustment.0)
        rhs.move(adjustment.1)
    }
    
}
