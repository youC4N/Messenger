import SwiftUI

struct ContactCardView: View {
    @State var userName: String
    var body: some View {
        NavigationLink(destination: MainVideoPlayerView()) {
            HStack {
                Image(systemName: "person")
                    .resizable()
                    .frame(width: 48, height: 48)
                    .aspectRatio(1, contentMode: .fit)
                    .foregroundColor(.primary)
                Spacer()

                Text(userName)
                    .fontWeight(.bold)
                    .font(.system(size: 500))
                    .minimumScaleFactor(0.01)
                    .foregroundStyle(.black)
                Spacer()

            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: 94)
            .background(.clear,in: RoundedRectangle(cornerRadius: 10))

        }
    }
}

#Preview {
    ContactCardView(userName: "Yaroslave")
}
