import SwiftUI

struct CallHistoryView: View {
    @EnvironmentObject var store: Store

    private var state: AppState { store.state }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    store.dispatch(.navigateTo(.dialer))
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.appAccent)
                }

                Spacer()

                Text("Recent Calls")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.appTextPrimary)

                Spacer()
                Color.clear.frame(width: 56, height: 1)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            RecentCallsView(
                calls: state.recentCalls,
                onCallTapped: { number in
                    store.dispatch(.phoneNumberChanged(number))
                    store.dispatch(.navigateTo(.dialer))
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .background(Color.appBackground)
    }
}
