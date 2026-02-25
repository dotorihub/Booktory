//
//  SearchView.swift
//  Booktory
//
//  Created by 김지현 on 2/25/26.
//

import SwiftUI

struct SearchView: View {
    @State private var searchText: String = ""
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        VStack {
            VStack {
                Text("Search")
                    .font(.largeTitle.bold())
                    .padding(.top, 20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Styled search field
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    
                    TextField("Books, Authors...", text: $searchText)
                        .textInputAutocapitalization(.none)
                        .disableAutocorrection(true)
                        .focused($isSearchFocused)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.systemGray6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isSearchFocused ? Color.accentColor : Color.clear, lineWidth: 1.5)
                )
                .animation(.easeInOut(duration: 0.15), value: isSearchFocused)
            }
            .padding(.horizontal, 24)
            
            ScrollView {
                GuideView
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    var GuideView: some View {
        VStack {
            Image(systemName: "magnifyingglass")
                .resizable()
                .frame(width: 32, height: 32)
                .foregroundStyle(.gray)
                .padding(24)
            
            Text("Search for your favorite books to add them to your library.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.gray)
                .padding()
        }
        .frame(height: 300, alignment: .center)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(
                    color: Color.black.opacity(0.1),
                    radius: 6
                )
        )
        .padding(.horizontal, 16)
        .padding(.top, 20)
    }
}

#Preview {
    SearchView()
}
