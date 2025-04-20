import SwiftUI

struct TopTitleBar: View {
    @Binding var showSearchView: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background for visual separation
                Color.black
                    .edgesIgnoringSafeArea(.top)
                
                HStack {
                    // Metallic FINITY logo
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
                    
                    Spacer()
                    
                    // Search Icon Button
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
                .padding(.horizontal, min(20, geometry.size.width * 0.05))
            }
            .frame(width: geometry.size.width, height: 60)
        }
        .frame(height: 60)
    }
}

struct TopTitleBar_Previews: PreviewProvider {
    static var previews: some View {
        TopTitleBar(showSearchView: .constant(false))
            .preferredColorScheme(.dark)
            .previewLayout(.sizeThatFits)
            .background(Color.gray) // Add background for preview context
    }
} 