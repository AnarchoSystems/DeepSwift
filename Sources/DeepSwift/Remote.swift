//
//  Remote.swift
//  
//
//  Created by Markus Kasperczyk on 16.05.22.
//


@available(iOS 13.0.0, *)
public protocol FetchableType {
    
    associatedtype Device : DeviceProtocol
    init(_ raw: Device.RemoteMemory, device: Device) async throws
    
}

@available(iOS 13.0.0, *)
public protocol CommittableType {
    
    associatedtype Device : DeviceProtocol
    func commit(to device: Device) async throws -> Device.RemoteMemory
    
}


public protocol DeviceProtocol : Codable {
    
    associatedtype InstructionBuffer
    associatedtype RemoteMemory
    associatedtype FunctionHandle
    func createInstructionBuffer() -> InstructionBuffer
    func compile(_ instructions: InstructionBuffer) throws -> FunctionHandle
    func checkExists(_ handle: FunctionHandle) -> Bool
    func execute(_ instructions: FunctionHandle, input: RemoteMemory) -> RemoteMemory
    func delete(_ handle: FunctionHandle) throws
    
}

public protocol RemoteComputation {
    
    associatedtype Input
    associatedtype Output
    associatedtype Device : DeviceProtocol
    
    /// Runs the computation on the remote device. This method exists so you can debug your computation in an "interpreted" way (where sequencing of instructions is orchestrated by the local CPU) in case you suspect that there's an error in the device's compiler.
    func callAsFunction(on device: Device, input: Input) -> Output
    /// Adds the computation to an instruction buffer if possible. Instruction buffers are a data format that the remote device understands so it can do optimizations such as running the computations in sequence with minimal to zero communication with your local CPU.
    func encode(to buffer: inout Device.InstructionBuffer) throws
    
}

public struct CPU {
    
    @inlinable
    public static var shared : Self {
        Self()
    }
    
    @usableFromInline
    init() {}
    
}

public struct CPUAlreadyCompiled : Error {}

extension CPU : DeviceProtocol {
    
    public func createInstructionBuffer() {}
    public func compile(_ instructions: ()) throws { throw CPUAlreadyCompiled() }
    public func checkExists(_ handle: ()) -> Bool { false }
    public func execute(_ instructions: (), input: ()) {}
    public func delete(_ handle: ()) throws {}
    
}

public extension RemoteComputation where Device == CPU {
    
    func callAsFunction(_ input: Input) -> Output {
        callAsFunction(on: .shared, input: input)
    }
    
}

@available(iOS 13.0.0, *)
public extension RemoteComputation where Input : CommittableType, Output : FetchableType, Input.Device == Device, Output.Device == Device {
    
    func deploy(to device: Device) throws -> CompiledRemoteComputation<Input, Output> {
        var emptyInstructionBuffer = device.createInstructionBuffer()
        try encode(to: &emptyInstructionBuffer)
        let handle = try device.compile(emptyInstructionBuffer)
        return CompiledRemoteComputation(device: device, handle: handle)
    }
    
}

@available(iOS 13.0.0, *)
public struct CompiledRemoteComputation<Input : CommittableType, Output : FetchableType> where Input.Device == Output.Device {
    
    public typealias Device = Input.Device
    public let device : Device
    public let handle : Device.FunctionHandle
    
    public init(device: Device, handle: Device.FunctionHandle) {
        self.device = device
        self.handle = handle
    }
    
    public func run(input: Input) async throws -> Output {
        try await .init(device.execute(handle, input: input.commit(to: device)), device: device)
    }
    
}

@available(iOS 13.0.0, *)
extension CompiledRemoteComputation : Codable where Device.FunctionHandle : Codable {}
