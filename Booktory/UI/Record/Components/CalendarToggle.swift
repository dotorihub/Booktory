//
//  CalendarToggle.swift
//  Booktory
//
//  위클리/먼슬리 달력 모드 토글.
//

import SwiftUI

struct CalendarToggle: View {
    @Binding var mode: RecordTabViewModel.CalendarMode

    var body: some View {
        Picker("달력 모드", selection: $mode) {
            Text("위클리").tag(RecordTabViewModel.CalendarMode.weekly)
            Text("먼슬리").tag(RecordTabViewModel.CalendarMode.monthly)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }
}

#Preview {
    CalendarToggle(mode: .constant(.weekly))
}
