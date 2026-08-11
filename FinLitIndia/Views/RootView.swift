import SwiftUI

let brandGreen = Color(red: 0.345, green: 0.800, blue: 0.008)

struct RootView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        Group {
            if session.isBootstrapping {
                ZStack {
                    Color.white.ignoresSafeArea()
                    ProgressView().tint(brandGreen)
                }
            } else if session.isRegistered {
                MainTabView()
            } else {
                RegistrationView()
            }
        }
        .task {
            await session.bootstrap()
        }
    }
}
