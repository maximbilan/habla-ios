//
//  CallButton.swift
//  habla-ios
//

import SwiftUI

struct CallButton: View {
    let isActive: Bool
    let isEndCall: Bool
    let size: CGFloat
    let iconSize: CGFloat
    let action: () -> Void

    init(
        isActive: Bool = true,
        isEndCall: Bool = false,
        size: CGFloat = 72,
        iconSize: CGFloat = 28,
        action: @escaping () -> Void
    ) {
        self.isActive = isActive
        self.isEndCall = isEndCall
        self.size = size
        self.iconSize = iconSize
        self.action = action
    }

    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action()
        }) {
            Image(systemName: isEndCall ? "phone.down.fill" : "phone.fill")
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: size, height: size)
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
