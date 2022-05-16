//
//  Remote.swift
//  
//
//  Created by Markus Kasperczyk on 16.05.22.
//

public protocol CompiledRemoteComputation {
    
    associatedtype Input
    associatedtype Output
    associatedtype Device
    
    var device : Device {get}
    func run(input: Input) -> Output
    
}

public protocol RemoteComputation where Compiled.Input == Input, Compiled.Output == Output, Compiled.Device == Device {
    
    associatedtype Input
    associatedtype Output
    associatedtype Device
    associatedtype Compiled : CompiledRemoteComputation
    
    func run(on device: Device, input: Input) -> Output
    func compile(on device: Device) -> Compiled
    
}


@available(iOS 13.0.0, *)
public protocol InitializableRemoteType {
    
    associatedtype LocalType
    associatedtype Device
    init(_ localValue: LocalType, device: Device) async throws
    
}

@available(iOS 13.0.0, *)
public protocol FetchableRemoteType {
    
    associatedtype LocalValue
    func fetch() async throws -> LocalValue
    
}


@available(iOS 13.0.0, *)
public extension CompiledRemoteComputation where Input : InitializableRemoteType, Input.Device == Device, Output : FetchableRemoteType {
    
    func run(input: Input.LocalType) async throws -> Output.LocalValue {
        try await run(input: Input(input, device: device)).fetch()
    }
    
}

@available(iOS 13.0.0, *)
public extension RemoteComputation where Input : InitializableRemoteType, Input.Device == Device, Output : FetchableRemoteType {
    
    func run(on device: Device, input: Input.LocalType) async throws -> Output.LocalValue {
        try await run(on: device, input: Input(input, device: device)).fetch()
    }
    
}
