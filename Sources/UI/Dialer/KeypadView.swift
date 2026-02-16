//
//  KeypadView.swift
//  habla-ios
//

import SwiftUI

struct KeypadView: View {
    let onDigit: (String) -> Void
    let onBackspace: () -> Void

    private let rows: [[KeypadItem]] = [
        [.digit("1", ""), .digit("2", "ABC"), .digit("3", "DEF")],
        [.digit("4", "GHI"), .digit("5", "JKL"), .digit("6", "MNO")],
        [.digit("7", "PQRS"), .digit("8", "TUV"), .digit("9", "WXYZ")],
        [.digit("*", ""), .digit("0", "+"), .digit("#", "")],
    ]

    var body: some View {
        VStack(spacing: 16) {
            ForEach(rows.indices, id: \.self) { rowIndex in
                HStack(spacing: 24) {
                    ForEach(rows[rowIndex].indices, id: \.self) { colIndex in
                        let item = rows[rowIndex][colIndex]
                        KeypadButton(item: item) {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            switch item {
                            case .digit(let d, _):
                                onDigit(d)
                            }
                        }
                    }
                }
            }

            HStack(spacing: 24) {
                Color.clear
                    .frame(width: 72, height: 72)

                Color.clear
                    .frame(width: 72, height: 72)

                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    onBackspace()
                }) {
                    Image(systemName: "delete.backward.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.appTextSecondary)
                        .frame(width: 72, height: 72)
                }
            }
        }
    }
}

private enum KeypadItem {
    case digit(String, String)
}

private struct KeypadButton: View {
    let item: KeypadItem
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                switch item {
                case .digit(let digit, let letters):
                    Text(digit)
                        .font(.system(size: 28, weight: .medium, design: .rounded))
                        .foregroundColor(.appTextPrimary)
                    if !letters.isEmpty {
                        Text(letters)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.appTextSecondary)
                    }
                }
            }
            .frame(width: 72, height: 72)
            .background(
                Circle()
                    .fill(Color.appKeypad)
            )
        }
    }
}
