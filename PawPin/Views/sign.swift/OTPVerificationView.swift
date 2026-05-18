//
//  OTPView.swift
//  PawPin
//
//  Created by lay on 27/11/1447 AH.
//

import SwiftUI

struct OTPVerificationView: View {
    @State private var otpCode: [String] = Array(repeating: "", count: 4)
    @FocusState private var focusedField: Int?
    
    let sheetOrange = Color(hex: "FFC762")
    let buttonOrange = Color(hex: "DA8A41")
    let subTextColor = Color(hex: "7B7B7B")

    var body: some View {
        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()
            
            // الشعار ثابت فوق مثل الصفحة السابقة
            VStack {
                Image("FindMyPetLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 110)
                    .padding(.top, 45)
                Spacer()
            }
            .zIndex(2)

            // الشيت البرتقالي
            VStack(alignment: .leading, spacing: 15) {
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Verify your number")
                        .font(.system(size: 24, weight: .bold))
                    
                    Text("Enter the code sent to your phone")
                        .font(.system(size: 14))
                        .foregroundColor(subTextColor)
                }
                .padding(.top, 35)

                // مربعات الـ OTP (نفس ستايل بوكس الجوال)
                HStack(spacing: 12) {
                    ForEach(0..<4, id: \.self) { index in
                        TextField("", text: $otpCode[index])
                            .frame(width: 60, height: 60)
                            .background(Color.white)
                            .cornerRadius(12)
                            .multilineTextAlignment(.center)
                            .keyboardType(.numberPad)
                            .font(.system(size: 24, weight: .bold))
                            .focused($focusedField, equals: index)
                            .onChange(of: otpCode[index]) { oldValue, newValue in
                                if newValue.count > 1 {
                                    otpCode[index] = String(newValue.suffix(1))
                                }
                                if !newValue.isEmpty && index < 3 {
                                    focusedField = index + 1
                                }
                            }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)

                // نص إعادة الإرسال
                HStack {
                    Text("Didn't receive a code?")
                        .font(.system(size: 13))
                        .foregroundColor(subTextColor)
                    Button(action: {}) {
                        Text("Resend")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(buttonOrange)
                    }
                }
                .frame(maxWidth: .infinity)

                // زر التحقق
                Button(action: {
                    let fullCode = otpCode.joined()
                    print("Verifying code: \(fullCode)")
                }) {
                    Text("Verify & Continue")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(buttonOrange)
                        .cornerRadius(22)
                }
                .padding(.top, 5)
                
                Spacer()
            }
            .padding(.horizontal, 30)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                sheetOrange
                    .cornerRadius(50, corners: [.topLeft, .topRight])
                    .ignoresSafeArea(edges: .bottom)
            )
            .padding(.top, 330) // نفس إزاحة الصفحة الأولى بالضبط لضمان التناسق
        }
    }
}

#Preview {
    OTPVerificationView()
}
