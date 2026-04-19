import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var hugVM: HugViewModel

    @State private var showAuth = false

    var body: some View {
        Group {
            if !authVM.isSignedIn {
                if showAuth {
                    AuthView()
                } else {
                    OnboardingView(showAuth: $showAuth)
                }
            } else if authVM.currentUser?.coupleId == nil {
                PairingView()
            } else {
                HomeView()
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.72), value: authVM.isSignedIn)
        .animation(.spring(response: 0.45, dampingFraction: 0.72), value: authVM.currentUser?.coupleId)
    }
}
