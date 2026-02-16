//
//  AudioVisualizerView.swift
//  habla-ios
//

import SwiftUI

struct AudioVisualizerView: View {
    let inputLevel: Float
    let outputLevel: Float
    let isReceivingAudio: Bool
    let isConnected: Bool

    @State private var animationPhase: Double = 0

    var body: some View {
        VStack(spacing: 16) {
            // Translation direction indicator
            if isConnected {
                HStack(spacing: 8) {
                    if isReceivingAudio {
                        Text("\u{1F1EA}\u{1F1F8}")
                            .font(.system(size: 24))
                        Image(systemName: "arrow.right")
                            .foregroundColor(.appAccent)
                            .font(.system(size: 16, weight: .semibold))
                        Text("\u{1F1FA}\u{1F1F8}")
                            .font(.system(size: 24))
                    } else if inputLevel > 0.05 {
                        Text("\u{1F1FA}\u{1F1F8}")
                            .font(.system(size: 24))
                        Image(systemName: "arrow.right")
                            .foregroundColor(.appAccent)
                            .font(.system(size: 16, weight: .semibold))
                        Text("\u{1F1EA}\u{1F1F8}")
                            .font(.system(size: 24))
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: isReceivingAudio)
                .animation(.easeInOut(duration: 0.3), value: inputLevel > 0.05)
            }

            // Pulsing circle visualizer
            ZStack {
                // Outer ring - output level
                Circle()
                    .stroke(
                        Color.appAccent.opacity(0.15),
                        lineWidth: 2
                    )
                    .frame(
                        width: 140 + CGFloat(outputLevel) * 40,
                        height: 140 + CGFloat(outputLevel) * 40
                    )
                    .animation(.easeInOut(duration: 0.15), value: outputLevel)

                // Middle ring
                Circle()
                    .stroke(
                        Color.appAccent.opacity(0.25),
                        lineWidth: 2
                    )
                    .frame(
                        width: 110 + CGFloat(inputLevel) * 30,
                        height: 110 + CGFloat(inputLevel) * 30
                    )
                    .animation(.easeInOut(duration: 0.1), value: inputLevel)

                // Inner filled circle
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.appAccent.opacity(0.4),
                                Color.appAccent.opacity(0.1)
                            ]),
                            center: .center,
                            startRadius: 10,
                            endRadius: 50
                        )
                    )
                    .frame(width: 80, height: 80)
                    .scaleEffect(1.0 + CGFloat(max(inputLevel, outputLevel)) * 0.3)
                    .animation(.easeInOut(duration: 0.15), value: inputLevel)
                    .animation(.easeInOut(duration: 0.15), value: outputLevel)

                // Waveform bars
                HStack(spacing: 3) {
                    ForEach(0..<7, id: \.self) { index in
                        let level = isConnected ? max(inputLevel, outputLevel) : 0
                        let barHeight = barHeight(for: index, level: CGFloat(level))
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.appAccent)
                            .frame(width: 4, height: barHeight)
                            .animation(
                                .easeInOut(duration: 0.12).delay(Double(index) * 0.02),
                                value: level
                            )
                    }
                }
            }
            .frame(height: 180)
        }
    }

    private func barHeight(for index: Int, level: CGFloat) -> CGFloat {
        let baseHeight: CGFloat = 8
        let maxExtra: CGFloat = 40
        let centerIndex = 3
        let distance = abs(index - centerIndex)
        let falloff = 1.0 - (CGFloat(distance) * 0.2)
        return baseHeight + maxExtra * level * falloff
    }
}
