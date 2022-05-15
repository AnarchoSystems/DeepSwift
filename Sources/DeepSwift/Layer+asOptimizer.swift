//
//  Layer+asOptimizer.swift
//  
//
//  Created by Markus Kasperczyk on 15.05.22.
//

public extension Layer {
    
    func asOptimizer(identifier: String, seed: Input) -> ToOptimizer<Self> where Input : Codable, Output : Codable {
        return ToOptimizer(optimizer: identifier, layer: self, params: seed)
    }
    
}

public struct ToOptimizer<L : Layer> : Optimizer where L.Input : Codable, L.Output : Codable {
    
    public let optimizer : String
    
    @usableFromInline
    var layer : L
    
    @usableFromInline
    var auxData : L.AuxiliaryData
    
    @usableFromInline
    var params : L.Input
    
    public var value : L.Output
    
    init(optimizer: String, layer: L, params: L.Input) {
        self.optimizer = optimizer
        self.layer = layer
        self.params = params
        (value, auxData) = layer.inspectableApply(params)
    }
    
    public mutating func move(_ adjustment: L.Output.Adjustment) {
        let (adj, bp) = layer.adjustment(input: params, auxiliaryData: auxData, gradient: adjustment)
        params.move(bp)
        layer.move(adj)
        (value, auxData) = layer.inspectableApply(params)
    }
    
}

extension ToOptimizer {
    
    private struct Helper : Codable {
        public let optimizer : String
        var layer : L
        var params : L.Input
        init(optimizer : String, layer: L, params: L.Input) {
            self.optimizer = optimizer
            self.layer = layer
            self.params = params
        }
    }
    
    public init(from decoder: Decoder) throws {
        let helper = try Helper(from: decoder)
        self = ToOptimizer(optimizer: helper.optimizer, layer: helper.layer, params: helper.params)
    }
    
    public func encode(to encoder: Encoder) throws {
        try Helper(optimizer: optimizer, layer: layer, params: params).encode(to: encoder)
    }
    
}
