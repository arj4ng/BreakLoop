import SwiftUI
import UIKit

struct WallpaperEditorView: View {
    let draft: WallpaperEditorDraft
    let isSaving: Bool
    let onCancel: () -> Void
    let onSave: (WallpaperEditorDraft) -> Void

    @State private var workingDraft: WallpaperEditorDraft
    @State private var zoomScale: CGFloat = 1
    @State private var baseZoomScale: CGFloat = 1
    @State private var dragOffset: CGSize = .zero
    @State private var baseOffset: CGSize = .zero
    @State private var localUIImage: UIImage?
    @State private var canvasSize: CGSize = .zero

    init(
        draft: WallpaperEditorDraft,
        isSaving: Bool,
        onCancel: @escaping () -> Void,
        onSave: @escaping (WallpaperEditorDraft) -> Void
    ) {
        self.draft = draft
        self.isSaving = isSaving
        self.onCancel = onCancel
        self.onSave = onSave
        _workingDraft = State(initialValue: draft)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()

                wallpaperImageLayer(size: geo.size)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .gesture(magnifyGesture.simultaneously(with: dragGesture))
                    .onTapGesture(count: 2) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            zoomScale = 1
                            baseZoomScale = 1
                            dragOffset = .zero
                            baseOffset = .zero
                        }
                    }

                VStack {
                    topBar
                        .padding(.top, max(topSafeAreaInset() + 6, 16))
                    Spacer()
                }

                VStack {
                    Spacer()
                    controls
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                }

                if isSaving {
                    Color.black.opacity(0.45).ignoresSafeArea()
                    ProgressView("Saving wallpaper")
                        .foregroundStyle(.white)
                }
            }
            .onAppear {
                canvasSize = geo.size
                bootstrapGestureState()
                localUIImage = loadLocalUIImage()
            }
            .onChange(of: geo.size.width) { _, _ in
                canvasSize = geo.size
                realignOffsetToCurrentTransform()
            }
            .onChange(of: geo.size.height) { _, _ in
                canvasSize = geo.size
                realignOffsetToCurrentTransform()
            }
        }
        .ignoresSafeArea()
    }

    private var topBar: some View {
        HStack {
            Button("Cancel") { onCancel() }
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.42), in: Capsule())

            Spacer()

            Text("Preview")
                .font(.headline)
                .foregroundStyle(.white)

            Spacer()

            Button("Save") {
                var out = workingDraft
                let transform = currentTransform(for: canvasSize)
                let norm = WallpaperTransform.normalizedPan(
                    offsetX: dragOffset.width,
                    offsetY: dragOffset.height,
                    maxOffsetX: transform.maxOffsetX,
                    maxOffsetY: transform.maxOffsetY
                )
                out.zoomScale = Double(zoomScale)
                out.panXNorm = Double(norm.x)
                out.panYNorm = Double(norm.y)
                out.imagePixelWidth = currentImagePixelSize().width
                out.imagePixelHeight = currentImagePixelSize().height
                onSave(out)
            }
            .foregroundStyle(.white)
            .disabled(isSaving)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.42), in: Capsule())
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func wallpaperImageLayer(size: CGSize) -> some View {
        let transform = currentTransform(for: size)
        let clamped = WallpaperTransform.clampOffset(
            offsetX: dragOffset.width,
            offsetY: dragOffset.height,
            maxOffsetX: transform.maxOffsetX,
            maxOffsetY: transform.maxOffsetY
        )

        if let localUIImage {
            Image(uiImage: localUIImage)
                .resizable()
                .scaledToFill()
                .frame(width: size.width, height: size.height)
                .scaleEffect(zoomScale)
                .offset(x: clamped.width, y: clamped.height)
                .blur(radius: workingDraft.blurRadius)
                .overlay(Color.black.opacity(0.16))
                .clipped()
        } else if let url = workingDraft.displayURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: size.width, height: size.height)
                        .scaleEffect(zoomScale)
                        .offset(x: clamped.width, y: clamped.height)
                        .blur(radius: workingDraft.blurRadius)
                        .overlay(Color.black.opacity(0.16))
                        .clipped()
                case .failure:
                    VStack(spacing: 8) {
                        Text("Could not load image")
                            .foregroundStyle(.white.opacity(0.85))
                        Button("Close") { onCancel() }
                            .foregroundStyle(.white)
                    }
                    .frame(width: size.width, height: size.height)
                default:
                    ProgressView().frame(width: size.width, height: size.height)
                }
            }
        } else {
            Color.black.frame(width: size.width, height: size.height)
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Blur")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.8))

            HStack(spacing: 12) {
                Slider(value: Binding(
                    get: { workingDraft.blurRadius },
                    set: { workingDraft.blurRadius = $0 }
                ), in: 0...30)
                .tint(.white)

                Text("\(Int(workingDraft.blurRadius))")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(width: 28)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func currentImagePixelSize() -> CGSize {
        if let localUIImage {
            return CGSize(width: localUIImage.size.width * localUIImage.scale, height: localUIImage.size.height * localUIImage.scale)
        }
        if workingDraft.imagePixelWidth > 0, workingDraft.imagePixelHeight > 0 {
            return CGSize(width: workingDraft.imagePixelWidth, height: workingDraft.imagePixelHeight)
        }
        return CGSize(width: 1, height: 1)
    }

    private func currentTransform(for size: CGSize) -> WallpaperTransform {
        WallpaperTransform.resolve(
            imagePixelSize: currentImagePixelSize(),
            canvasSize: size,
            zoom: zoomScale,
            panXNorm: CGFloat(workingDraft.panXNorm),
            panYNorm: CGFloat(workingDraft.panYNorm)
        )
    }

    private func bootstrapGestureState() {
        zoomScale = CGFloat(max(workingDraft.zoomScale, 1))
        baseZoomScale = zoomScale
        let transform = currentTransform(for: canvasSize)
        dragOffset = CGSize(width: transform.offsetX, height: transform.offsetY)
        baseOffset = dragOffset
    }

    private func realignOffsetToCurrentTransform() {
        let transform = currentTransform(for: canvasSize)
        let clamped = WallpaperTransform.clampOffset(
            offsetX: dragOffset.width,
            offsetY: dragOffset.height,
            maxOffsetX: transform.maxOffsetX,
            maxOffsetY: transform.maxOffsetY
        )
        dragOffset = clamped
        baseOffset = clamped
    }

    private func loadLocalUIImage() -> UIImage? {
        guard let path = workingDraft.cachedLocalPath else { return nil }
        return UIImage(contentsOfFile: path)
    }

    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                zoomScale = min(max(baseZoomScale * value.magnification, 1), 4)
                realignOffsetToCurrentTransform()
            }
            .onEnded { _ in
                baseZoomScale = zoomScale
                baseOffset = dragOffset
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let candidateX = baseOffset.width + value.translation.width
                let candidateY = baseOffset.height + value.translation.height
                let transform = currentTransform(for: canvasSize)
                dragOffset = WallpaperTransform.clampOffset(
                    offsetX: candidateX,
                    offsetY: candidateY,
                    maxOffsetX: transform.maxOffsetX,
                    maxOffsetY: transform.maxOffsetY
                )
            }
            .onEnded { _ in
                baseOffset = dragOffset
            }
    }

    private func topSafeAreaInset() -> CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: { $0.isKeyWindow })?
            .safeAreaInsets.top ?? 0
    }
}
