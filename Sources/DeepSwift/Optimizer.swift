//
//  Optimizer.swift
//  
//
//  Created by Markus Kasperczyk on 15.05.22.
//


public protocol Optimizer : Movable, Codable where Adjustment == Output.Adjustment {
    
    associatedtype Adjustment = Output.Adjustment
    associatedtype Output : Movable
    var value : Output {get}
    var optimizer : String {get}
    
}

public protocol OptimizerFactory {
    
    /// This identifier should be unique in your namespace, but always the same across restarts of the application.
    static var uniqueIdentifier : String {get}
    func makeOptimizer<Output : Movable>(_ params: Output) -> AnyOptimizer<Output>?
    static var decoder : OptimizerDecoder {get}
    
}

@usableFromInline
class _AnyOptimizer<Output : Movable> : Optimizer {
     
    @usableFromInline
    var value : Output {
        fatalError()
    }
    
    @usableFromInline
    init(){}
    
    @usableFromInline
     required init(from decoder: Decoder) throws {
         fatalError()
     }
    
   @usableFromInline
    func move(_ adjustment: Output.Adjustment) {
        fatalError()
    }
    
   @usableFromInline
    func copy() -> _AnyOptimizer<Output> {
        fatalError()
    }
    
    @usableFromInline
    var optimizer : String {
        fatalError()
    }
    
}

@usableFromInline
final class _ConcreteOptimizer<Wrapped : Optimizer> : _AnyOptimizer<Wrapped.Output> {
    
    @usableFromInline
    var _optimizer : Wrapped
    
   @usableFromInline
    init(_ wrapped: Wrapped) {
        self._optimizer = wrapped
        super.init()
    }
    
   @usableFromInline
    required init(from decoder: Decoder) throws {
        fatalError()
    }
    
    @usableFromInline
    override func encode(to encoder: Encoder) throws {
        try _optimizer.encode(to: encoder)
    }
    
   @usableFromInline
    override var value : Wrapped.Output {
        _optimizer.value
    }
    
   @usableFromInline
    override func move(_ adjustment: Output.Adjustment) {
        _optimizer.move(adjustment)
    }
    
   @usableFromInline
    override func copy() -> Self {
        Self(_optimizer)
    }
    
    @usableFromInline
    override var optimizer : String {
        _optimizer.optimizer
    }
    
}


public struct AnyOptimizer<Output : Movable> : Optimizer {
    
    @usableFromInline
    var wrapped : _AnyOptimizer<Output>
    
    @inlinable
    public init<Opti : Optimizer>(_ opti: Opti) where Opti.Output == Output {
        self.wrapped = _ConcreteOptimizer(opti)
    }
    
    @inlinable
    public var value : Output {
        wrapped.value
    }
    
    @inlinable
    public mutating func move(_ adjustment: Adjustment) {
        if !isKnownUniquelyReferenced(&wrapped) {
            wrapped = wrapped.copy()
        }
        wrapped.move(adjustment)
    }
    
    @inlinable
    public var optimizer : String {
        wrapped.optimizer
    }
    
}

public extension Optimizer {
    
    func erased() -> AnyOptimizer<Output> {
        AnyOptimizer(self)
    }
    
}

public protocol OptimizerDecoder {
    func makeOptimizer<Output : Movable>(from decoder: Decoder) throws -> AnyOptimizer<Output>?
}

public extension OptimizerFactory {
    
    static var coder : OptimizerCoder {
        .init(Self.self)
    }
    
}

public let optimizerRegistryKey = CodingUserInfoKey(rawValue: "OptimizerRegistry")!

public struct OptimizerCoder {
    
    let decoder : OptimizerDecoder
    let id : String
    
    public init<Fac : OptimizerFactory>(_ type: Fac.Type) {
        self.decoder = type.decoder
        self.id = type.uniqueIdentifier
    }
    
}

public struct OptimizerRegistry : ExpressibleByArrayLiteral {
    
    var elems : [String : OptimizerCoder]
    
    public init() {
        elems = [:]
    }
    
    public init(arrayLiteral elements: OptimizerCoder...) {
        elems = .init(uniqueKeysWithValues: elements.lazy.map{($0.id, $0)})
    }
    
    public mutating func register<Fac: OptimizerFactory>(_ type: Fac.Type) {
        elems[type.uniqueIdentifier] = type.coder
    }
    
    public subscript(_ id: String) -> OptimizerCoder? {
        elems[id]
    }
    
}
