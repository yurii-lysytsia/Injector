# Swift Injector with Xcode Macros
This project provides a lightweight dependency injection framework for Swift iOS projects built on Xcode macros. It simplifies dependency management by enabling you to mark classes with injectable properties and configure the Injector to resolve them during object creation.

# Installation (SPM)

```swift
.package(url: "https://github.com/yurii-lysytsia/Injector.git", .upToNextMajor(from: "1.0.0"))
```

# Usage

1. Mark classes with injectable properties using the `@Injectable` macro. This macro informs the Injector about classes that participate in dependency injection.

```swift
@Injectable
class MyClass { ... }
```

2. Mark properties within the classes as injectable using the `@Injected` macro. The Injector will resolve dependencies and inject them during object creation.

```swift
@Injected var string: String
```

3. Example

```swift
@Injectable(access: .internal, superInit: "value: true", useSetup: true)
public class MyClass: MySuperClass {
    @Injected(name: "customStringName") var string: String
    @Injected var closure: () -> String
    @Injected(escaping: true) var closureTypealias: StringClosure // where, StringClosure is `typealias StringClosure = () -> String`

    private func setup() { ... }

    // Code generated by macro ->
    init(
      customStringName: String, // `name` is `customStringName`
      closure: @escaping () -> String,
      closureTypealias: @escaping StringClosure // `escaping` is `true`
    ) {
      self.string = customStringName
      self.closure = closure
      self.closureTypealias = closureTypealias
      super.init(value: true) // `superInit` value isn't `nil`
      setup() // `useSetup` is `true`
    }
    // <-
}
```

# License

This project is distributed under the MIT License (see LICENSE file).
