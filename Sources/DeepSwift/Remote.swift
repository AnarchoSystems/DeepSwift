//
//  Remote.swift
//  
//
//  Created by Markus Kasperczyk on 16.05.22.
//


public protocol DeviceProtocol : Codable {
    
    associatedtype InstructionBuffer
    associatedtype RawPointer
    associatedtype FunctionHandle
    func createInstructionBuffer() -> InstructionBuffer
    func compile(_ instructions: InstructionBuffer) throws -> FunctionHandle
    func checkExists(_ handle: FunctionHandle) -> Bool
    func execute(_ instructions: FunctionHandle, input: RawPointer) -> RawPointer
    func delete(_ handle: FunctionHandle) throws
    func delete(_ memory: RawPointer)
    func encodeDeletion(of memory: RawPointer, to instructionBuffer: InstructionBuffer)
    
}

public protocol MemoryDescriptor {
    
    associatedtype Device : DeviceProtocol
    func allocate(on device: Device) -> Device.RawPointer
    func encodeAllocation(to buffer: Device.InstructionBuffer) -> Device.RawPointer
    
}

open class Procedure<Device: DeviceProtocol, Result> {
    
    public let device : Device
    
    public init(_ device: Device) {
        self.device = device
    }
    
    open func evaluate() {}
    open func encode(to buffer: Device.InstructionBuffer) {}
    
}

open class Symbol<T : MemoryDescriptor> : Procedure<T.Device, T> {
    
    public typealias Device = T.Device
    
    open var memory : Device.RawPointer {
        fatalError()
    }
    
    public final override func evaluate() {
        _ = memory
    }
    
}

public final class AllocatedSymbol<T : MemoryDescriptor> : Symbol<T> {
    
    @usableFromInline
    let layout : T
    @usableFromInline
    var _memory: T.Device.RawPointer?
    @inlinable
    public override var memory: T.Device.RawPointer {
        if _memory == nil {
            _memory = layout.allocate(on: device)
        }
        return _memory!
    }
    
    @usableFromInline
    init(device: Device, layout: T) {
        self.layout = layout
        super.init(device)
    }
    
    override public func encode(to buffer: Symbol<T>.Device.InstructionBuffer) {
        _memory = layout.encodeAllocation(to: buffer)
    }
    
}

fileprivate protocol NeedsStartup {
    func beforeEval()
    func encodePre<T>(to buffer: T)
}

fileprivate protocol NeesCleanup {
    func afterEval()
    func encodePost<T>(to buffer: T)
}



/// To be assigned exactly once. Think of this as a declaration of a let constant.
@propertyWrapper
public final class Consumed<T : MemoryDescriptor> : NeesCleanup {
    
    public var wrappedValue : Symbol<T>!
    
    public init() {}
    
    func afterEval() {
        wrappedValue.device.delete(wrappedValue.memory)
    }
    
    func encodePost<S>(to buffer: S) {
        wrappedValue.device.encodeDeletion(of: wrappedValue.memory, to: (buffer as! T.Device.InstructionBuffer))
    }
    
}

@propertyWrapper
public final class Local<T : MemoryDescriptor> : NeedsStartup & NeesCleanup {
    
    var layout : T
    public var wrappedValue : Symbol<T>
    
    public init(layout: T, device: T.Device) {
        self.layout = layout
        wrappedValue = AllocatedSymbol(device: device, layout: layout)
    }
    
    @inlinable
    public var projectedValue : Local<T> {
        self
    }
    
    func beforeEval() {
        wrappedValue = AllocatedSymbol(device: wrappedValue.device, layout: layout)
    }
    
    func encodePre<S>(to buffer: S) {
        beforeEval()
        wrappedValue.encode(to: (buffer as! T.Device.InstructionBuffer))
    }
    
    func afterEval() {
        wrappedValue.device.delete(wrappedValue.memory)
    }
    
    func encodePost<S>(to buffer: S) {
        wrappedValue.device.encodeDeletion(of: wrappedValue.memory, to: (buffer as! T.Device.InstructionBuffer))
    }
    
}


@propertyWrapper
public final class AllocatingReturn<T : MemoryDescriptor> : NeedsStartup {
    
    var layout : T
    public var wrappedValue : Symbol<T>
    
    public init(layout: T, device: T.Device) {
        self.layout = layout
        wrappedValue = AllocatedSymbol(device: device, layout: layout)
    }
    
    @inlinable
    public var projectedValue : AllocatingReturn<T> {
        self
    }
    
    func beforeEval() {
        wrappedValue = AllocatedSymbol(device: wrappedValue.device, layout: layout)
    }
    
    func encodePre<S>(to buffer: S) {
        beforeEval()
        wrappedValue.encode(to: (buffer as! T.Device.InstructionBuffer))
    }
    
}

public class Computation<T : MemoryDescriptor> : Symbol<T> {
    
    public var body : Symbol<T> {fatalError("Abstract method")}
    
    public override var memory: T.Device.RawPointer {
        
        let mirror = Mirror(reflecting: self)
        
        for (_, child) in mirror.children {
            if let needsStartup = child as? NeedsStartup {
                needsStartup.beforeEval()
            }
        }
        
        let body = body
        body.evaluate()
        
        for (_, child) in mirror.children {
            if let needsStartup = child as? NeesCleanup {
                needsStartup.afterEval()
            }
        }
        
        return body.memory
        
    }
    
    public override func encode(to buffer: T.Device.InstructionBuffer) {
        
        let mirror = Mirror(reflecting: self)
        
        for (_, child) in mirror.children {
            if let needsStartup = child as? NeedsStartup {
                needsStartup.encodePre(to: buffer)
            }
        }
        
        let body = body
        body.encode(to: buffer)
        
        for (_, child) in mirror.children {
            if let needsStartup = child as? NeesCleanup {
                needsStartup.encodePost(to: buffer)
            }
        }
        
    }
    
}
