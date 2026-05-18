//
//  PetReport.swift
//  PawPin
//
//  Created by lay on 24/11/1447 AH.
//

import SwiftUI
import MapKit

// MARK: - Brand colour (shared — keep in one place in your project)
// extension Color { static let brand = Color(red: 238/255, green: 182/255, blue: 81/255) }

// MARK: - Report Model
// This is the data object passed from ReportPetView into ReportCardView.
// In production you'll populate this from Firestore.

struct PetReport: Identifiable {
    let id:              String          // Firestore document ID
    let type:            PetReportType  // .lost / .found
    let petName:         String?        // only for owner
    let photoURL:        String?        // remote URL or nil
    let localImage:      UIImage?       // set when coming straight from the form
    let gender:          PetGender
    let eyeColor:        String?        // e.g. "Green"
    let eyeAssetName:    String?        // e.g. "eye_green"
    let description:     String
    let locationName:    String
    let coordinate:      CLLocationCoordinate2D?
    let rewardAmount:    Double?        // nil = no reward
    let isHighlighted:   Bool           // true if reward post with active 24h boost
    let highlightExpiry: Date?
    let postedAt:        Date
    let ownerID:         String         // current user's UID
    let viewerID:        String         // UID of whoever is viewing (to show/hide name)
}

// MARK: - Report Card View

struct ReportCardView: View {

    let report: PetReport
    @Environment(\.dismiss) private var dismiss
    @State private var showChat = false
    @State private var mapRegion: MKCoordinateRegion

    init(report: PetReport) {
        self.report = report
        _mapRegion = State(initialValue: MKCoordinateRegion(
            center: report.coordinate ?? CLLocationCoordinate2D(latitude: 24.7136, longitude: 46.6753),
            span:   MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
        ))
    }

    var cardBg:  Color { Color(white: 1.0) }
    var pageBg:  Color { Color(white: 0.95) }
    var fieldBg: Color { Color(red: 0.96, green: 0.96, blue: 0.97) }

    // Show pet name only to the owner
    var isOwner: Bool { report.viewerID == report.ownerID }

    var timeSincePosted: String {
        let diff = Date().timeIntervalSince(report.postedAt)
        if diff < 3600   { return "\(Int(diff / 60)) mins ago" }
        if diff < 86400  { return "\(Int(diff / 3600)) hrs ago" }
        return "\(Int(diff / 86400)) days ago"
    }

    var highlightTimeRemaining: String? {
        guard report.isHighlighted, let expiry = report.highlightExpiry else { return nil }
        let remaining = expiry.timeIntervalSinceNow
        guard remaining > 0 else { return nil }
        let hrs = Int(remaining / 3600)
        let mins = Int((remaining.truncatingRemainder(dividingBy: 3600)) / 60)
        return hrs > 0 ? "\(hrs)h \(mins)m left" : "\(mins)m left"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {

                // ── Hero photo + back button ──
                ZStack(alignment: .topLeading) {
                    Group {
                        if let ui = report.localImage {
                            Image(uiImage: ui)
                                .resizable().scaledToFill()
                        } else {
                            Rectangle()
                                .fill(Color(red: 0.92, green: 0.88, blue: 0.82))
                                .overlay(
                                    Image(systemName: "pawprint.fill")
                                        .font(.system(size: 60))
                                        .foregroundColor(Color.brand.opacity(0.4))
                                )
                        }
                    }
                    .frame(height: 300)
                    .clipped()

                    // Gradient overlay so back button is always readable
                    LinearGradient(
                        colors: [Color.black.opacity(0.35), Color.clear],
                        startPoint: .top, endPoint: .center
                    )
                    .frame(height: 300)

                    // Back button
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.brand)
                            .padding(12)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.12), radius: 6, y: 2)
                    }
                    .padding(.top, 56).padding(.leading, 16)

                    // Highlight badge (top right)
                    if let remaining = highlightTimeRemaining {
                        VStack {
                            HStack {
                                Spacer()
                                HStack(spacing: 4) {
                                    Image(systemName: "bolt.fill").font(.caption2)
                                    Text("Boosted · \(remaining)").font(.caption2).bold()
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 10).padding(.vertical, 5)
                                .background(Color.brand)
                                .clipShape(Capsule())
                                .padding(.top, 60).padding(.trailing, 16)
                            }
                            Spacer()
                        }
                        .frame(height: 300)
                    }
                }

                // ── White card content ──
                VStack(alignment: .leading, spacing: 0) {

                    // ── Name row + reward badge ──
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {

                            // Show name only to owner; others see "Lost Pet" / "Found Pet"
                            if isOwner, let name = report.petName, !name.isEmpty {
                                Text(name)
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.primary)
                            } else {
                                Text(report.type == .lost ? "Lost Pet" : "Found Pet")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.primary)
                            }

                            // Time
                            HStack(spacing: 4) {
                                Text("Last seen")
                                    .font(.subheadline).foregroundColor(.secondary)
                                Text(timeSincePosted)
                                    .font(.subheadline).bold().foregroundColor(Color.brand)
                                Text("ago")
                                    .font(.subheadline).foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        // Reward badge
                        if let reward = report.rewardAmount, reward > 0 {
                            HStack(spacing: 6) {
                                Image(systemName: "pawprint.fill")
                                    .font(.subheadline).foregroundColor(Color.brand)
                                Text("\(Int(reward))")
                                    .font(.title3).bold().foregroundColor(Color.brand)
                            }
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(Color.brand.opacity(0.12))
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 20).padding(.top, 22).padding(.bottom, 18)

                    // ── Gender + Eye Color cards ──
                    HStack(spacing: 12) {
                        InfoTile(
                            icon: report.gender == .female ? "venus" : "mars",
                            iconColor: Color.brand,
                            title: report.gender == .female ? "Female" : (report.gender == .male ? "Male" : "Unknown"),
                            subtitle: "Gender"
                        )

                        // Eye tile — shows real eye image if available
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color(red: 0.90, green: 0.95, blue: 0.90))
                                    .frame(width: 44, height: 44)
                                if let asset = report.eyeAssetName {
                                    Image(asset)
                                        .resizable().scaledToFill()
                                        .frame(width: 36, height: 36)
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "eye.fill")
                                        .foregroundColor(Color.brand)
                                }
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(report.eyeColor ?? "Unknown")
                                    .font(.subheadline).bold()
                                Text("Eye color")
                                    .font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(12)
                        .background(fieldBg)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 20).padding(.bottom, 18)

                    // ── About ──
                    if !report.description.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "doc.text.fill")
                                    .foregroundColor(Color.brand).font(.subheadline)
                                Text("Description").font(.headline)
                            }

                            Text(report.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineSpacing(4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)
                                .background(fieldBg)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.horizontal, 20).padding(.bottom, 18)
                    }

                    // ── Location ──
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(Color.brand).font(.subheadline)
                            Text("Location").font(.headline)
                        }

                        if let coord = report.coordinate {
                            // Interactive map with pet photo pin
                            ZStack(alignment: .bottomTrailing) {
                                Map(coordinateRegion: $mapRegion,
                                    annotationItems: [MapPinItem(coordinate: coord)]) { item in
                                    MapAnnotation(coordinate: item.coordinate) {
                                        // Pin with pet photo inside
                                        ZStack(alignment: .bottom) {
                                            VStack(spacing: 0) {
                                                ZStack {
                                                    Circle()
                                                        .fill(Color.brand)
                                                        .frame(width: 54, height: 54)
                                                    if let ui = report.localImage {
                                                        Image(uiImage: ui)
                                                            .resizable().scaledToFill()
                                                            .frame(width: 46, height: 46)
                                                            .clipShape(Circle())
                                                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                                    } else {
                                                        Image(systemName: "pawprint.fill")
                                                            .foregroundColor(.white)
                                                            .font(.title3)
                                                    }
                                                }
                                                Image(systemName: "arrowtriangle.down.fill")
                                                    .foregroundColor(Color.brand)
                                                    .font(.system(size: 12))
                                                    .offset(y: -2)
                                            }
                                        }
                                    }
                                }
                                .frame(height: 220)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .allowsHitTesting(true)

                                // Chat button (for non-owners)
                                if !isOwner {
                                    Button { showChat = true } label: {
                                        Image(systemName: "bubble.left.fill")
                                            .font(.title3)
                                            .foregroundColor(Color.brand)
                                            .padding(14)
                                            .background(Color.white)
                                            .clipShape(Circle())
                                            .shadow(color: .black.opacity(0.15), radius: 8, y: 3)
                                    }
                                    .padding(12)
                                }
                            }

                            // Address label
                            if !report.locationName.isEmpty {
                                HStack(spacing: 6) {
                                    Image(systemName: "mappin").foregroundColor(Color.brand).font(.caption)
                                    Text(report.locationName)
                                        .font(.caption).foregroundColor(.secondary)
                                }
                                .padding(.top, 2)
                            }

                        } else {
                            Text(report.locationName.isEmpty ? "Location not specified" : report.locationName)
                                .font(.subheadline).foregroundColor(.secondary)
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(fieldBg)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding(.horizontal, 20).padding(.bottom, 18)

                    // ── Reward section (visible to everyone) ──
                    if let reward = report.rewardAmount, reward > 0 {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "gift.fill")
                                    .foregroundColor(Color.brand).font(.subheadline)
                                Text("Reward Offered").font(.headline)
                            }

                            HStack(spacing: 14) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("\(Int(reward)) SAR")
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(Color.brand)
                                    Text("Offered by the owner if found")
                                        .font(.caption).foregroundColor(.secondary)
                                }
                                Spacer()
                                if !isOwner {
                                    Button { showChat = true } label: {
                                        Text("I found it!")
                                            .font(.subheadline).bold()
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 18).padding(.vertical, 10)
                                            .background(Color.brand)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                            .padding(16)
                            .background(Color.brand.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.brand.opacity(0.25), lineWidth: 1))
                        }
                        .padding(.horizontal, 20).padding(.bottom, 28)
                    }

                    // ── Contact button (non-owner, no reward) ──
                    if !isOwner && (report.rewardAmount ?? 0) == 0 {
                        Button { showChat = true } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "bubble.left.fill")
                                Text("Contact Owner").font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding()
                            .background(Color.brand)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.horizontal, 20).padding(.bottom, 28)
                    }

                    // ── Owner actions ──
                    if isOwner {
                        VStack(spacing: 10) {
                            Button { /* TODO: mark as found */ } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Mark as Found").font(.headline)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity).padding()
                                .background(Color(red: 0.20, green: 0.65, blue: 0.40))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }

                            Button { /* TODO: delete post */ } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "trash")
                                    Text("Delete Post").font(.headline)
                                }
                                .foregroundColor(Color(red: 0.85, green: 0.25, blue: 0.25))
                                .frame(maxWidth: .infinity).padding()
                                .background(Color(red: 0.85, green: 0.25, blue: 0.25).opacity(0.10))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                        .padding(.horizontal, 20).padding(.bottom, 36)
                    }
                }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .offset(y: -28)         // overlaps the hero photo slightly
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(pageBg.ignoresSafeArea())
        .navigationBarHidden(true)      // we have our own back button
        .sheet(isPresented: $showChat) {
            // TODO: replace with your real chat view
            VStack(spacing: 16) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 48)).foregroundColor(Color.brand)
                Text("Chat coming soon").font(.headline)
                Text("This will open a Firebase-backed chat with the owner.")
                    .font(.caption).foregroundColor(.secondary).multilineTextAlignment(.center)
            }
            .padding(32)
            .presentationDetents([.medium])
        }
    }
}

// MARK: - Sub-components

struct InfoTile: View {
    let icon:      String
    let iconColor: Color
    let title:     String
    let subtitle:  String

    var fieldBg: Color { Color(red: 0.96, green: 0.96, blue: 0.97) }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.title3)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline).bold()
                Text(subtitle).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(fieldBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct MapPinItem: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

// MARK: - Preview
#Preview {
    NavigationStack {
        ReportCardView(report: PetReport(
            id:             "preview-001",
            type:           .lost,
            petName:        "Oliver",
            photoURL:       nil,
            localImage:     nil,
            gender:         .male,
            eyeColor:       "Green",
            eyeAssetName:   "eye_green",
            description:    "This is Oliver my cat.\nThere is a scar on his left hand paw.\nLast seen near the neighbourhood park.",
            locationName:   "Al Olaya, Riyadh",
            coordinate:     CLLocationCoordinate2D(latitude: 24.7136, longitude: 46.6753),
            rewardAmount:   200,
            isHighlighted:  true,
            highlightExpiry: Date().addingTimeInterval(3600 * 18),
            postedAt:       Date().addingTimeInterval(-7200),
            ownerID:        "user-abc",
            viewerID:       "user-abc"   // change to a different ID to see non-owner view
        ))
    }
}
