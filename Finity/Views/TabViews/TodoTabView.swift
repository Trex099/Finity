import SwiftUI

struct TodoTabView: View {
    var body: some View {
        TodoView()
            .navigationBarHidden(true)
    }
}

struct TodoTabView_Previews: PreviewProvider {
    static var previews: some View {
        TodoTabView()
    }
} 