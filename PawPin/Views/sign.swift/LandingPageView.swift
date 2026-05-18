//
//  LandingPageView.swift
//  PawPin
//
//  Created by lay on 01/12/1447 AH.
//
import SwiftUI

struct LandingPageView: View {
    @State private var showAuthSheet = false
    @State private var phoneNumber = ""
    @State private var navigateToOTP = false
    
    let lightOrange = Color(hex: "FFC762")
    let subTextColor = Color(hex: "7B7B7B")

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.white.ignoresSafeArea()

                // 1. المحتوى الخلفي (القطط والنصوص)
                VStack(spacing: 0) {
                    if !showAuthSheet {
                        Image("OnboardingBackground")
                            .resizable()
                            .scaledToFit()
                            .frame(width: UIScreen.main.bounds.width * 0.85)
                            .padding(.top, 20)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    Spacer().frame(height: showAuthSheet ? 120 : 230)

                    if !showAuthSheet {
                        VStack(spacing: 18) {
                            VStack(spacing: 10) {
                                Text("Lost or found? We connect you")
                                    .font(.system(size: 24, weight: .bold))
                                
                                Text("One post can bring them home 🐾")
                                    .font(.system(size: 15))
                                    .foregroundColor(subTextColor)
                            }
                            
                            Spacer()

                            Button(action: {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    showAuthSheet = true
                                }
                            }) {
                                Text("Sign up with Phone Number")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(lightOrange)
                                    .cornerRadius(25)
                            }
                            .padding(.horizontal, 35)

                            HStack(spacing: 15) {
                                SocialButton(title: "Apple", icon: "applelogo", bg: .black, fg: .white)
                                SocialButton(title: "Google", icon: "g.circle.fill", bg: .white, fg: .black, hasBorder: true)
                            }
                            .padding(.horizontal, 35)
                            .padding(.bottom, 50)
                        }
                        .transition(.opacity)
                    }
                }

                // 2. الشيت البرتقالي (AuthView)
                if showAuthSheet {
                    AuthView(phoneNumber: $phoneNumber, onContinue: {
                        navigateToOTP = true
                    })
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
                }

                // 3. الشعار
                VStack {
                    Image("FindMyPetLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: showAuthSheet ? 110 : 130)
                        .padding(.top, showAuthSheet ? 45 : 350)
                    
                    if showAuthSheet { Spacer() }
                }
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showAuthSheet)
                .zIndex(2)
            }
            .navigationDestination(isPresented: $navigateToOTP) {
                // ناديت لك صفحة الـ OTP هنا
                OTPVerificationView()
            }
        }
    }
}

// MARK: - المكونات الإضافية (عشان تروح الأخطاء)

struct SocialButton: View {
    let title: String; let icon: String; let bg: Color; let fg: Color; var hasBorder: Bool = false
    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(title)
        }
        .font(.system(size: 15, weight: .bold))
        .foregroundColor(fg)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(bg)
        .overlay(RoundedRectangle(cornerRadius: 25).stroke(Color.gray.opacity(hasBorder ? 0.3 : 0), lineWidth: 1))
        .cornerRadius(25)
    }
}

struct AuthView: View {
    @Binding var phoneNumber: String
    var onContinue: () -> Void
    @State private var isAgreed = true
    
    let sheetOrange = Color(hex: "FFC762")
    let buttonOrange = Color(hex: "DA8A41")
    let subTextColor = Color(hex: "7B7B7B")

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Enter your phone number").font(.system(size: 24, weight: .bold))
                Text("paw p").font(.system(size: 14)).foregroundColor(subTextColor)
            }
            .padding(.top, 35)

            VStack(spacing: 0) {
                HStack {
                    Text("Saudi Arabia").font(.system(size: 16, weight: .medium))
                    Spacer()
                }
                .padding(.bottom, 10)
                Divider()
                HStack {
                    Text("+966").font(.system(size: 16, weight: .bold))
                    TextField("5xxxxxxx", text: $phoneNumber).keyboardType(.numberPad)
                }
                .padding(.top, 10)
            }
            .padding(15).background(Color.white).cornerRadius(15)
            
            HStack(alignment: .top, spacing: 8) {
                Button(action: { isAgreed.toggle() }) {
                    Image(systemName: isAgreed ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isAgreed ? Color.blue : subTextColor)
                        .font(.system(size: 18))
                }
                (Text("you are agreeing to our ") + Text("Terms of Service & Privacy Policy").underline())
                    .font(.system(size: 12)).foregroundColor(subTextColor)
            }
            .padding(.vertical, 5)

            Button(action: { onContinue() }) {
                Text("Continue")
                    .font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(buttonOrange).cornerRadius(22)
            }
            .padding(.top, 5)
            Spacer()
        }
        .padding(.horizontal, 30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(sheetOrange.cornerRadius(50, corners: [.topLeft, .topRight]).ignoresSafeArea(edges: .bottom))
        .padding(.top, 200)
    }
}

#Preview {
    LandingPageView()
}
