import SwiftUI

struct SettingsView: View {
    @State private var isNotificationsEnabled = true
    @State private var isAutoPlayEnabled = true
    @State private var preferredQuality = "Auto"
    @State private var username = "User"
    
    private let qualityOptions = ["Auto", "Low", "Medium", "High", "Ultra HD"]
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top metallic title
                TopTitleBar()
                    .padding(.top, geometry.safeAreaInsets.top)
                
                // Header
                HStack {
                    Text("Settings")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                // Settings list
                ScrollView {
                    VStack(spacing: 24) {
                        // Account section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("ACCOUNT")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.leading, 16)
                            
                            VStack(spacing: 1) {
                                Button(action: {}) {
                                    HStack {
                                        Image(systemName: "person.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.white)
                                        
                                        Text(username)
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                    }
                                    .padding(16)
                                    .background(Color.gray.opacity(0.2))
                                }
                                
                                Button(action: {}) {
                                    HStack {
                                        Image(systemName: "arrow.right.square")
                                            .font(.title2)
                                            .foregroundColor(.white)
                                        
                                        Text("Sign Out")
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                    }
                                    .padding(16)
                                    .background(Color.gray.opacity(0.2))
                                }
                            }
                            .cornerRadius(8)
                        }
                        
                        // Preferences section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("PREFERENCES")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.leading, 16)
                            
                            VStack(spacing: 1) {
                                Toggle(isOn: $isNotificationsEnabled) {
                                    HStack {
                                        Image(systemName: "bell.fill")
                                            .font(.title2)
                                            .foregroundColor(.white)
                                        
                                        Text("Notifications")
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding(16)
                                .background(Color.gray.opacity(0.2))
                                
                                Toggle(isOn: $isAutoPlayEnabled) {
                                    HStack {
                                        Image(systemName: "play.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.white)
                                        
                                        Text("Auto-play next episode")
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding(16)
                                .background(Color.gray.opacity(0.2))
                                
                                HStack {
                                    Image(systemName: "dial.high")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                    
                                    Text("Preferred Quality")
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Picker("Quality", selection: $preferredQuality) {
                                        ForEach(qualityOptions, id: \.self) {
                                            Text($0)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    .accentColor(.white)
                                }
                                .padding(16)
                                .background(Color.gray.opacity(0.2))
                            }
                            .cornerRadius(8)
                        }
                        
                        // About section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("ABOUT")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.leading, 16)
                            
                            VStack(spacing: 1) {
                                Button(action: {}) {
                                    HStack {
                                        Image(systemName: "doc.text.fill")
                                            .font(.title2)
                                            .foregroundColor(.white)
                                        
                                        Text("Terms of Service")
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                    }
                                    .padding(16)
                                    .background(Color.gray.opacity(0.2))
                                }
                                
                                Button(action: {}) {
                                    HStack {
                                        Image(systemName: "lock.fill")
                                            .font(.title2)
                                            .foregroundColor(.white)
                                        
                                        Text("Privacy Policy")
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                    }
                                    .padding(16)
                                    .background(Color.gray.opacity(0.2))
                                }
                                
                                HStack {
                                    Image(systemName: "info.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                    
                                    Text("Version")
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Text("1.0.0")
                                        .foregroundColor(.gray)
                                }
                                .padding(16)
                                .background(Color.gray.opacity(0.2))
                            }
                            .cornerRadius(8)
                        }
                        
                        Spacer(minLength: geometry.safeAreaInsets.bottom + 70)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .preferredColorScheme(.dark)
    }
} 