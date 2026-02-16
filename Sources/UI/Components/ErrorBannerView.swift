//
//  ErrorBannerView.swift
//  habla-ios
//

import SwiftUI

struct ErrorBannerView: View {
    let error: AppError
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.appDestructive)
                .font(.system(size: 18))

            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.appTextPrimary)
                .lineLimit(2)

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.appTextSecondary)
                    .font(.system(size: 18))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.appDestructive.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
