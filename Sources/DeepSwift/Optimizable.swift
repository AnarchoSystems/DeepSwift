//
//  Optimizable.swift
//  
//
//  Created by Markus Kasperczyk on 15.05.22.
//

@propertyWrapper
public struct Optimizable<Value : Movable & Codable> : Movable, Codable {
    
    @usableFromInline
    enum Wrapper : Codable {
        
        case value(Value)
        case optimized(AnyOptimizer<Value>)
        
        enum Key : String, CodingKey {
            case optimizer
        }
        
        @usableFromInline
        init(from decoder: Decoder) throws {
            
            do {
                self = .value(try decoder.singleValueContainer().decode(Value.self))
            }
            catch {
                guard let registry = decoder.userInfo[optimizerRegistryKey] as? OptimizerRegistry else {
                    fatalError("Missing optimizer registry in decoding!")
                }
                let container = try decoder.container(keyedBy: Key.self)
                let opti = try container.decode(String.self, forKey: .optimizer)
                guard let coder = registry[opti] else {
                    fatalError(opti + " not registered in optimizer registry!")
                }
                guard let resolved : AnyOptimizer<Value> = try coder.decoder.makeOptimizer(from: decoder) else {
                    throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath,
                                                            debugDescription: "The data can not be decoded as " + opti))
                }
                self = .optimized(resolved)
            }
            
        }
        
        @usableFromInline
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .value(let value):
                    try container.encode(value)
            case .optimized(let anyOptimizer):
                try container.encode(anyOptimizer)
            }
        }
        
    }
    
    @usableFromInline
    class Box {
        var value : Wrapper!
    }
    
    @usableFromInline
    var _value : Box
    
    public var wrappedValue : Value {
        switch _value.value! {
        case .value(let value):
            return value
        case .optimized(let anyOptimizer):
            return anyOptimizer.value
        }
    }
    
    public init(wrappedValue : Value) {
        _value = Box()
        _value.value = .value(wrappedValue)
    }
    
    public init(from decoder: Decoder) throws {
        self = try .init(wrappedValue: .init(from: decoder))
    }
    
    public func encode(to encoder: Encoder) throws {
        try _value.value.encode(to: encoder)
    }
    
    public var projectedValue : Optimizable<Value> {
        _read {yield self}
        _modify {yield &self}
    }
    
    public mutating func move(_ adjustment: Value.Adjustment) {
        if !isKnownUniquelyReferenced(&_value) {
            let v = _value.value
            _value = Box()
            _value.value = v
        }
        switch _value.value! {
        case .value(var value):
            _value.value = nil
            value.move(adjustment)
            _value.value = .value(value)
        case .optimized(var anyOptimizer):
            _value.value = nil
            anyOptimizer.move(adjustment)
            _value.value = .optimized(anyOptimizer)
        }
    }
    
}
