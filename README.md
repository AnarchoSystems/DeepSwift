# DeepSwift

DeepSwift is a Swift library for differentiable programming without compiler magic. The "low level" API to write new differentiable types looks as follows:

```swift

struct Foo : Layer {

    /*
    typealias Input = Float
    typealias Output = Float 
    typealias Adjustment = Float 
    typealias AuxiliaryData = Float
    */
    
    func inspectableApply(_ input: Float) -> (result: Float, auxiliaryData: Float) {
        //...
    }
    
    func adjustment(input: Float, auxiliaryData: Float, gradient: Float) -> (adjustment: Float, backprop: Float) {
        //...
    }
    
    mutating func move(_ adjustment: Float) {
        //...
    }
    
    // optional methods
    
    func apply(_ input: Float) -> Float {
        //...
    }
    
    func auxData(at input: Float) -> Float {
        //...
    }
    
    func backprop(input: Float, auxiliaryData: Float, gradient: Float) -> Float {
        //...
    }
    
}

```

This is really all you need in order to implement backpropagation. Here's what the individual methods do:

- ```inspectableApply``` should produce a "result" which should be equivalent to the ```apply``` method. Additionally, it can produce auxiliary data. In case of a loss function, this should be the derivative so we can feed it into backpropagation. In all other cases, auxiliary data should be considered a layer-internal type that nobody except the layer itself cares about.
- ```adjustment``` is called after you produced a result using inspectableApply and you got feedback on how "good" your output was. This feedback is expressed as the parameter called ```gradient```, and you can think of it as a requested change to the output you delivered. The job of the ```adjustment``` method is to translate this change to the output to a change of this layer and the input to this layer. Intuitively, you need to estimate here how much a small change in the input or in the layer parameters would have changed the output - and then compare that to the requested change in the output. Often, one can work out a reasonable mathematical answer for that using tools with intimidating names like "calculus" or "derivative".
- ```move``` is is responsible for actually carrying out the change.

The other methods have default implementations, but I recommend to implement at least ```backprop``` so you get a speedup when freezing this layer.

Note: The ```Layer```protocol requires ```Input``` and ```Output``` to conform to ```Movable``` - that is, they have to provide a ```move``` method too. The ```gradient``` in ```adjustment```/```backprop``` will be of type ```Output.Adjustment```, and the returned ```backprop``` value will have type ```Input.Adjustment```.

And here's how the three mandatory methods work together:

```swift

extension Layer {
    
    mutating func learn<Loss : Layer>(examples: Input, loss: Loss)  where
    Loss.Adjustment == Void,
          Loss.AuxiliaryData == Output.Adjustment,
          Loss.Input == Output {
              let (result, derivative) = inspectableApply(examples)
              let (adjustment, _) = adjustment(input: examples, auxiliaryData: derivative, gradient: loss.auxData(at: result))
              move(adjustment)
          }
          
}
```

If you want to implement pure layers, there's a ```Function``` protocol that will not ask you to implement a ```move``` method.

For optimizers, the current approach is to inject them locally. You can annotate parameters of your model with ```@Optimizable``` in order to indicate that you want adjustments to this parameter to be intercepted.

While DeepSwift leaves the design of concrete layers and optimizers and the implementation of efficient numerics to other (downstream) repos, DeepSwift provides the high level API that you need so you can write:

```swift
struct MyModel : Learner {

   var body = SomeLayer() |> SomeOtherLayer() |> ThirdLayer()

} 
```
