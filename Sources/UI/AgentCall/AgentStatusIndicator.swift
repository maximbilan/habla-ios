import SwiftUI

struct AgentStatusIndicator: View {
    let status: AgentStatus
    @State private var pulse = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.35)) { context in
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.appAgentAccent)
                    .frame(width: 8, height: 8)
                    .scaleEffect(pulseScale)
                    .opacity(pulseOpacity)

                Text(statusText(context.date))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.appTextSecondary)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }

    private func statusText(_ date: Date) -> String {
        switch status {
        case .idle:
            return "🤖 Waiting..."
        case .listening:
            return "🤖 Listening..."
        case .speaking:
            return "🤖 Agent is speaking..."
        case .thinking:
            let step = Int(date.timeIntervalSinceReferenceDate / 0.35) % 4
            let dots = String(repeating: ".", count: step)
            return "🤖 Thinking\(dots)"
        }
    }

    private var pulseScale: CGFloat {
        switch status {
        case .speaking:
            return pulse ? 1.25 : 0.9
        case .listening:
            return pulse ? 1.1 : 0.95
        default:
            return 1.0
        }
    }

    private var pulseOpacity: Double {
        switch status {
        case .speaking, .listening:
            return pulse ? 1.0 : 0.5
        default:
            return 0.8
        }
    }
}
