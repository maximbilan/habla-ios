//
//  AudioVisualizerView.swift
//  habla-ios
//

import SwiftUI

struct AudioVisualizerView: View {
    let inputLevel: Float
    let isReceivingAudio: Bool
    let isConnected: Bool
    let phase: LiveCallPhase

    var body: some View {
        VStack(spacing: 16) {
            if isConnected {
                HStack(spacing: 10) {
                    ActivityChip(
                        icon: "mic.fill",
                        title: "Listening",
                        level: CGFloat(inputLevel),
                        isActive: phase == .listening
                    )
                    ActivityChip(
                        icon: "speaker.wave.2.fill",
                        title: "Remote",
                        level: isReceivingAudio ? 1 : 0,
                        isActive: phase == .speaking
                    )
                }
            }

            ZStack {
                Circle()
                    .stroke(
                        Color.appAccent.opacity(0.15),
                        lineWidth: 2
                    )
                    .frame(
                        width: 140 + activityLevel * 40,
                        height: 140 + activityLevel * 40
                    )
                    .animation(.easeInOut(duration: 0.15), value: activityLevel)

                Circle()
                    .stroke(
                        Color.appAccent.opacity(0.25),
                        lineWidth: 2
                    )
                    .frame(
                        width: 110 + activityLevel * 30,
                        height: 110 + activityLevel * 30
                    )
                    .animation(.easeInOut(duration: 0.1), value: activityLevel)

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
                    .scaleEffect(1.0 + activityLevel * 0.3)
                    .animation(.easeInOut(duration: 0.15), value: activityLevel)

                HStack(spacing: 3) {
                    ForEach(0..<7, id: \.self) { index in
                        let level = isConnected ? activityLevel : 0
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

    private var activityLevel: CGFloat {
        if !isConnected {
            return 0
        }
        if isReceivingAudio {
            return max(0.35, CGFloat(inputLevel))
        }
        return CGFloat(inputLevel)
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

private struct ActivityChip: View {
    let icon: String
    let title: String
    let level: CGFloat
    let isActive: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isActive ? .appTextPrimary : .appTextSecondary)

            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.appTextSecondary)

            Capsule()
                .fill(Color.appTextSecondary.opacity(0.22))
                .frame(width: 42, height: 6)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(Color.appAccent)
                        .frame(width: max(8, min(42, level * 42)), height: 6)
                }

            Circle()
                .fill(isActive ? Color.appAccent : Color.appTextSecondary.opacity(0.3))
                .frame(width: 8, height: 8)
                .scaleEffect(isActive ? 1.15 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isActive)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appSurface)
        )
    }
}
