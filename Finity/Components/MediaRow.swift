import SwiftUI

struct MediaRowView: View {
    let row: MediaRow
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(row.title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(row.items) { item in
                        MediaPosterCard(item: item)
                            .padding(.vertical, 4)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
    }
}

struct MediaRowView_Previews: PreviewProvider {
    static var previews: some View {
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
    }
} 