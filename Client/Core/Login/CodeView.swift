//
//  CodeView.swift
//  Messenger
//
//  Created by Егор Малыгин on 06.05.2024.
//

import SwiftUI

struct CodeView: View {
    @State var code = ""
    var onLoginComplete: () -> Void
    @State private var nextView = false
    func validate(_ code: String) -> Bool {
        // TODO: validate the code
        return false
    }
    var body: some View {
        VStack {
            Text("Enter the code")
            HStack {
                ZStack {

                    TextField("", text: $code)
                        .padding(.leading, 10)
                        .frame(maxWidth: 160, minHeight: 47)
                        .background(.secondary, in: RoundedRectangle(cornerRadius: 10))
                        .autocorrectionDisabled(true)
                }
            }

            Button(
                action: {
                    if validate(code) {
                        onLoginComplete()
                    } else {
                        nextView = true
                    }
                },
                label: {
                    Text("Next")
                        .frame(maxWidth: .infinity, minHeight: 47)
                        .background(
                            .secondary,
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                })
            .navigationDestination(isPresented: $nextView) {
                Registration(onLoginComplete: onLoginComplete)
            }
        }
        .padding()
        .navigationTitle("Authorization")
    }

}

#Preview {
    NavigationStack {
        CodeView(onLoginComplete: {})
    }
}
