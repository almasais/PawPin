//
//  AIPage.swift
//  PawPin
//
//  Created by Afnan hassan on 01/12/1447 AH.
//


import SwiftUI
import AVFoundation
import PhotosUI
import Combine


// MARK: - Models
struct CatResult: Identifiable {
    let id = UUID()
    let name: String
    let color: String
    let eyes: String
    let district: String
    let isOnline: Bool
    let accentColor: Color
    let image: String // SF Symbol placeholder
}

// MARK: - Camera Manager
@MainActor
class CameraManager: NSObject, ObservableObject {
    
    let session = AVCaptureSession()
    @Published var isRunning = false

    override init() {
        super.init()
        configure()
    }

    private func configure() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else { session.commitConfiguration(); return }
        session.addInput(input)
        session.commitConfiguration()
    }

    func start() {
        guard !session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
            DispatchQueue.main.async { self.isRunning = true }
        }
    }

    func stop() {
        session.stopRunning()
        isRunning = false
    }
}

// MARK: - Camera Preview
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> VideoView {
        let v = VideoView()
        v.session = session
        return v
    }
    func updateUIView(_ uiView: VideoView, context: Context) {}

    class VideoView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var layer2: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
        var session: AVCaptureSession? {
            didSet {
                layer2.session = session
                layer2.videoGravity = .resizeAspectFill
            }
        }
    }
}

// MARK: - Camera Screen
struct CameraView: View {
    @StateObject private var cam = CameraManager()
    @State private var showResults = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var libraryThumb: UIImage?

    var body: some View {
        NavigationStack {
            ZStack {
                // Live camera
                CameraPreview(session: cam.session)
                    .ignoresSafeArea()

                // Top back arrow
                VStack {
                    HStack {
                        Button {
                            // back action
                        } label: {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .shadow(radius: 4)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 56)
                    Spacer()
                }

                // Bottom controls
                VStack {
                    Spacer()
                    HStack(alignment: .center, spacing: 0) {

                        // Library thumbnail
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.black.opacity(0.3))
                                    .frame(width: 52, height: 52)
                                if let img = libraryThumb {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 52, height: 52)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                } else {
                                    Image(systemName: "photo")
                                        .font(.system(size: 22))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)

                        // Shutter
                        Button {
                            showResults = true
                        } label: {
                            ZStack {
                                Circle()
                                    .stroke(Color.white, lineWidth: 3)
                                    .frame(width: 76, height: 76)
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 62, height: 62)
                            }
                        }
                        .frame(maxWidth: .infinity)

                        // Flip camera
                        Button {
                            // flip camera action
                        } label: {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 26, weight: .medium))
                                .foregroundColor(.white)
                                .shadow(radius: 4)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 48)
                }
            }
            .navigationDestination(isPresented: $showResults) {
                ResultsView()
            }
        }
        .onAppear { cam.start() }
        .onDisappear { cam.stop() }
        .onChange(of: selectedPhoto) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    await MainActor.run {
                        libraryThumb = img
                        showResults = true
                    }
                }
            }
        }
    }
}

// MARK: - Results Screen
struct ResultsView: View {
    @Environment(\.dismiss) private var dismiss

    private let cats: [CatResult] = [
        CatResult(name: "Oliver",   color: "Orange",      eyes: "Green Eyes",  district: "Alrabie District", isOnline: true,  accentColor: .green,  image: "cat"),
        CatResult(name: "Lost pet", color: "Black",       eyes: "Yellow Eyes", district: "Alrabie District", isOnline: false, accentColor: .orange, image: "cat"),
        CatResult(name: "Sara",     color: "White/Brown", eyes: "Grey Eyes",   district: "Alnahda District", isOnline: true,  accentColor: .blue,   image: "cat"),
        CatResult(name: "Oliver",   color: "Orange",      eyes: "Green Eyes",  district: "Alrabie District", isOnline: true,  accentColor: .green,  image: "cat"),
    ]

    @State private var selectedID: UUID? = nil

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                // Hero captured image
                heroImage

                // Results list
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(cats) { cat in
                            CatRow(cat: cat, isSelected: selectedID == cat.id)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedID = selectedID == cat.id ? nil : cat.id
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 100)
                }
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .offset(y: -24)
            }
            .ignoresSafeArea(edges: .top)

            // FAB
            Button {
                // add new cat
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.orange)
                    .clipShape(Circle())
                    .shadow(color: .orange.opacity(0.4), radius: 10, y: 4)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 36)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
        }
    }

    var heroImage: some View {
        ZStack {
            // Placeholder for captured cat photo
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color(.systemGray5), Color(.systemGray4)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 380)

            Image(systemName: "cat.fill")
                .font(.system(size: 90))
                .foregroundColor(.white.opacity(0.3))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 380)
    }
}

// MARK: - Cat Row
struct CatRow: View {
    let cat: CatResult
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 14) {
            // Cat thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray5))
                    .frame(width: 72, height: 72)
                Image(systemName: "cat.fill")
                    .font(.system(size: 30))
                    .foregroundColor(Color(.systemGray3))
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(cat.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)

                    Circle()
                        .fill(cat.isOnline ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                }

                Text("\(cat.color) , \(cat.eyes)")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)

                Text(cat.district)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    isSelected ? Color.blue : Color(.systemGray5),
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

#Preview {
    CameraView()
}


