import OSLog
import SwiftUI

struct PhoneNumberView: View {

    var countryCode = "+380"
    var countryFlag = "🇺🇦"
    @State var phoneNumber = ""
    var onLoginComplete: () -> Void


    var body: some View {
        VStack(spacing: 10) {
            Text("Confirm country code and enter phone number")
                .font(.title)
                .padding(.bottom, 20)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Button(action: {}) {
                    Text("\(countryFlag) \(countryCode)")
                        .padding(10)
                        .frame(minWidth: 80, minHeight: 48)
                        .background(
                            .secondary,
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                        )
                        .foregroundColor(.black)
                }
                PhoneNumberField(text: $phoneNumber)
                    .padding(.leading, 10)
                    .frame(minWidth: 80, maxHeight: 48)
                    .background(
                        .secondary, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            NavigationLink(destination: CodeView(onLoginComplete: onLoginComplete)) {
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

#Preview {
    NavigationStack {
        PhoneNumberView(onLoginComplete: {})
    }
}
