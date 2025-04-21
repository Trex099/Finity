import SwiftUI

struct MediaRowView: View {
    let row: MediaRow

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 12) {
                if !row.title.isEmpty {
                    Text(row.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .accessibility(identifier: "row_title_\(row.title)")
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: geometry.size.width * 0.04) {
                        ForEach(row.items) { item in
                            NavigationLink(value: item) {
                                MediaPosterCard(item: item)
                                    .frame(width: min(geometry.size.width * 0.3, 150))
                                    .accessibility(identifier: "media_card_\(item.id)")
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .frame(height: row.title.isEmpty ? 240 : 270)
    }
}

struct MediaRowView_Previews: PreviewProvider {
    static let previewItems: [MediaItem] = [
        MediaItem(
            id: "1", name: "Inception", serverId: nil, type: "Movie", 
            overview: "A thief who steals corporate secrets.", productionYear: 2010, 
            communityRating: 8.8, officialRating: "PG-13", 
            imageTags: ["Primary": "inceptionTag"], backdropImageTags: [], 
            userData: nil, genres: ["Action", "Sci-Fi"], runTimeTicks: 72000000000,
            indexNumber: nil, parentIndexNumber: nil, seriesName: nil
        ),
        MediaItem(
            id: "2", name: "The Dark Knight", serverId: nil, type: "Movie", 
            overview: "Batman faces his greatest challenge.", productionYear: 2008, 
            communityRating: 9.0, officialRating: "PG-13", 
            imageTags: ["Primary": "darkknightTag"], backdropImageTags: [], 
            userData: nil, genres: ["Action", "Drama"], runTimeTicks: nil,
            indexNumber: nil, parentIndexNumber: nil, seriesName: nil
        )
    ]
    
    static let previewRow = MediaRow(
        title: "Action Movies",
        items: previewItems
    )
    
    static var previews: some View {
        Group {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                MediaRowView(row: previewRow)
            }
            .previewDevice("iPhone 13 Pro")
            .environmentObject(JellyfinService())
            
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                MediaRowView(row: previewRow)
            }
            .previewDevice("iPhone SE (3rd generation)")
            .environmentObject(JellyfinService())
        }
        .preferredColorScheme(.dark)
    }
} 