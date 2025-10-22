# FittingHStack

A lightweight SwiftUI layout that behaves like an `HStack`, but **automatically wraps its child views** onto new lines when there’s not enough horizontal space.
Perfect for tags, chips, buttons, or any horizontally flowing content that needs to adapt gracefully to screen size.

---

## ✨ Features

* 🧩 Drop-in replacement for `HStack`
* 🔄 Automatically wraps to a new line when space runs out
* ⚙️ Customizable `spacing` and `lineSpacing`
* 📱 Works with dynamic type, animations, and layout changes
* 💡 Built using SwiftUI’s modern [`Layout`](https://developer.apple.com/documentation/swiftui/layout) protocol (iOS 16+)

---

## 🚀 Example

```swift
import SwiftUI
import FittingHStack

struct ExampleView: View {
    let tags = ["Swift", "SwiftUI", "Combine", "Async/Await", "Concurrency", "iOS 26", "Layout Protocol"]

    var body: some View {
        FittingHStack(spacing: 10, lineSpacing: 10) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.blue.opacity(0.2)))
            }
        }
        .padding()
    }
}
```

Result:

> Tags are displayed horizontally and wrap neatly into multiple rows when the available width is exceeded.

---

## 📦 Installation

You can copy the `FittingHStack.swift` file directly into your project,
or add it as a Swift Package dependency:

```swift
.package(url: "https://github.com/GlennChiu/FittingHStack.git", from: "1.1.0")
```

Then import it:

```swift
import FittingHStack
```

---

## 🧩 Requirements

* iOS 16.0+ / macOS 13.0+
* Swift 5.7+
* Xcode 14+

---

## 🫶 Credits

Created by [Glenn Chiu](https://github.com/GlennChiu) — inspired by the simplicity of SwiftUI stacks and the flexibility of flow layouts.

---

## 🪪 License

`FittingHStack` is available under the MIT License.
See the [LICENSE](LICENSE) file for more info.
