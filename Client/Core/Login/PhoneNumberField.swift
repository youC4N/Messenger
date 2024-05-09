import OSLog
import SwiftUI

let chunks = [2, 3, 2, 2]
let maxFormattedLength = chunks.reduce(0, +)
func formatPhoneNumber(_ input: String) -> String {
    if input.isEmpty {
        return input
    } else if input.count <= maxFormattedLength {
        var result = ""
        var chunkStart = input.startIndex
        for chunkLength in chunks {
            if let chunkEnd = input.index(
                chunkStart,
                offsetBy: chunkLength,
                limitedBy: input.endIndex
            ), chunkEnd != input.endIndex {
                result += input[chunkStart..<chunkEnd]
                result += " "
                chunkStart = chunkEnd
            } else {
                result += input[chunkStart...]
                break
            }
        }
        return result
    } else {
        return input
    }
}

struct PhoneNumberField: UIViewRepresentable {
    var text: Binding<String>

    func makeCoordinator() -> Coordinator {
        Coordinator(binding: text)
    }

    func makeUIView(context: Context) -> UITextField {
        let view = UITextField(frame: .zero)
        view.text = formatPhoneNumber(text.wrappedValue)
        view.keyboardType = .phonePad
        view.textContentType = .telephoneNumber
        context.coordinator.setup(view)
        return view
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = formatPhoneNumber(text.wrappedValue)
    }

    typealias UIViewType = UITextField

    class Coordinator: NSObject, UITextFieldDelegate {
        var binding: Binding<String>

        init(binding: Binding<String>) {
            self.binding = binding
        }

        func setup(_ view: UITextField) {
            view.delegate = self
            view.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        }

        @objc func textFieldDidChange(_ view: UITextField) {
            guard var text = view.text else {
                binding.wrappedValue = ""
                return
            }
            if let countryCodeMatch = text.firstMatch(of: #/^\+?380/#) {
                text.removeSubrange(countryCodeMatch.range)
                text.replace(#/[ ()]/#, with: "")
            } else {
                text.replace(" ", with: "")
            }
            binding.wrappedValue = text
        }
    }
}
