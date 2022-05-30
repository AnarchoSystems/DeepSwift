//
//  Remote.swift
//  
//
//  Created by Markus Kasperczyk on 16.05.22.
//

import Foundation

public protocol DeviceProtocol {}


public protocol Memory {
    
    associatedtype Device : DeviceProtocol
    
    init()
    
    mutating func copy(to device: Device)
    mutating func delete(from device: Device)
    
}

public struct PairMemory<S: Memory, T : Memory> : Memory where S.Device == T.Device {
    
    public var first : S
    public var second: T
    
    public init() {
        first = S()
        second = T()
    }
    
    public init(_ s: S, _ t: T) {
        self.first = s
        self.second = t
    }
    
    public mutating func copy(to device: S.Device) {
        first.copy(to: device)
        second.copy(to: device)
    }
    
    public mutating func delete(from device: S.Device) {
        first.delete(from: device)
        second.delete(from: device)
    }
    
}


public struct RunPreventer {}

public protocol DeviceComputationProtocol {
    
    associatedtype MemoryType : Memory
    func run(on device: MemoryType.Device, memory: inout MemoryType, _ unsafeRunGuard: RunPreventer)
    
}

open class _DeviceComputation<MemoryType: Memory> {
    public init() {}
}

public typealias DeviceComputation<MemoryType : Memory> = _DeviceComputation<MemoryType> & DeviceComputationProtocol

public protocol DeviceComputationWrapperProtocol : DeviceComputationProtocol where MemoryType == Body.MemoryType {
    
    associatedtype MemoryType = Body.MemoryType
    associatedtype Body : DeviceComputationProtocol
    var body : Body {get}
    
}

public extension DeviceComputationWrapperProtocol {
    
    func run(on device: MemoryType.Device, memory: inout MemoryType, _ unsafeRunGuard: RunPreventer) {
        body.run(on: device, memory: &memory, unsafeRunGuard)
    }
    
}

open class _DeviceComputationWrapper<MemoryType : Memory> : _DeviceComputation<MemoryType> {}

public typealias DeviceComputationWrapper<MemoryType : Memory> = _DeviceComputationWrapper<MemoryType> & DeviceComputationWrapperProtocol

public struct VoidMemory<D : DeviceProtocol> : Memory {
    @inlinable
    public init() {}
    @inlinable
    public func copy(to device: D) {}
    @inlinable
    public func delete(from device: D) {}
}

public extension DeviceComputationProtocol {
    
    func runUnsafe<D>(on device: MemoryType.Device) where MemoryType == VoidMemory<D> {
        var mem = VoidMemory<D>()
        run(on: device, memory: &mem, RunPreventer())
    }
    
    func allocate<Mem : Memory>(_ value: Mem) -> AllocateFromVoid<Self, Mem> {
        AllocateFromVoid(wrapped: self, assignMemory: value)
    }
    
    func allocate<Mem : Memory>(_ value: Mem) -> Allocate<Self, Mem> {
        Allocate(wrapped: self, assignMemory: value)
    }
    
    func deallocate<Forgotten : Memory, Remaining : Memory>(_ forgetting: WritableKeyPath<MemoryType, Forgotten>, retaining: @escaping (MemoryType) -> Remaining) -> Deallocate<Self, Forgotten, Remaining> {
        Deallocate(wrapped: self, remaining: retaining, forgotten: forgetting)
    }
    
    func deallocate<M1 : Memory, M2 : Memory>(_ keyPath: WritableKeyPath<PairMemory<M1, M2>, M1>) -> Deallocate<Self, M1, M2> where MemoryType == PairMemory<M1, M2> {
        Deallocate(wrapped: self, remaining: \.second, forgotten: keyPath)
    }
    
    func deallocate<M1 : Memory, M2 : Memory>(_ keyPath: WritableKeyPath<PairMemory<M1, M2>, M2>) -> Deallocate<Self, M2, M1> where MemoryType == PairMemory<M1, M2> {
        Deallocate(wrapped: self, remaining: \.first, forgotten: keyPath)
    }
    
    func deallocateAll() -> DeallocateAll<Self> {
        DeallocateAll(wrapped: self)
    }
    
    func rearrange<New : Memory>(_ transform: @escaping (MemoryType) -> New) -> RefactComputation<Self, New> {
        RefactComputation(wrapped: self, transform: transform)
    }
    
    func chain<Next: DeviceComputationProtocol>(_ next: Next) -> ChainComputations<Self, Next> {
        ChainComputations(self, next)
    }
    
    func chainWithAllocs<Next : DeviceComputationProtocol>(_ next: Next) -> ChainAllocs<Self, Next> {
        ChainAllocs(self, next)
    }
    
}


public final class AllocateFromVoid<Wrapped : DeviceComputationProtocol, NewMemory : Memory> : DeviceComputation<NewMemory> where Wrapped.MemoryType == VoidMemory<NewMemory.Device> {
    
    @usableFromInline
    let wrapped : Wrapped
    @usableFromInline
    let assignMemory : NewMemory
    
    @usableFromInline
    init(wrapped: Wrapped, assignMemory: NewMemory) {
        self.wrapped = wrapped
        self.assignMemory = assignMemory
    }
    
    @inlinable
    public func run(on device: NewMemory.Device, memory: inout NewMemory, _ unsafeRunGuard: RunPreventer) {
        
        var mem = VoidMemory<NewMemory.Device>()
        wrapped.run(on: device, memory: &mem, unsafeRunGuard)
        memory = assignMemory
        memory.copy(to: device)
        
    }
    
}

public final class DeallocateAll<Wrapped : DeviceComputationProtocol> : DeviceComputation<VoidMemory<Wrapped.MemoryType.Device>> {
    
    @usableFromInline
    let wrapped : Wrapped
    
    @usableFromInline
    init(wrapped: Wrapped) {
        self.wrapped = wrapped
    }
    
    @inlinable
    public func run(on device: Wrapped.MemoryType.Device, memory: inout Wrapped.MemoryType, _ unsafeRunGuard: RunPreventer) {
        var mem = Wrapped.MemoryType()
        wrapped.run(on: device, memory: &mem, unsafeRunGuard)
        mem.delete(from: device)
    }
    
}

public final class Allocate<Wrapped : DeviceComputationProtocol, NextMemory : Memory> : DeviceComputation<PairMemory<Wrapped.MemoryType, NextMemory>> where Wrapped.MemoryType.Device == NextMemory.Device {
    
    @usableFromInline
    let wrapped : Wrapped
    @usableFromInline
    let assignMemory : NextMemory
    
    @usableFromInline
    init(wrapped: Wrapped, assignMemory: NextMemory) {
        self.wrapped = wrapped
        self.assignMemory = assignMemory
    }
    
    @inlinable
    public func run(on device: NextMemory.Device, memory: inout PairMemory<Wrapped.MemoryType, NextMemory>, _ unsafeRunGuard: RunPreventer) {
        wrapped.run(on: device, memory: &memory.first, unsafeRunGuard)
        memory.second = assignMemory
        memory.copy(to: device)
    }
    
}


public final class Deallocate<Wrapped : DeviceComputationProtocol, Forgotten : Memory, Remaining : Memory> : DeviceComputation<Remaining> where Wrapped.MemoryType.Device == Forgotten.Device, Forgotten.Device == Remaining.Device {
    
    @usableFromInline
    let wrapped : Wrapped
    @usableFromInline
    let remaining : (Wrapped.MemoryType) -> Remaining
    @usableFromInline
    let forgotten : WritableKeyPath<Wrapped.MemoryType, Forgotten>
    
    @usableFromInline
    init(wrapped: Wrapped,
         remaining: @escaping (Wrapped.MemoryType) -> Remaining,
         forgotten: WritableKeyPath<Wrapped.MemoryType, Forgotten>) {
        self.wrapped = wrapped
        self.remaining = remaining
        self.forgotten = forgotten
    }
    
    @inlinable
    public func run(on device: Remaining.Device, memory: inout Remaining, _ unsafeRunGuard: RunPreventer) {
        
        var old = Wrapped.MemoryType()
        wrapped.run(on: device, memory: &old, unsafeRunGuard)
        memory = remaining(old)
        old[keyPath: forgotten].delete(from: device)
        
    }
    
}


public final class RefactComputation<Wrapped : DeviceComputationProtocol, NewMemory : Memory> : DeviceComputation<NewMemory> where Wrapped.MemoryType.Device == NewMemory.Device {
    
    @usableFromInline
    let wrapped : Wrapped
    @usableFromInline
    let transform : (Wrapped.MemoryType) -> NewMemory
    
    @usableFromInline
    init(wrapped: Wrapped, transform: @escaping (Wrapped.MemoryType) -> NewMemory) {
        self.wrapped = wrapped
        self.transform = transform
        super.init()
    }
    
    @inlinable
    public func run(on device: NewMemory.Device, memory: inout NewMemory, _ unsafeRunGuard: RunPreventer) {
        
        var old = Wrapped.MemoryType()
        wrapped.run(on: device, memory: &old, unsafeRunGuard)
        memory = transform(old)
        
    }
    
}


public class ChainComputations<W1 : DeviceComputationProtocol, W2 : DeviceComputationProtocol> : DeviceComputation<W1.MemoryType> where W1.MemoryType == W2.MemoryType {
    
    @usableFromInline
    let w1 : W1
    @usableFromInline
    let w2 : W2
    
    @usableFromInline
    init(_ w1: W1, _ w2: W2) {
        self.w1 = w1
        self.w2 = w2
    }
    
    @inlinable
    public func run(on device: W1.MemoryType.Device, memory: inout W1.MemoryType, _ unsafeRunGuard: RunPreventer) {
        w1.run(on: device, memory: &memory, unsafeRunGuard)
        w2.run(on: device, memory: &memory, unsafeRunGuard)
    }
    
}


public class ChainAllocs<W1 : DeviceComputationProtocol, W2 : DeviceComputationProtocol> : DeviceComputation<PairMemory<W1.MemoryType, W2.MemoryType>> where W1.MemoryType.Device == W2.MemoryType .Device {
    
    @usableFromInline
    let w1 : W1
    @usableFromInline
    let w2 : W2
    
    @usableFromInline
    init(_ w1: W1, _ w2: W2) {
        self.w1 = w1
        self.w2 = w2
    }
    
    @inlinable
    public func run(on device: W1.MemoryType.Device, memory: inout PairMemory<W1.MemoryType, W2.MemoryType>, _ unsafeRunGuard: RunPreventer) {
        w1.run(on: device, memory: &memory.first, unsafeRunGuard)
        w2.run(on: device, memory: &memory.second, unsafeRunGuard)
    }
    
}


