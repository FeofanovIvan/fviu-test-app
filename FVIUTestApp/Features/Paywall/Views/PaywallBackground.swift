import SwiftUI

struct PaywallBackground: View {
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height

            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.116, green: 0.113, blue: 0.181),
                        Color(red: 0.082, green: 0.046, blue: 0.079),
                        Color(red: 0.043, green: 0.027, blue: 0.055),
                        Color(red: 0.006, green: 0.004, blue: 0.009)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: width, height: height)

                LinearGradient(
                    colors: [
                        Color(red: 0.596, green: 0.776, blue: 0.969),
                        Color(red: 0.922, green: 0.357, blue: 0.573)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: width * 1.6, height: height * 0.26)
                .opacity(0.42)
                .rotationEffect(.degrees(-18.36))
                .blur(radius: 108)
                .offset(x: width * 0.13, y: -height * 0.37)

                Color(red: 0.043, green: 0.027, blue: 0.055)
                    .frame(width: width * 0.6, height: height * 0.45)
                    .rotationEffect(.degrees(-89.27))
                    .blur(radius: 108)
                    .offset(x: -width * 0.38, y: -height * 0.09)

                Color(red: 0.043, green: 0.027, blue: 0.055)
                    .frame(width: width * 0.6, height: height * 0.37)
                    .rotationEffect(.degrees(-89.27))
                    .blur(radius: 108)
                    .offset(x: width * 0.39, y: -height * 0.05)
            }
            .frame(width: width, height: height)
            .clipped()
        }
        .ignoresSafeArea()
    }
}
