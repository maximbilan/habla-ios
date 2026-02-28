import SwiftUI

struct CallHistoryView: View {
    @EnvironmentObject var store: Store

    private var state: AppState { store.state }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Recent Calls")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.appTextPrimary)

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            RecentCallsView(
                calls: state.recentCalls,
                onCallTapped: { number in
                    store.dispatch(.phoneNumberChanged(number))
                    store.dispatch(.navigateTo(.dialer))
                },
                onSummaryTapped: { record in
                    store.dispatch(.openCallSummary(record))
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .background(Color.appBackground)
    }
}
