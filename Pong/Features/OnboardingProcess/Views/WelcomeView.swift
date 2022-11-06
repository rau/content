import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var onboardingVM : OnboardingViewModel
    
    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("Connect with your college community, anonymously.")
                    .font(.title).bold()
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                Image("OnboardSchoolImage")
                    .resizable()
                    .scaledToFit()
                    .frame(width: UIScreen.screenWidth / 1.1)
                
                Spacer()
                
                Text("By using Pong, you understand and agree to our [Terms of Service](https://www.pong.blog/legal) and [Privacy Policy](https://www.pong.blog/legal)")
                    .accentColor(Color.pongAccent)

            }
            .padding(15)
        }
        .background(Color.pongSystemBackground)
        .padding()
        .padding(.bottom, 20)
    }
}
