//
//  Extensions.swift
//  PawPin
//
//  Created by lay on 01/12/1447 AH.
//
import SwiftUI

// 1. تعريف الألوان بالـ Hex (مرة واحدة فقط للمشروع)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6: (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default: (r, g, b) = (1, 1, 1)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: 1)
    }
}

// 2. تصميم الزر الدائري (الذي كان مفقوداً في لقطة الشاشة)
struct CustomCircleToggle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: { configuration.isOn.toggle() }) {
            Circle()
                .fill(Color.white)
                .frame(width: 22, height: 22)
                .overlay(
                    Circle()
                        .fill(configuration.isOn ? Color.blue : Color.clear)
                        .padding(5)
                )
        }
    }
}

// 3. تعريف انحناء الزوايا
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}
