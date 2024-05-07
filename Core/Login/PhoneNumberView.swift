//
//  PhoneNumberView.swift
//  Messenger
//
//  Created by Егор Малыгин on 30.04.2024.
//

import Algorithms
import Combine
import SwiftUI

struct PhoneNumberView: View {
    

    @State var presentSheet = false
    @State var countryCode: String = "+380"
    @State var countryFlag: String = "🇺🇦"
    @State var countryPattern: String = "### ### ####"
    @State var countryLimit: Int = 17
    @State var mobPhoneNumber = ""
    var onLoginComplete: () -> Void
    
    @State private var searchCountry: String = ""
    @Environment(\.colorScheme) var colorScheme
    @FocusState private var keyIsFocused: Bool
    
//        let formatedPhoneNumber = Binding(
//            get: {
//                Array(
//                    self.mobPhoneNumber
//                        .chunks(ofCount: 3)
//                )
//                .joined(separator: " ")
//            }, set: { self.mobPhoneNumber = $0.replacingOccurrences(of: " ", with: "") })
    
    func applyPatternOnNumbers(_ stringvar: inout String, pattern: String, replacementCharacter: Character) {
            var pureNumber = stringvar.replacingOccurrences( of: "[^0-9]", with: "", options: .regularExpression)
            for index in 0 ..< pattern.count {
                guard index < pureNumber.count else {
                    stringvar = pureNumber
                    return
                }
                let stringIndex = String.Index(utf16Offset: index, in: pattern)
                let patternCharacter = pattern[stringIndex]
                guard patternCharacter != replacementCharacter else { continue }
                pureNumber.insert(patternCharacter, at: stringIndex)
            }
            stringvar = pureNumber
        }

    var body: some View {
        VStack(spacing: 10) {
            Text("Confirm country code and enter phone number")

                .font(.title)
                .padding(.bottom, 20)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Button(
                    action: {},
                    label: {
                        Text("\(countryFlag) \(countryCode)")
                            .padding(10)
                            .frame(minWidth: 80, minHeight: 47)
                            .background(
                                .secondary,
                                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                            )
                            .foregroundColor(.black)
                    })
                TextField("", text: $mobPhoneNumber)
                    .padding(.leading, 10)
                    .frame(minWidth: 80, minHeight: 47)
                    .background(
                        .secondary, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .onReceive(Just(mobPhoneNumber)){ _ in foo(&mobPhoneNumber)
                        
                    }

            }

            NavigationLink(destination: CodeView(onLoginComplete: onLoginComplete)) {
//            Button(action: onLoginComplete) {
                Text("Next")
                    .frame(maxWidth: .infinity, minHeight: 47)
                    .background(
                        .secondary,
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            

        }
        
        .navigationTitle("Login")
        .padding(.horizontal)
        .padding(.bottom, 80)
        
    }

}

//#Preview("with navigation") {
//    
//    NavigationStack {
//        
//        PhoneNumberView()
//    }
//
//}
//
//#Preview(traits: .sizeThatFitsLayout) {
//
//    PhoneNumberView()
//
//}

#Preview{
    PhoneNumberView(onLoginComplete: {})
}
