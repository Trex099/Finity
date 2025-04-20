import SwiftUI

struct TopTitleBar: View {
    @Binding var showSearchView: Bool
    var title: String? = nil // Optional custom title
    var showLogo: Bool = true
    var showSearchIcon: Bool = true
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background back to black
                Color.black
                    .edgesIgnoringSafeArea(.top)
                
                HStack {
                    // Conditional FINITY Logo or Custom Title
                    if let customTitle = title {
                        Text(customTitle)
                            .font(.system(size: min(30, geometry.size.width * 0.07), weight: .bold))
                            .foregroundColor(.white)
                            .accessibility(identifier: "page_title")
                    } else if showLogo {
                        Text("FINITY")
                            .font(.system(size: min(36, geometry.size.width * 0.08), weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .gray.opacity(0.7), .white.opacity(0.9)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .white.opacity(0.5), radius: 1, x: 0, y: 1)
                            .accessibility(identifier: "finity_logo")
                    }
                    
                    Spacer()
                    
                    // Conditional Search Icon Button
                    if showSearchIcon {
                        Button(action: {
                            showSearchView = true
                        }) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                        }
                        .accessibility(identifier: "top_search_button")
                    }
                }
                .padding(.horizontal, min(20, geometry.size.width * 0.05))
            }
            .frame(width: geometry.size.width, height: 60)
        }
        .frame(height: 60)
    }
}

// Simple Blur View using UIVisualEffectView (Keep for Bottom Bar)
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

struct TopTitleBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            // Preview: Home style
            TopTitleBar(showSearchView: .constant(false), showLogo: true, showSearchIcon: true)
            
            // Preview: Favorites style
            TopTitleBar(showSearchView: .constant(false), title: "My Favorites", showLogo: false, showSearchIcon: true)
            
            // Preview: Settings style
            TopTitleBar(showSearchView: .constant(false), title: "Settings", showLogo: false, showSearchIcon: false)
        }
        .preferredColorScheme(.dark)
        .previewLayout(.sizeThatFits)
    }
} 