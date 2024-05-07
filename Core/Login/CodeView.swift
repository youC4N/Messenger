//
//  CodeView.swift
//  Messenger
//
//  Created by Егор Малыгин on 06.05.2024.
//

import SwiftUI

struct CodeView: View {
    @State var input = ""
    var onLoginComplete: () -> Void

    var body: some View {
        VStack {
            Text("Enter the code")
            HStack {
                ZStack {
                    TextField("", text: $input)
                        .frame(minWidth: 80, minHeight: 47)
                    //                        .background(, in: RoundedRectangle(cornerRadius: 10))
                }
            }

            Button(action: onLoginComplete) {
                Text("Next")
                    .frame(maxWidth: .infinity, minHeight: 47)
                    .background(
                        .secondary,
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .navigationTitle("Authorization")
    }

}

#Preview {
    NavigationStack {
        CodeView(onLoginComplete: {})
    }
}
