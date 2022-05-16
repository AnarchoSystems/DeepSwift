//
//  Optimizer.swift
//  
//
//  Created by Markus Kasperczyk on 15.05.22.
//


public protocol Optimizer {
    
    associatedtype Model : Layer
    mutating func move(_ model: inout Model, along adjustment: Model.Adjustment)
    
}


public struct Momentum<Model : Layer> : Optimizer where Model.Adjustment.Scalar : ExpressibleByFloatLiteral, Model.Adjustment.Scalar : Comparable {
    
    let retain : Model.Adjustment.Scalar
    let stepWidth : Model.Adjustment.Scalar
    var lastAdjustment : Model.Adjustment?
    
    public init?(retain: Model.Adjustment.Scalar, stepWidth: Model.Adjustment.Scalar) {
        if retain < 0.0 || 1.0 < retain {
            return nil
        }
        self.retain = retain
        self.stepWidth = stepWidth
    }
    
    public mutating func move(_ model: inout Model, along adjustment: Model.Adjustment) {
        
        lastAdjustment = lastAdjustment.map{retain * $0 - stepWidth * adjustment} ?? adjustment
        model += lastAdjustment.unsafelyUnwrapped
        
    }
    
}
