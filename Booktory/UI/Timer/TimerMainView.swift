//
//  TimerMainView.swift
//  Booktory
//
//  Created by 김지현 on 2/9/26.
//

import SwiftUI

struct TimerMainView: View {
    @State private var isPresentingTimerView: Bool = false
    
    var body: some View {
        ZStack {
            Color.paperGray
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(Date().formatted())
                    Text("Reading Now")
                        .font(.largeTitle.bold())
                }
                .padding(.top, 20)
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 24) {
                    Image(systemName: "book")
                        .resizable()
                        .frame(width: 32, height: 32)
                        .padding(24)
                    Text("Start Your Journey")
                        .font(.title2.bold())
                    Text("Track your reading, take notes, and build a lasting habit with Bookly.")
                        .multilineTextAlignment(.center)
                    
                    Button {
                        self.isPresentingTimerView = true
                    } label: {
                     Text("Find a Book")
                            .font(.title3.bold())
                            .padding()
                            .foregroundStyle(.white)
                            .background(.black)
                            .cornerRadius(24)
                    }
                    .padding(.vertical, 12)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(
                            color: Color.black.opacity(0.1),
                            radius: 6,
                        )
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .fullScreenCover(isPresented: $isPresentingTimerView) {
            TimerView()
        }
    }
}

#Preview {
    TimerMainView()
}
