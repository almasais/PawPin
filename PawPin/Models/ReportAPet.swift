//
//  ReportAPet.swift
//  PawPin
//
//  Created by Abeer Alshabrami on 5/19/26.
//

import SwiftUI
import PhotosUI
import MapKit
import Combine
import PassKit

// MARK: - Brand colour #EEB651
extension Color {
    static let brand = Color(red: 238/255, green: 182/255, blue: 81/255)
}

// MARK: - Double helper
extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let factor = pow(10.0, Double(places))
        return (self * factor).rounded() / factor
    }
}

// MARK: - Models
enum PetReportType { case found, lost }
enum PetGender     { case male, female, unknown }

// MARK: - Eye Options
struct EyeOption: Identifiable {
    let id        = UUID()
    let name:       String
    let assetName:  String
}

let allEyeOptions: [EyeOption] = [
    EyeOption(name: "Green",        assetName: "eye_green"),
    EyeOption(name: "Hazel",        assetName: "eye_hazel"),
    EyeOption(name: "Amber",        assetName: "eye_amber"),
    EyeOption(name: "Copper",       assetName: "eye_copper"),
    EyeOption(name: "Brown",        assetName: "eye_brown"),
    EyeOption(name: "Blue",         assetName: "eye_blue"),
    EyeOption(name: "Turquoise",    assetName: "eye_turquoise"),
    EyeOption(name: "Aquamarine",   assetName: "eye_aquamarine"),
    EyeOption(name: "Gray",         assetName: "eye_gray"),
    EyeOption(name: "Olive",        assetName: "eye_olive"),
    EyeOption(name: "Blue-Gray",    assetName: "eye_bluegray"),
    EyeOption(name: "Yellow-Green", assetName: "eye_yellowgreen"),
    EyeOption(name: "Blue / Gold",  assetName: "eye_blue_gold"),
    EyeOption(name: "Green / Blue", assetName: "eye_green_blue"),
]

// MARK: - Eye Picker Sheet
struct EyePickerSheet: View {
    @Binding var selectedID: UUID?
    @Environment(\.dismiss) private var dismiss

    let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(allEyeOptions) { eye in
                        Button {
                            selectedID = eye.id
                            dismiss()
                        } label: {
                            VStack(spacing: 6) {
                                ZStack {
                                    Image(eye.assetName)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 64, height: 64)
                                        .clipShape(Circle())

                                    if selectedID == eye.id {
                                        Circle()
                                            .strokeBorder(Color.brand, lineWidth: 3)
                                            .frame(width: 68, height: 68)
                                        Circle()
                                            .fill(Color.brand.opacity(0.22))
                                            .frame(width: 64, height: 64)
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.white)
                                            .shadow(radius: 2)
                                    } else {
                                        Circle()
                                            .strokeBorder(Color(white: 0.82), lineWidth: 1.5)
                                            .frame(width: 68, height: 68)
                                    }
                                }
                                Text(eye.name)
                                    .font(.system(size: 10, weight: selectedID == eye.id ? .bold : .regular))
                                    .foregroundColor(selectedID == eye.id ? .brand : .secondary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .navigationTitle("Choose Eye Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.foregroundColor(.brand)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Location Manager
@MainActor
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var lastLocation: CLLocation?
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocation() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in self.lastLocation = locations.last }
    }
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {}
}

// MARK: - Map Location Picker
struct MapPin: Identifiable {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
}

struct MapLocationPicker: View {
    @Binding var selectedLocation: String
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    @Environment(\.dismiss) private var dismiss

    @StateObject private var locManager = LocationManager()
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 24.7136, longitude: 46.6753),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    )
    @State private var pin: MapPin?    = nil
    @State private var isResolving     = false
    @State private var addressLabel    = ""
    @State private var didCenterOnUser = false

    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: $cameraPosition) {
                    if let pin {
                        Annotation("", coordinate: pin.coordinate) {
                            VStack(spacing: 0) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(.brand)
                                    .shadow(radius: 3)
                                Image(systemName: "arrowtriangle.down.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.brand)
                                    .offset(y: -4)
                            }
                        }
                    }
                }
                .mapStyle(.standard)
                .mapControls { MapCompass(); MapScaleView(); MapUserLocationButton() }
                .ignoresSafeArea(edges: .bottom)
                .overlay(MapTapLayer { coord in movePinTo(coord) })

                VStack {
                    Group {
                        if isResolving {
                            Label("Finding address…", systemImage: "location.circle")
                        } else if addressLabel.isEmpty {
                            Label("Tap the map or use your location", systemImage: "hand.tap")
                        } else {
                            Label(addressLabel, systemImage: "mappin")
                        }
                    }
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 16).padding(.top, 8)
                    Spacer()
                }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button { jumpToUserLocation() } label: {
                            Image(systemName: "location.fill")
                                .foregroundColor(.brand)
                                .padding(14)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding(.trailing, 16).padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Choose Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(.brand)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm") {
                        selectedLocation   = addressLabel
                        selectedCoordinate = pin?.coordinate
                        dismiss()
                    }
                    .bold()
                    .foregroundColor(pin == nil ? .secondary : .brand)
                    .disabled(pin == nil)
                }
            }
            .onAppear {
                locManager.requestLocation()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { jumpToUserLocation() }
            }
            .onChange(of: locManager.lastLocation) { _, loc in
                guard !didCenterOnUser, let loc else { return }
                didCenterOnUser = true
                let coord = loc.coordinate
                cameraPosition = .region(MKCoordinateRegion(
                    center: coord,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                ))
                movePinTo(coord)
            }
        }
    }

    private func jumpToUserLocation() {
        guard let coord = locManager.lastLocation?.coordinate else { return }
        withAnimation {
            cameraPosition = .region(MKCoordinateRegion(
                center: coord,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        }
        movePinTo(coord)
    }
    private func movePinTo(_ coord: CLLocationCoordinate2D) {
        pin = MapPin(coordinate: coord); reverseGeocode(coord)
    }
    private func reverseGeocode(_ coord: CLLocationCoordinate2D) {
        isResolving = true
        CLGeocoder().reverseGeocodeLocation(
            CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        ) { marks, _ in
            isResolving = false
            if let p = marks?.first {
                addressLabel = [p.name, p.locality, p.country]
                    .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")
            }
        }
    }
}

struct MapTapLayer: UIViewRepresentable {
    let onTap: (CLLocationCoordinate2D) -> Void
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.tapped(_:)))
        view.addGestureRecognizer(tap)
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) { context.coordinator.onTap = onTap }
    func makeCoordinator() -> Coordinator { Coordinator(onTap: onTap) }
    class Coordinator: NSObject {
        var onTap: (CLLocationCoordinate2D) -> Void
        init(onTap: @escaping (CLLocationCoordinate2D) -> Void) { self.onTap = onTap }
        @objc func tapped(_ gesture: UITapGestureRecognizer) {
            var v: UIView? = gesture.view
            while v != nil {
                if let mapView = v as? MKMapView {
                    let pt = gesture.location(in: mapView)
                    onTap(mapView.convert(pt, toCoordinateFrom: mapView)); return
                }
                v = v?.superview
            }
        }
    }
}

struct MiniMapPreview: UIViewRepresentable {
    let coordinate: CLLocationCoordinate2D
    func makeUIView(context: Context) -> MKMapView {
        let m = MKMapView()
        m.isUserInteractionEnabled = false; m.isScrollEnabled = false; m.isZoomEnabled = false
        return m
    }
    func updateUIView(_ map: MKMapView, context: Context) {
        map.setRegion(MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        ), animated: false)
        map.removeAnnotations(map.annotations)
        let p = MKPointAnnotation(); p.coordinate = coordinate; map.addAnnotation(p)
    }
}

// MARK: - Apple Pay
class ApplePayCoordinator: NSObject, PKPaymentAuthorizationControllerDelegate {
    var onSuccess: (() -> Void)?
    private var controller: PKPaymentAuthorizationController?

    func present(amount: Decimal, label: String) {
        guard PKPaymentAuthorizationController.canMakePayments() else { return }
        let item = PKPaymentSummaryItem(label: label, amount: NSDecimalNumber(decimal: amount))
        let req  = PKPaymentRequest()
        req.merchantIdentifier   = "merchant.com.yourapp.paw"   // ← replace with yours
        req.supportedNetworks    = [.visa, .masterCard, .mada]
        req.merchantCapabilities = .capability3DS
        req.countryCode = "SA"; req.currencyCode = "SAR"
        req.paymentSummaryItems = [item]
        controller = PKPaymentAuthorizationController(paymentRequest: req)
        controller?.delegate = self; controller?.present()
    }
    func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController,
                                        didAuthorizePayment payment: PKPayment,
                                        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        completion(PKPaymentAuthorizationResult(status: .success, errors: nil)); onSuccess?()
    }
    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.dismiss()
    }
}

// MARK: - Moyasar Payment
// Moyasar is a Saudi payment gateway (moyasar.com).
// It works via a REST API — we open their hosted payment page in a sheet using SFSafariViewController,
// then listen for the callback URL to confirm success.
// Replace MOYASAR_PUBLISHABLE_KEY with your key from the Moyasar dashboard.

import SafariServices

struct MoyasarPaymentSheet: UIViewControllerRepresentable {
    let amountHalala: Int      // Moyasar uses halala (1 SAR = 100 halala)
    let description:  String
    let callbackURL:  String   // your app's deep link, e.g. "paw://payment-success"
    var onSuccess:    () -> Void
    var onCancel:     () -> Void

    func makeUIViewController(context: Context) -> SFSafariViewController {
        // Build the Moyasar hosted payment URL
        var components = URLComponents(string: "https://api.moyasar.com/v1/payments/initiate")!
        components.queryItems = [
            URLQueryItem(name: "publishable_api_key", value: "pk_live_YOUR_MOYASAR_KEY"), // ← replace
            URLQueryItem(name: "amount",              value: "\(amountHalala)"),
            URLQueryItem(name: "currency",            value: "SAR"),
            URLQueryItem(name: "description",         value: description),
            URLQueryItem(name: "callback_url",        value: callbackURL),
            URLQueryItem(name: "source[type]",        value: "creditcard"),
        ]
        let url = components.url ?? URL(string: "https://moyasar.com")!
        let vc  = SFSafariViewController(url: url)
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onCancel: onCancel) }

    class Coordinator: NSObject, SFSafariViewControllerDelegate {
        let onCancel: () -> Void
        init(onCancel: @escaping () -> Void) { self.onCancel = onCancel }
        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            onCancel()   // user dismissed without completing
        }
    }
}

// MARK: - App Entry
struct ReportAPetApp: View {
    var body: some View {
        NavigationStack { ReportPetView() }
    }
}

// MARK: - Screen 1: Report a Pet
struct ReportPetView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var reportType: PetReportType        = .found
    @State private var selectedPhoto: PhotosPickerItem? = nil   // photo is now FIRST
    @State private var petImage: Image?                 = nil
    @State private var petName                          = ""
    @State private var gender: PetGender                = .unknown
    @State private var selectedEyeID: UUID?             = nil
    @State private var showEyePicker                    = false
    @State private var description                      = ""
    @State private var location                         = ""
    @State private var selectedCoordinate: CLLocationCoordinate2D? = nil
    @State private var showMapPicker                    = false
    @State private var goToReward                       = false

    var cardBg: Color { Color(red: 0.97, green: 0.95, blue: 0.91) }
    var pageBg: Color { Color(red: 0.99, green: 0.98, blue: 0.96) }
    var selectedEye: EyeOption? { allEyeOptions.first { $0.id == selectedEyeID } }

    var body: some View {
        ZStack {
            pageBg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Found / Lost
                    HStack(spacing: 0) {
                        SegmentButton(label: "Found a Pet", icon: "pawprint",
                                      isSelected: reportType == .found) { reportType = .found }
                        SegmentButton(label: "Lost a Pet",  icon: "pawprint.fill",
                                      isSelected: reportType == .lost)  { reportType = .lost  }
                    }
                    .background(cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(white: 0.88), lineWidth: 1))

                    // MARK: Photo — now comes FIRST before name
                    SectionLabel("Pet Photo")
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14).fill(cardBg).frame(height: 90)
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(white: 0.88), lineWidth: 1))
                            if let petImage {
                                petImage.resizable().scaledToFill()
                                    .frame(height: 90).clipShape(RoundedRectangle(cornerRadius: 14))
                            } else {
                                HStack(spacing: 14) {
                                    RoundedRectangle(cornerRadius: 10).fill(Color(white: 0.90))
                                        .frame(width: 58, height: 58)
                                        .overlay(Image(systemName: "camera").foregroundColor(.gray))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Add Photo").font(.subheadline).bold().foregroundColor(.primary)
                                        Text("Upload a clear photo of the pet").font(.caption).foregroundColor(.secondary)
                                        Text("1 photo only").font(.caption2).foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }.padding(.horizontal, 14)
                            }
                        }
                    }
                    .onChange(of: selectedPhoto) { _, item in
                        Task {
                            if let data = try? await item?.loadTransferable(type: Data.self),
                               let ui = UIImage(data: data) { petImage = Image(uiImage: ui) }
                        }
                    }

                    // MARK: Pet Name — now comes AFTER photo
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 4) {
                            SectionLabel("Pet Name")
                        
                        }
                        if reportType == .found {
                            HStack {
                                Text("Lost Pet").font(.subheadline).foregroundColor(Color(white: 0.55))
                                Spacer()
                                Image(systemName: "lock.fill").foregroundColor(Color(white: 0.75)).font(.caption)
                            }
                            .padding()
                            .background(Color(white: 0.94))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(white: 0.88), lineWidth: 1))
                        } else {
                            TextField("e.g. Fluffy", text: $petName)
                                .font(.subheadline).padding()
                                .background(cardBg)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(white: 0.88), lineWidth: 1))
                        }
                    }

                    // Gender
                    SectionLabel("Gender")
                    HStack(spacing: 12) {
                        GenderButton(label: "Male",   icon: "♂", isSelected: gender == .male)   { gender = .male   }
                        GenderButton(label: "Female", icon: "♀", isSelected: gender == .female) { gender = .female }
                    }

                    // Eye Color
                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel("Eye Color")
                        Button { showEyePicker = true } label: {
                            HStack(spacing: 12) {
                                if let eye = selectedEye {
                                    Image(eye.assetName)
                                        .resizable().scaledToFill()
                                        .frame(width: 32, height: 32)
                                        .clipShape(Circle())
                                        .overlay(Circle().strokeBorder(Color.brand, lineWidth: 1.5))
                                    Text(eye.name).font(.subheadline).foregroundColor(.primary)
                                } else {
                                    Image(systemName: "eye").foregroundColor(.secondary)
                                    Text("Select eye color").font(.subheadline).foregroundColor(Color(white: 0.55))
                                }
                                Spacer()
                                if selectedEye != nil {
                                    Button { selectedEyeID = nil } label: {
                                        Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                                    }
                                }
                                Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
                            }
                            .padding()
                            .background(cardBg)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(white: 0.88), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .sheet(isPresented: $showEyePicker) {
                            EyePickerSheet(selectedID: $selectedEyeID)
                        }
                    }

                    // Description
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 4) {
                            SectionLabel("Description")
                            Text("(optional)").font(.caption).foregroundColor(.secondary)
                        }
                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 12).fill(cardBg).frame(height: 115)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(white: 0.88), lineWidth: 1))
                            TextEditor(text: $description)
                                .frame(height: 95).padding(.horizontal, 8).padding(.top, 6)
                                .scrollContentBackground(.hidden).background(Color.clear).scrollDisabled(true)
                            if description.isEmpty {
                                Text("Any details about the pet (behaviour, marks, where it was last seen...)")
                                    .font(.caption).foregroundColor(Color(white: 0.70))
                                    .padding(.horizontal, 14).padding(.top, 14).allowsHitTesting(false)
                            }
                            VStack {
                                Spacer()
                                HStack { Spacer()
                                    Text("\(description.count)/300").font(.caption2).foregroundColor(.secondary).padding(8)
                                }
                            }.frame(height: 115)
                        }
                        .onChange(of: description) { _, new in
                            if new.count > 300 { description = String(new.prefix(300)) }
                        }
                    }

                    // Location
                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel("Last Seen Location")
                        if let coord = selectedCoordinate {
                            MiniMapPreview(coordinate: coord)
                                .frame(height: 140)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(white: 0.88), lineWidth: 1))
                        }
                        Button { showMapPicker = true } label: {
                            HStack {
                                Text(location.isEmpty ? "Select location" : location)
                                    .font(.subheadline)
                                    .foregroundColor(location.isEmpty ? Color(white: 0.55) : .primary)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                                Image(systemName: selectedCoordinate == nil ? "map" : "map.fill")
                                    .foregroundColor(selectedCoordinate == nil ? .secondary : .brand)
                            }
                            .padding().background(cardBg)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(white: 0.88), lineWidth: 1))
                        }
                        .fullScreenCover(isPresented: $showMapPicker) {
                            MapLocationPicker(selectedLocation: $location, selectedCoordinate: $selectedCoordinate)
                        }
                    }

                    // Reward banner (Lost only)
                    if reportType == .lost {
                        Button { goToReward = true } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "gift").foregroundColor(.brand).font(.title3)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Add a Reward (optional)").font(.subheadline).bold().foregroundColor(.primary)
                                    Text("Offering a reward can motivate people to help and increase trust in your report.")
                                        .font(.caption).foregroundColor(.secondary).multilineTextAlignment(.leading)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").foregroundColor(.secondary)
                            }
                            .padding().background(cardBg)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.brand.opacity(0.4), lineWidth: 1))
                        }
                    }

                    // Main button
                    Button {
                        if reportType == .lost { goToReward = true }
                        // else: TODO post found-pet to Firebase
                    } label: {
                        Text(reportType == .lost ? "Continue" : "Post")
                            .font(.headline).foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding()
                            .background(Color.brand)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.top, 4).padding(.bottom, 24)
                }
                .padding(.horizontal, 16).padding(.top, 12)
            }
            .onTapGesture {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
        .navigationTitle("Report a Pet")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left").fontWeight(.semibold)
                        Text("Home")
                    }.foregroundColor(.brand)
                }
            }
        }
        .navigationDestination(isPresented: $goToReward) { AddRewardView() }
    }
}

// MARK: - Screen 2: Add a Reward
struct AddRewardView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var rewardAmountText = ""
    @State private var applePayCoord    = ApplePayCoordinator()
    @State private var showMoyasar      = false

    var cardBg: Color  { Color(red: 0.97, green: 0.95, blue: 0.91) }
    var pageBg: Color  { Color(red: 0.99, green: 0.98, blue: 0.96) }
    var boostBg: Color { Color(red: 1.00, green: 0.97, blue: 0.88) }

    // Fixed visibility fee — platform revenue
    let visibilityFee: Double = 9.0

    var rewardValue:     Double { Double(rewardAmountText) ?? 0 }
    var totalCharge:     Double { rewardValue + visibilityFee }
    var rewardFormatted: String { String(format: "%.0f", rewardValue) }
    var totalFormatted:  String { String(format: "%.0f", totalCharge) }
    var totalHalala:     Int    { Int(totalCharge * 100) }
    var canPay:          Bool   { rewardValue >= 1 }

    var body: some View {
        ZStack {
            pageBg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // ── Header ──
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(Color.brand.opacity(0.15)).frame(width: 46, height: 46)
                            Image(systemName: "gift.fill").foregroundColor(.brand).font(.title3)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Add a Reward").font(.subheadline).bold()
                            Text("Every reward post gets 24h priority visibility — automatically.")
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }
                    .padding().background(cardBg).clipShape(RoundedRectangle(cornerRadius: 14))

                    // ── Reward Amount Input ──
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reward Amount").font(.subheadline).bold()
                        Text("Reserved fully for whoever finds your pet.")
                            .font(.caption).foregroundColor(.secondary)

                        HStack(alignment: .center, spacing: 0) {
                            Text("SAR")
                                .font(.headline).bold()
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 14)
                            Divider().frame(height: 28)
                            TextField("0", text: $rewardAmountText)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(canPay ? .primary : Color(white: 0.55))
                                .padding(.horizontal, 14)
                            Spacer()
                        }
                        .frame(height: 64)
                        .background(cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(
                            canPay ? Color.brand : Color(white: 0.86),
                            lineWidth: canPay ? 2 : 1))
                    }

                    // ── Priority Reach card (always visible) ──
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            Image(systemName: "bolt.fill")
                                .foregroundColor(Color.brand)
                                .font(.subheadline)
                            Text("Priority Reach — Included with every reward")
                                .font(.subheadline).bold()
                        }

                        VStack(spacing: 8) {
                            BoostFeatureRow(icon: "flame.fill",
                                           color: Color(red: 0.95, green: 0.45, blue: 0.15),
                                           text: "24-hour highlighted listing in the feed")
                            BoostFeatureRow(icon: "arrow.up.circle.fill",
                                           color: Color(red: 0.25, green: 0.60, blue: 0.90),
                                           text: "Priority placement on the home page")
                            BoostFeatureRow(icon: "eye.fill",
                                           color: Color(red: 0.35, green: 0.70, blue: 0.45),
                                           text: "Higher visibility across all feeds")
                            BoostFeatureRow(icon: "star.fill",
                                           color: Color.brand,
                                           text: "Reward badge shown on your post")
                        }
                    }
                    .padding(16)
                    .background(boostBg)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.brand.opacity(0.35), lineWidth: 1))

                    // ── Checkout summary — live ──
                    if canPay {

                  
                    VStack(spacing: 0) {

                        CheckoutRow(
                            label: "Reward Promise",
                            sublabel: "Displayed publicly on your post",
                            amount: "\(rewardFormatted) SAR",
                            isTotal: false,
                            icon: "gift.fill"
                        )

                        Divider().padding(.horizontal, 16)

                        CheckoutRow(
                            label: "Visibility Boost",
                            sublabel: "24h highlighted listing included",
                            amount: "9 SAR",
                            isTotal: false,
                            icon: "bolt.fill"
                        )

                        Divider().padding(.horizontal, 16)

                        CheckoutRow(
                            label: "Total Charged Now",
                            sublabel: "Platform visibility fee",
                            amount: "\(totalFormatted) SAR",
                            isTotal: true,
                            icon: nil
                        )
                    }
                    .background(cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(white: 0.86), lineWidth: 1)
                    )

                    // Disclaimer
                    HStack(alignment: .top, spacing: 8) {

                        Image(systemName: "info.circle")
                            .foregroundColor(.brand)
                            .font(.caption)

                        Text("The reward amount is displayed publicly on your post only and is handled privately between you and the finder. Paw only charges a 9 SAR visibility fee for promoting your post for 24 hours.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .background(Color.brand.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    // ── Payment buttons ──
                    VStack(spacing: 10) {

                        // Apple Pay
                        Button {

                            applePayCoord.onSuccess = {

                                // TODO:
                                // Save reward amount to Firebase
                                // Save highlight expiry = now + 24h
                                // Publish post

                                dismiss()
                            }

                            applePayCoord.present(
                                amount: Decimal(totalCharge),
                                label: "Paw — 24h Visibility Boost"
                            )

                        } label: {

                            HStack(spacing: 8) {

                                Image(systemName: "applelogo")
                                    .font(.subheadline)

                                Text("Pay 9 SAR with Apple Pay")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        // Moyasar
                        Button {
                            showMoyasar = true
                        } label: {

                            HStack(spacing: 8) {

                                Image(systemName: "creditcard")
                                    .font(.subheadline)

                                Text("Pay 9 SAR with Card / mada")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.brand)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .sheet(isPresented: $showMoyasar) {

                            MoyasarPaymentSheet(
                                amountHalala: totalHalala,
                                description: "Paw — 24h Priority Visibility",
                                callbackURL: "paw://payment-success",

                                onSuccess: {

                                    showMoyasar = false

                                    // TODO:
                                    // Save reward amount
                                    // Save highlighted = true
                                    // Save highlight expiry = now + 24h
                                    // Publish post

                                    dismiss()
                                },

                                onCancel: {
                                    showMoyasar = false
                                }
                            )
                        }

                        Text("Your reward amount is shown publicly, but only the 9 SAR visibility fee is charged.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 2)

                        // Network badges
                        HStack(spacing: 10) {

                            Spacer()

                            PaymentBadge(label: "Visa")
                            PaymentBadge(label: "Mastercard")
                            PaymentBadge(label: "mada")
                            PaymentBadge(label: "STC Pay")

                            Spacer()
                        }
                    }
                    

                    } else {

                   
                    VStack(spacing: 0) {

                        CheckoutRow(
                            label: "Reward Promise",
                            sublabel: "Enter an amount above",
                            amount: "— SAR",
                            isTotal: false,
                            icon: "gift.fill"
                        )

                        Divider().padding(.horizontal, 16)

                        CheckoutRow(
                            label: "Visibility Boost",
                            sublabel: "24h highlighted listing included",
                            amount: "9 SAR",
                            isTotal: false,
                            icon: "bolt.fill"
                        )

                        Divider().padding(.horizontal, 16)

                        CheckoutRow(
                            label: "Total Charged Now",
                            sublabel: "Platform visibility fee",
                            amount: "9 SAR",
                            isTotal: true,
                            icon: nil
                        )
                    }
                    .background(cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(white: 0.86), lineWidth: 1)
                    )

                    Button { }
                    label: {

                        Text("Enter a reward amount to continue")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(white: 0.78))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(true)
                   

                    }

                    // Post without reward
                    Button {
                        // TODO: post without reward to Firebase
                    } label: {
                        Text("Post without a Reward")
                            .font(.subheadline).foregroundColor(.secondary)
                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                    }
                    .padding(.bottom, 28)
                }
                .padding(.horizontal, 16).padding(.top, 12)
            }
            .onTapGesture {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
        .navigationTitle("Reward Post")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left").fontWeight(.semibold)
                        Text("Back")
                    }.foregroundColor(.brand)
                }
            }
        }
    }
}

// Boost feature bullet row
struct BoostFeatureRow: View {
    let icon: String; let color: Color; let text: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundColor(color).font(.caption).frame(width: 18)
            Text(text).font(.caption).foregroundColor(.primary)
            Spacer()
        }
    }
}

// Checkout summary row
struct CheckoutRow: View {
    let label:    String
    let sublabel: String
    let amount:   String
    let isTotal:  Bool
    let icon:     String?

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            if let icon {
                Image(systemName: icon)
                    .foregroundColor(isTotal ? Color.brand : .secondary)
                    .font(.caption).frame(width: 18)
            } else {
                Spacer().frame(width: 18)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(isTotal ? .subheadline : .caption)
                    .fontWeight(isTotal ? .bold : .semibold)
                    .foregroundColor(isTotal ? .primary : .primary)
                Text(sublabel)
                    .font(.caption2).foregroundColor(.secondary)
            }
            Spacer()
            Text(amount)
                .font(isTotal ? .subheadline : .caption)
                .fontWeight(isTotal ? .bold : .semibold)
                .foregroundColor(isTotal ? Color.brand : .primary)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }
}

// Small payment network badge
struct PaymentBadge: View {
    let label: String
    var body: some View {
        Text(label)
            .font(.system(size: 9, weight: .semibold))
            .foregroundColor(.secondary)
            .padding(.horizontal, 7).padding(.vertical, 4)
            .background(Color(white: 0.92))
            .clipShape(RoundedRectangle(cornerRadius: 5))
    }
}

// MARK: - Shared Components

struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View { Text(text).font(.subheadline).bold().foregroundColor(.primary) }
}

struct SegmentButton: View {
    let label: String; let icon: String; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.caption)
                Text(label).font(.subheadline)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 10)
            .background(isSelected ? Color.brand : Color.clear)
            .foregroundColor(isSelected ? .white : .secondary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }.padding(3)
    }
}

struct GenderButton: View {
    let label: String; let icon: String; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack { Text(icon).font(.title3); Text(label).font(.subheadline) }
                .frame(maxWidth: .infinity).padding(.vertical, 12)
                .background(isSelected ? Color.brand : Color(white: 0.95))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(
                    isSelected ? Color.brand : Color(white: 0.88), lineWidth: 1))
        }
    }
}

struct FeeRow: View {
    let label: String; let amount: String; let isTotal: Bool
    var body: some View {
        HStack {
            Text(label)
                .font(isTotal ? .subheadline : .caption)
                .fontWeight(isTotal ? .bold : .regular)
                .foregroundColor(isTotal ? .primary : .secondary)
            Spacer()
            Text("\(amount) SAR")
                .font(isTotal ? .subheadline : .caption)
                .fontWeight(isTotal ? .bold : .regular)
                .foregroundColor(isTotal ? Color.brand : .secondary)
        }
        .padding(.horizontal, 16).padding(.vertical, 11)
    }
}

struct RewardReasonRow: View {
    let icon: String; let title: String; let subtitle: String
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon).foregroundColor(.brand).frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption).bold()
                Text(subtitle).font(.caption).foregroundColor(.secondary)
            }
        }
    }
}

#Preview { ReportAPetApp() }
