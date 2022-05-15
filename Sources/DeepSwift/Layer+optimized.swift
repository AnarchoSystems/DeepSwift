//
//  Layer+optimized.swift
//  
//
//  Created by Markus Kasperczyk on 15.05.22.
//


fileprivate protocol OptimizerAcceptor {
    
    func acceptOptimizer<Factory : OptimizerFactory>(_ factory: Factory)
    func ejectOptimizer()
    
}

func setOptimizer<Factory : OptimizerFactory>(_ factory: Factory, in any: Any) {
    
    var children = Array(Mirror(reflecting: any).children)
    var childIdx = 0
    
    while children.indices.contains(childIdx) {
        if children[childIdx] is OptimizerAcceptor {
            (children[childIdx] as! OptimizerAcceptor).acceptOptimizer(factory)
        }
        else {
                children.append(contentsOf: Mirror(reflecting: children[childIdx]).children)
        }
        childIdx += 1
    }
    
}

func ejectOptimizer(in any: Any) {
    
    var children = Array(Mirror(reflecting: any).children)
    var childIdx = 0
    
    while children.indices.contains(childIdx) {
        if children[childIdx] is OptimizerAcceptor {
            (children[childIdx] as! OptimizerAcceptor).ejectOptimizer()
        }
        else {
                children.append(contentsOf: Mirror(reflecting: children[childIdx]).children)
        }
        childIdx += 1
    }
    
}

public extension Layer {
    
    /// In this method, the ```@Param```s have reference semantics. Copy this learner only after injecting the optimizer!
    mutating func setOptimizer<Factory : OptimizerFactory>(_ factory: Factory) {
        DeepSwift.setOptimizer(factory, in: self)
    }
    
    /// In this method, the ```@Param```s have reference semantics. Copy this learner only after injecting the optimizer!
    func optimized<Factory : OptimizerFactory>(_ factory: Factory) -> Self {
        var result = self
        result.setOptimizer(factory)
        return result
    }
    
    mutating func ejectOptimizer() {
        DeepSwift.ejectOptimizer(in: self)
    }
    
    func ejectingOptimizer() -> Self {
        var copy = self
        copy.ejectOptimizer()
        return copy
    }
    
}

extension Optimizable : OptimizerAcceptor {
    
    fileprivate func acceptOptimizer<Factory>(_ factory: Factory) where Factory : OptimizerFactory {
        if let opti = factory.makeOptimizer(wrappedValue) {
            _value.value = .optimized(opti)
        }
    }
    
    fileprivate func ejectOptimizer() {
        _value.value = .value(wrappedValue)
    }
    
}
