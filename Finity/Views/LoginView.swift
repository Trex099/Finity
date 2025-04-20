import SwiftUI

struct LoginView: View {
    // Observe the shared JellyfinService instance
    @ObservedObject var jellyfinService: JellyfinService
    
    @State private var serverURL = ""
    @State private var username = ""
    @State private var password = ""
    // isLoading and errorMessage are now sourced from jellyfinService
    // @State private var isLoading = false
    // @State private var errorMessage: String?

    // Remove the callback, authentication state is handled by observing jellyfinService
    // var onAuthenticated: () -> Void

    var body: some View {
        // Assign the service property to a local constant
        let isCurrentlyLoading = jellyfinService.isLoadingAuth // Use the renamed property
        
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
                            // Prefill from service if available (e.g., loaded from Keychain)
                            .onAppear {
                                if let savedURL = jellyfinService.serverURL {
                                    serverURL = savedURL
                                }
                            }
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

                    // Error Message Display (from service)
                    if let error = jellyfinService.errorMessage {
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
                            // Use the local constant
                            if isCurrentlyLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
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
                    // Disable based on local constant and input fields
                    .disabled(isCurrentlyLoading || serverURL.isEmpty || username.isEmpty || password.isEmpty)
                    .opacity((isCurrentlyLoading || serverURL.isEmpty || username.isEmpty || password.isEmpty) ? 0.6 : 1.0)
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
        // No need to manage isLoading or errorMessage locally
        // isLoading = true
        // errorMessage = nil
        print("Attempting login via JellyfinService with URL: \(serverURL), User: \(username)")
        
        // Call the authentication method on the service
        jellyfinService.authenticate(serverURL: serverURL, username: username, password: password)
        
        // The service will publish changes to isLoading, errorMessage, and isAuthenticated,
        // which will automatically update this view and ContentView.
        
        // Remove placeholder logic
        /*
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let success = true
            if success {
                print("Login Successful (Placeholder)")
                // Securely store credentials/token here (e.g., Keychain)
                // onAuthenticated()
            } else {
                print("Login Failed (Placeholder)")
                errorMessage = "Could not connect to server. Check URL, username, and password."
            }
            isLoading = false
        }
        */
    }
}

// Preview Provider
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        // Provide a mock service for the preview
        LoginView(jellyfinService: JellyfinService())
    }
} 