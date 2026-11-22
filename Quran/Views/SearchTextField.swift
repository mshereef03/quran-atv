import SwiftUI
import UIKit

/// A text field with tvOS's default focus halo and background chrome fully suppressed, so
/// `SearchView`'s own Capsule + accent-ring styling is the only visible focus indicator
/// instead of fighting a mismatched system-drawn shape. Once the user actually presses
/// select to start typing, tvOS still takes over with its own full-screen keyboard — that
/// part is OS-level presentation and isn't reachable from any app.
struct SearchTextField: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool
    var placeholder: String
    var fontSize: CGFloat

    final class NoHaloTextField: UITextField {
        var onFocusChange: ((Bool) -> Void)?

        override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
            super.didUpdateFocus(in: context, with: coordinator)
            onFocusChange?(context.nextFocusedView === self)
        }
    }

    func makeUIView(context: Context) -> UITextField {
        let field = NoHaloTextField()
        field.delegate = context.coordinator
        field.borderStyle = .none
        field.backgroundColor = .clear
        field.font = .systemFont(ofSize: fontSize)
        field.textColor = .white
        field.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.5)]
        )
        field.addTarget(context.coordinator, action: #selector(Coordinator.textChanged(_:)), for: .editingChanged)
        field.onFocusChange = { focused in
            isFocused = focused
        }
        return field
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, isFocused: $isFocused)
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        let text: Binding<String>
        let isFocused: Binding<Bool>

        init(text: Binding<String>, isFocused: Binding<Bool>) {
            self.text = text
            self.isFocused = isFocused
        }

        @objc func textChanged(_ sender: UITextField) {
            text.wrappedValue = sender.text ?? ""
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            isFocused.wrappedValue = true
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            isFocused.wrappedValue = false
        }
    }
}
