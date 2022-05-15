//
//  Layer.swift
//  
//
//  Created by Markus Kasperczyk on 14.05.22.
//


public protocol Layer : Movable, Codable {
    
    associatedtype Input : Movable
    associatedtype Output : Movable
    associatedtype AuxiliaryData
    
    func apply(_ input: Input) -> Output
    
    func auxData(at input: Input) -> AuxiliaryData
    
    func inspectableApply(_ input: Input) -> (result: Output, auxiliaryData: AuxiliaryData)
    
    func adjustment(input: Input, auxiliaryData: AuxiliaryData, gradient: Output.Adjustment) -> (Adjustment, Input.Adjustment)
    
    func backprop(input: Input, auxiliaryData: AuxiliaryData, gradient: Output.Adjustment) -> Input.Adjustment
    
}

public extension Layer {
    
    func apply(_ input: Input) -> Output {
        inspectableApply(input).result
    }
    
    func auxData(at input: Input) -> AuxiliaryData {
        inspectableApply(input).auxiliaryData
    }
    
    func backprop(input: Input, auxiliaryData: AuxiliaryData, gradient: Output.Adjustment) -> Input.Adjustment {
        adjustment(input: input, auxiliaryData: auxiliaryData, gradient: gradient).1
    }
    
    mutating func learn<Loss : Layer>(examples: Input, loss: Loss)  where
    Loss.Adjustment == Void,
          Loss.AuxiliaryData == Output.Adjustment,
          Loss.Input == Output {
              let (result, derivative) = inspectableApply(examples)
              let (adjustment, _) = adjustment(input: examples, auxiliaryData: derivative, gradient: loss.auxData(at: result))
              move(adjustment)
          }
    
}

public protocol Function : Layer where Adjustment == Void {
    associatedtype Adjustment = Void
}
