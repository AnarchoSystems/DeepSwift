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


public protocol DeviceProtocol {
    
    associatedtype InstructionBuffer
    associatedtype RemoteMemory
    associatedtype FunctionHandle : Codable
    func createInstructionBuffer() -> InstructionBuffer
    func compile(_ instructions: InstructionBuffer) throws -> FunctionHandle
    func execute(_ instructions: FunctionHandle, input: RemoteMemory) -> RemoteMemory
    func delete(_ handle: FunctionHandle) throws
    
}

public protocol RemoteComputation {
    
    associatedtype Input
    associatedtype Output
    associatedtype Device : DeviceProtocol
    
    func run(on device: Device, input: Input) -> Output
    func encode(to buffer: inout Device.InstructionBuffer) throws
    
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
