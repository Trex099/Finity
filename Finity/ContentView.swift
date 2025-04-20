//
//  ContentView.swift
//  Finity
//
//  Created by arsh on 20/04/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        HomeView()
            .preferredColorScheme(.dark)
            .ignoresSafeArea(.keyboard) // Prevent keyboard from causing layout issues
    }
}

#Preview {
    ContentView()
}
