//
//  Learner.swift
//  
//
//  Created by Markus Kasperczyk on 14.05.22.
//

public protocol Learner : Layer where Input == Wrapped.Input, Output == Wrapped.Output, AuxiliaryData == Wrapped.AuxiliaryData, Adjustment == Wrapped.Adjustment {
    
    associatedtype Input = Wrapped.Input
    associatedtype Output = Wrapped.Output
    associatedtype AuxiliaryData = Wrapped.AuxiliaryData
    associatedtype Adjustment = Wrapped.Adjustment
    associatedtype Wrapped : Layer
    
    var body : Wrapped {get set}
    
}


public extension Learner {
    
    func apply(_ input: Input) -> Output {
        body.apply(input)
    }
    
    func inspectableApply(_ input: Input) -> (result: Output, auxiliaryData: AuxiliaryData) {
        body.inspectableApply(input)
    }
    
    func auxData(at input: Input) -> AuxiliaryData {
        body.auxData(at: input)
    }
    
    func adjustment(input: Input, auxiliaryData: AuxiliaryData, gradient: Wrapped.Output.Adjustment) -> (Adjustment, Wrapped.Input.Adjustment) {
        body.adjustment(input: input, auxiliaryData: auxiliaryData, gradient: gradient)
    }
    
    func backprop(input: Input, auxiliaryData: AuxiliaryData, gradient: Output.Adjustment) -> Input.Adjustment {
        body.backprop(input: input, auxiliaryData: auxiliaryData, gradient: gradient)
    }
    
    mutating func move(_ adjustment: Adjustment) {
        body.move(adjustment)
    }
    
}
