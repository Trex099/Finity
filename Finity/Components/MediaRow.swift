import SwiftUI

struct MediaRowView: View {
    let row: MediaRow
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 12) {
                Text(row.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal)
                    .accessibility(identifier: "row_title_\(row.title)")
                
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: geometry.size.width * 0.04) {
                        ForEach(row.items) { item in
                            MediaPosterCard(item: item)
                                .frame(width: min(geometry.size.width * 0.3, 150))
                                .accessibility(identifier: "media_card_\(item.id)")
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .frame(height: 270) // Fixed height for consistent row sizing
    }
}

struct MediaRowView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                MediaRowView(row: MediaRow(
                    title: "Action Movies",
                    items: [
                        MediaItem(id: "1", title: "Inception", posterPath: "inception", type: .movie, year: "2010", rating: 8.8, overview: "A thief who steals corporate secrets."),
                        MediaItem(id: "2", title: "The Dark Knight", posterPath: "darkknight", type: .movie, year: "2008", rating: 9.0, overview: "Batman faces his greatest challenge.")
                    ]
                ))
            }
            .previewDevice("iPhone 13 Pro")
            
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                MediaRowView(row: MediaRow(
                    title: "Action Movies",
                    items: [
                        MediaItem(id: "1", title: "Inception", posterPath: "inception", type: .movie, year: "2010", rating: 8.8, overview: "A thief who steals corporate secrets."),
                        MediaItem(id: "2", title: "The Dark Knight", posterPath: "darkknight", type: .movie, year: "2008", rating: 9.0, overview: "Batman faces his greatest challenge.")
                    ]
                ))
            }
            .previewDevice("iPhone SE (3rd generation)")
        }
    }
} 