//
//  ActiveCallView.swift
//  habla-ios
//

import SwiftUI

struct ActiveCallView: View {
    @EnvironmentObject var store: Store

    private var state: AppState { store.state }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Phone number
            Text(state.phoneNumber)
                .font(.system(size: 26, weight: .medium, design: .monospaced))
                .foregroundColor(.appTextPrimary)
                .padding(.bottom, 8)

            // Call status / timer
            Group {
                switch state.callStatus {
                case .initiating:
                    Text("Initiating...")
                case .connecting:
                    Text("Connecting...")
                case .ringing:
                    Text("Ringing...")
                case .connected:
                    Text(state.callDuration.formattedDuration)
                        .font(.system(size: 18, design: .monospaced))
                case .ended:
                    Text("Call Ended")
                case .failed(let reason):
                    Text("Failed: \(reason)")
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                case .idle:
                    Text("")
                }
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.appTextSecondary)
            .padding(.bottom, 40)

            // Audio visualizer
            AudioVisualizerView(
                inputLevel: state.inputAudioLevel,
                outputLevel: state.outputAudioLevel,
                isReceivingAudio: state.isReceivingAudio,
                isConnected: state.callStatus == .connected
            )
            .padding(.bottom, 40)

            Spacer()

            // Control buttons
            HStack(spacing: 48) {
                // Mute button
                ControlButton(
                    icon: state.isMuted ? "mic.slash.fill" : "mic.fill",
                    label: state.isMuted ? "Unmute" : "Mute",
                    isActive: state.isMuted
                ) {
                    store.dispatch(.toggleMute)
                }

                // Speaker button
                ControlButton(
                    icon: state.isSpeaker ? "speaker.wave.2.fill" : "speaker.fill",
                    label: "Speaker",
                    isActive: state.isSpeaker
                ) {
                    store.dispatch(.toggleSpeaker)
                }
            }
            .padding(.bottom, 40)

            // End call button
            CallButton(isActive: true, isEndCall: true) {
                store.dispatch(.endCall)
            }
            .padding(.bottom, 48)
        }
        .frame(maxWidth: .infinity)
        .background(Color.appBackground)
    }
}

private struct ControlButton: View {
    let icon: String
    let label: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(isActive ? .appBackground : .appTextPrimary)
                    .frame(width: 56, height: 56)
                    .background(
                        Circle()
                            .fill(isActive ? Color.appTextPrimary : Color.appSurface)
                    )

                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(.appTextSecondary)
            }
        }
    }
}
