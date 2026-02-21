//
//  KeypadView.swift
//  habla-ios
//

import SwiftUI

struct KeypadView: View {
    let onDigit: (String) -> Void
    let buttonSize: CGFloat
    let rowSpacing: CGFloat
    let columnSpacing: CGFloat
    let digitFontSize: CGFloat
    let lettersFontSize: CGFloat

    private let rows: [[KeypadItem]] = [
        [.digit("1", ""), .digit("2", "ABC"), .digit("3", "DEF")],
        [.digit("4", "GHI"), .digit("5", "JKL"), .digit("6", "MNO")],
        [.digit("7", "PQRS"), .digit("8", "TUV"), .digit("9", "WXYZ")],
        [.digit("*", ""), .digit("0", "+"), .digit("#", "")],
    ]

    init(
        onDigit: @escaping (String) -> Void,
        buttonSize: CGFloat = 72,
        rowSpacing: CGFloat = 16,
        columnSpacing: CGFloat = 24,
        digitFontSize: CGFloat = 28,
        lettersFontSize: CGFloat = 10
    ) {
        self.onDigit = onDigit
        self.buttonSize = buttonSize
        self.rowSpacing = rowSpacing
        self.columnSpacing = columnSpacing
        self.digitFontSize = digitFontSize
        self.lettersFontSize = lettersFontSize
    }

    var body: some View {
        VStack(spacing: rowSpacing) {
            ForEach(rows.indices, id: \.self) { rowIndex in
                HStack(spacing: columnSpacing) {
                    ForEach(rows[rowIndex].indices, id: \.self) { colIndex in
                        let item = rows[rowIndex][colIndex]
                        KeypadButton(
                            item: item,
                            buttonSize: buttonSize,
                            digitFontSize: digitFontSize,
                            lettersFontSize: lettersFontSize
                        ) {
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
        }
    }
}

private enum KeypadItem {
    case digit(String, String)
}

private struct KeypadButton: View {
    let item: KeypadItem
    let buttonSize: CGFloat
    let digitFontSize: CGFloat
    let lettersFontSize: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                switch item {
                case .digit(let digit, let letters):
                    Text(digit)
                        .font(.system(size: digitFontSize, weight: .medium, design: .rounded))
                        .foregroundColor(.appTextPrimary)
                    if !letters.isEmpty {
                        Text(letters)
                            .font(.system(size: lettersFontSize, weight: .medium))
                            .foregroundColor(.appTextSecondary)
                    }
                }
            }
            .frame(width: buttonSize, height: buttonSize)
            .background(
                Circle()
                    .fill(Color.appKeypad)
            )
        }
    }
}
