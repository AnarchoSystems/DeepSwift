//
//  Many.swift
//  
//
//  Created by Markus Kasperczyk on 14.05.22.
//

public struct Many<L : Layer> : Layer where L.Input == L.Output {
    
    @usableFromInline
    var models : [L]
    
    public init(_ models : [L]) {
        self.models = models
    }
    
    @inlinable
    public func apply(_ input: L.Input) -> L.Output {
        models.reduce(input) {$1.apply($0)}
    }
    
    @inlinable
    public func inspectableApply(_ input: L.Input) -> (result: L.Output, auxiliaryData: [(input: L.Input, aux: L.AuxiliaryData)]) {
        var results = [(input: L.Input, aux: L.AuxiliaryData)]()
        results.reserveCapacity(models.count)
        var out = input
        for model in models {
            let (result, aux) = model.inspectableApply(out)
            results.append((input: out, aux: aux))
            out = result
        }
        return (result: out, auxiliaryData: results)
    }
    
    @inlinable
    public func adjustment(input: L.Input, auxiliaryData: [(input: L.Input, aux: L.AuxiliaryData)], gradient: L.Output.Adjustment) -> ([L.Adjustment], L.Input.Adjustment) {
        var adjustments = [L.Adjustment]()
        adjustments.reserveCapacity(models.count)
        var bp = gradient
        for (idx, inputAndAux) in auxiliaryData.enumerated().reversed() {
            let (inp, aux) = inputAndAux
            let (adj, newBp) = models[idx].adjustment(input: inp, auxiliaryData: aux, gradient: bp)
            bp = newBp
            adjustments.append(adj)
        }
        return (adjustments, bp)
    }
    
    @inlinable
    public func backprop(input: L.Input, auxiliaryData: [(input: L.Input, aux: L.AuxiliaryData)], gradient: L.Input.Adjustment) -> L.Input.Adjustment {
        var bp = gradient
        for (idx, inputAndAux) in auxiliaryData.enumerated().reversed() {
            bp = models[idx].backprop(input: inputAndAux.input, auxiliaryData: inputAndAux.aux, gradient: bp)
        }
        return bp
    }
    
    @inlinable
    public mutating func move(_ adjustment: [L.Adjustment]) {
        for (idx, adj) in adjustment.reversed().enumerated() {
            models[idx].move(adj)
        }
    }
    
}
