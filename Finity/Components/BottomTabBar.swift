import SwiftUI

enum TabItem: String, CaseIterable {
    case home = "Home"
    case favorites = "Favorites"
    case settings = "Settings"
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .favorites: return "heart.fill"
        case .settings: return "gear"
        }
    }
}

struct BottomTabBar: View {
    @Binding var selectedTab: TabItem
    let contentAreaHeight: CGFloat = 50 // Height for the actual icons/text area

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TabItem.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 22))
                            .foregroundColor(selectedTab == tab ? .white : .gray)
                        
                        Text(tab.rawValue)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(selectedTab == tab ? .white : .gray)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: contentAreaHeight)
                }
                .accessibility(identifier: "tab_\(tab.rawValue)")
            }
        }
        .frame(height: contentAreaHeight) // Set the fixed height for the content HStack
        .background(BlurView(style: .systemMaterialDark)) // Apply background ONLY to the content area
    }
}

struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView { UIVisualEffectView(effect: UIBlurEffect(style: style)) }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) { uiView.effect = UIBlurEffect(style: style) }
}

struct BottomTabBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            BottomTabBar(selectedTab: .constant(.home))
                 // Preview container simulates safe area
                .padding(.bottom, 34)
        }
        .background(Color.gray)
        .edgesIgnoringSafeArea(.all)
        .preferredColorScheme(.dark)
    }
}