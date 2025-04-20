import SwiftUI

struct TopTitleBar: View {
    var body: some View {
        GeometryReader { geometry in
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
            }
            .padding(.horizontal, min(20, geometry.size.width * 0.05))
            .frame(width: geometry.size.width, height: 60)
            .background(Color.black)
        }
        .frame(height: 60)
    }
}

struct TopTitleBar_Previews: PreviewProvider {
    static var previews: some View {
        TopTitleBar()
            .preferredColorScheme(.dark)
            .previewLayout(.sizeThatFits)
    }
} 