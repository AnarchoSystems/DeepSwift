//
//  Repeat.swift
//  
//
//  Created by Markus Kasperczyk on 14.05.22.
//

public struct Repeat<L : Layer> : Layer where L.Input == L.Output {
    
    @usableFromInline
    let repetitions : Int
    
    @usableFromInline
    var model : L
    
    public init(_ model: L, repetitions: Int) {
        self.model = model
        self.repetitions = repetitions
    }
    
    @inlinable
    public func apply(_ input: L.Input) -> L.Output {
        (0..<repetitions).reduce(input) {inp, _ in model.apply(inp)}
    }
    
    @inlinable
    public func inspectableApply(_ input: L.Input) -> (result: L.Output, auxiliaryData: [(input: L.Input, aux: L.AuxiliaryData)]) {
        var results = [(input: L.Input, aux: L.AuxiliaryData)]()
        results.reserveCapacity(repetitions)
        var out = input
        for _ in (0..<repetitions) {
            let (result, aux) = model.inspectableApply(out)
            results.append((input: out, aux: aux))
            out = result
        }
        return (result: out, auxiliaryData: results)
    }
    
    @inlinable
    public func adjustment(input: L.Input, auxiliaryData: [(input: L.Input, aux: L.AuxiliaryData)], gradient: L.Output.Adjustment) -> (adjustment: DifferentiableArray<L.Adjustment>, backprop: L.Input.Adjustment) {
        var adjustments = [L.Adjustment]()
        adjustments.reserveCapacity(repetitions)
        var bp = gradient
        for (inp, aux) in auxiliaryData.reversed() {
            let (adj, newBp) = model.adjustment(input: inp, auxiliaryData: aux, gradient: bp)
            bp = newBp
            adjustments.append(adj)
        }
        return (DifferentiableArray(adjustments), bp)
    }
    
    @inlinable
    public func backprop(input: L.Input, auxiliaryData: [(input: L.Input, aux: L.AuxiliaryData)], gradient: L.Input.Adjustment) -> L.Input.Adjustment {
        var bp = gradient
        for (inp, aux) in auxiliaryData.reversed() {
            bp = model.backprop(input: inp, auxiliaryData: aux, gradient: bp)
        }
        return bp
    }
    
    @inlinable
    public mutating func move(_ adjustment: DifferentiableArray<L.Adjustment>) {
        for adj in adjustment.content {
            model.move(adj)
        }
    }
    
}
