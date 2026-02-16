//
//  CallButton.swift
//  habla-ios
//

import SwiftUI

struct CallButton: View {
    let isActive: Bool
    let isEndCall: Bool
    let action: () -> Void

    init(isActive: Bool = true, isEndCall: Bool = false, action: @escaping () -> Void) {
        self.isActive = isActive
        self.isEndCall = isEndCall
        self.action = action
    }

    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action()
        }) {
            Image(systemName: isEndCall ? "phone.down.fill" : "phone.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 72, height: 72)
                .background(
                    Circle()
                        .fill(isEndCall ? Color.appDestructive : Color.appAccent)
                )
                .scaleEffect(isActive ? 1.0 : 0.9)
                .opacity(isActive ? 1.0 : 0.5)
        }
        .disabled(!isActive)
        .animation(.easeInOut(duration: 0.15), value: isActive)
    }
}
