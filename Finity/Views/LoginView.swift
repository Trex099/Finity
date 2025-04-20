import SwiftUI

struct LoginView: View {
    @State private var serverURL = ""
    @State private var username = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    // Placeholder for authentication logic - will connect to JellyfinService later
    var onAuthenticated: () -> Void

    var body: some View {
        NavigationView { // Use NavigationView for the title
            ZStack {
                // Background color to match the app theme
                Color.black.edgesIgnoringSafeArea(.all)

                VStack(spacing: 20) {
                    Spacer()

                    Text("FINITY")
                         .font(.system(size: 48, weight: .bold))
                         .foregroundStyle(
                             LinearGradient(
                                 colors: [.white, .gray.opacity(0.7), .white.opacity(0.9)],
                                 startPoint: .topLeading,
                                 endPoint: .bottomTrailing
                             )
                         )
                         .shadow(color: .white.opacity(0.5), radius: 1, x: 0, y: 1)
                         .padding(.bottom, 40)


                    // Server URL Input
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Server URL")
                            .foregroundColor(.gray)
                            .font(.caption)
                        TextField("https://your-jellyfin-server.com", text: $serverURL)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .keyboardType(.URL)
                    }

                    // Username Input
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Username")
                            .foregroundColor(.gray)
                            .font(.caption)
                        TextField("Username", text: $username)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }

                    // Password Input
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Password")
                            .foregroundColor(.gray)
                            .font(.caption)
                        SecureField("Password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    // Error Message Display
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.top, 5)
                    }

                    // Login Button
                    Button(action: performLogin) {
                        HStack {
                            Spacer()
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black)) // Dark tint for contrast
                            } else {
                                Text("Connect")
                                    .fontWeight(.bold)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(8)
                    }
                    .disabled(isLoading || serverURL.isEmpty || username.isEmpty || password.isEmpty)
                    .opacity((isLoading || serverURL.isEmpty || username.isEmpty || password.isEmpty) ? 0.6 : 1.0) // Indicate disabled state
                    .padding(.top, 20)

                    Spacer()
                    Spacer() // Add more space at the bottom
                }
                .padding(.horizontal, 30) // Add horizontal padding
            }
            .navigationBarHidden(true) // Hide the default navigation bar
        }
        .preferredColorScheme(.dark) // Ensure dark mode appearance
    }

    func performLogin() {
        isLoading = true
        errorMessage = nil
        print("Attempting login with URL: \(serverURL), User: \(username)")

        // ** TODO: **
        // 1. Validate Server URL format (basic check)
        // 2. Instantiate or access JellyfinService
        // 3. Call JellyfinService.authenticate(url: serverURL, username: username, password: password)
        // 4. Handle success: Save credentials/token securely, call onAuthenticated()
        // 5. Handle failure: Set errorMessage

        // Placeholder logic for now
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Simulate success/failure
            let success = true // Change to false to test error
            if success {
                print("Login Successful (Placeholder)")
                // Securely store credentials/token here (e.g., Keychain)
                onAuthenticated()
            } else {
                print("Login Failed (Placeholder)")
                errorMessage = "Could not connect to server. Check URL, username, and password."
            }
            isLoading = false
        }
    }
}

// Preview Provider
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(onAuthenticated: { print("Authenticated!") })
    }
} 