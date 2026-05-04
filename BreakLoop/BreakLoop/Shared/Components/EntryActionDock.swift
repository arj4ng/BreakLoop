// BreakLoop/ BreakLoop/ Shared/ Components/ EntryActionDock.swift

// entry action dock
//
// Created by Arjang Khademi on 27.04.2026
/*
  ╔════════════════════════════════════════════════════════╗
  ║  █████╗ ██████╗      ██╗ ██╗  ██╗ ███╗   ██╗  ██████╗  ║
  ║ ██╔══██╗██╔══██╗     ██║ ██║  ██║ ████╗  ██║ ██╔════╝  ║
  ║ ███████║██████╔╝     ██║ ███████║ ██╔██╗ ██║ ██║  ███╗ ║
  ║ ██╔══██║██╔══██╗██   ██║ ╚════██║ ██║╚██╗██║ ██║   ██║ ║
  ║ ██║  ██║██║  ██║╚█████╔╝      ██║ ██║ ╚████║ ╚██████╔╝ ║
  ║ ╚═╝  ╚═╝╚═╝  ╚═╝ ╚════╝       ╚═╝ ╚═╝  ╚═══╝  ╚═════╝  ║
  ╚═════════════════════════════════════════ [ DEV TAG ] ══╝
*/

import SwiftUI


// MARK: ┏━ [13 UI COMPONENTS] EntryActionDock
// MARK: ┗━ Bottom dock für consume slide action + purchase quick button

struct EntryActionDock: View {
    let onPurchaseTap: () -> Void
    let onConsumeCompleted: () -> Void

    @State private var slideProgress: CGFloat = 0
    @State private var isConsumeExpanded: Bool = false

    var body: some View {
        GeometryReader { geo in
            // breite wird dynamisch geteilt, damit dock auf allen geräten passt
            let spacing: CGFloat = 10
            let totalWidth = geo.size.width
            let halfWidth = max(0, (totalWidth - spacing) / 2)
            let sliderWidth = isConsumeExpanded ? totalWidth : halfWidth

            ZStack(alignment: .leading) {
                HStack(spacing: spacing) {
                    Color.clear
                        .frame(width: halfWidth, height: 64)

                    Button(action: onPurchaseTap) {
                        dockCard(
                            title: "New Purchase",
                            value: "Add entry",
                            icon: "cart.fill",
                            accent: AppColors.accentStrong
                        )
                    }
                    .hapticTap(.medium)
                    .frame(width: halfWidth, height: 64)
                    // purchase button verschwindet während consume slider expandiert
                    .opacity(isConsumeExpanded ? 0 : 1)
                    .allowsHitTesting(!isConsumeExpanded)
                    .buttonStyle(PressableCardButtonStyle())
                }

                PressHoldActionButton(
                    onCompleted: {
                        onConsumeCompleted()

                        withAnimation(.easeInOut(duration: 0.18)) {
                            isConsumeExpanded = false
                        }
                        slideProgress = 0
                    },
                    onProgress: { progress in
                        slideProgress = progress
                    },
                    content: {
                        dockCard(
                            title: "Slide To Log",
                            value: "Consume",
                            icon: "plus.circle.fill",
                            accent: AppColors.accent
                        )
                    }
                )
                .frame(width: sliderWidth, height: 64, alignment: .leading)
                .clipped()
                .simultaneousGesture(
                    // erster touch öffnet slider auf volle breite
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if !isConsumeExpanded {
                                withAnimation(.easeInOut(duration: 0.18)) {
                                    isConsumeExpanded = true
                                }
                            }
                        }
                        .onEnded { _ in
                            if slideProgress < 0.98 {
                                withAnimation(.easeInOut(duration: 0.18)) {
                                    isConsumeExpanded = false
                                }
                                slideProgress = 0
                            }
                        }
                )
            }
        }
        .frame(height: 64)
        .animation(.easeInOut(duration: 0.18), value: isConsumeExpanded)
    }

    private func dockCard(title: String, value: String, icon: String, accent: Color) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .appTypography(AppTypography.caption1)
                    .foregroundStyle(AppColors.textSecondary)

                Text(value)
                    .appTypography(AppTypography.bodyEmphasis)
                    .foregroundStyle(AppColors.textPrimary)
            }

            Spacer()

            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(accent)
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity)
        .frame(height: 64)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.surfaceElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppColors.borderStrong.opacity(0.45), lineWidth: 1)
                )
        )
    }
}


// MARK: ┏━ [13 UI COMPONENTS] PressHoldActionButton
// MARK: ┗━ Slide handle mit progress overlay und complete callback

private struct PressHoldActionButton<Content: View>: View {
    let onCompleted: () -> Void
    var onProgress: ((CGFloat) -> Void)? = nil
    @ViewBuilder let content: () -> Content

    @State private var dragOffset: CGFloat = 0
    @State private var dragAnchor: CGFloat? = nil
    @State private var didComplete = false
    @GestureState private var isDragging = false
    @GestureState private var isPressed = false

    private let cornerRadius: CGFloat = 16
    private let handleSize: CGSize = .init(width: 56, height: 56)
    private let handleInset: CGFloat = 6

    var body: some View {
        GeometryReader { proxy in
            // maxTravel = komplette strecke vom handle bis rechts
            let totalWidth = proxy.size.width
            let totalHeight = proxy.size.height
            let maxTravel = max(0, totalWidth - (handleSize.width + (handleInset * 2)))
            let progressCG: CGFloat = (maxTravel > 0) ? (dragOffset / maxTravel) : 0
            let progress = Double(max(0, min(1, progressCG)))
            let isSliding = isPressed || isDragging || dragOffset > 0 || progress > 0

            ZStack(alignment: .leading) {
                content()
                    .opacity(isSliding ? 0 : 1)
                    .animation(.easeInOut(duration: 0.12), value: isSliding)
                progressFillOverlay(progress: progress, dragOffset: dragOffset, handleInset: handleInset)
                slideTextOverlay(progress: progress, dragOffset: dragOffset)

                ZStack {
                    Circle()
                        .fill(AppColors.textInverse.opacity(0.92))
                        .overlay(Circle().stroke(AppColors.borderStrong.opacity(0.25), lineWidth: 1))
                        .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 1)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(AppColors.textSecondary)
                }
                .frame(width: handleSize.width, height: handleSize.height)
                .padding(.leading, handleInset)
                .offset(x: dragOffset)
                .opacity((isPressed || isDragging || dragOffset > 0) ? 1 : 0)
                .scaleEffect((isPressed || isDragging || dragOffset > 0) ? 1 : 0.92)
                .accessibilityHidden(true)
            }
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AppColors.borderStrong.opacity(0.45), lineWidth: 1)
            )
            .highPriorityGesture(dragGesture(maxTravel: maxTravel))
            .simultaneousGesture(
                // zeigt handle sofort beim drücken, nicht erst nach drag
                LongPressGesture(minimumDuration: 0, maximumDistance: 30)
                    .updating($isPressed) { _, state, _ in state = true }
            )
            .onChange(of: progress) { _, newValue in
                onProgress?(CGFloat(newValue))
            }
            .onChange(of: isPressed) { oldValue, pressed in
                if !pressed && !didComplete {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                        dragOffset = 0
                        dragAnchor = nil
                    }
                    onProgress?(0)
                }
            }
            .onChange(of: didComplete) { _, done in
                if done {
                    onProgress?(1)
                }
            }
            .frame(width: proxy.size.width, height: totalHeight)
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isButton)
        .frame(minHeight: 56)
    }

    private func dragGesture(maxTravel: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .updating($isDragging) { _, state, _ in state = true }
            .onChanged { value in
                if dragAnchor == nil {
                    // startposition wird auf handle mitte normalisiert
                    let startX = value.startLocation.x
                    let desiredOffset = max(0, min(maxTravel, startX - handleInset - (handleSize.width / 2)))
                    dragAnchor = desiredOffset - value.translation.width
                    dragOffset = desiredOffset
                }

                let anchor = dragAnchor ?? 0
                let x = anchor + value.translation.width
                dragOffset = max(0, min(maxTravel, x))
            }
            .onEnded { _ in
                dragAnchor = nil
                let progressCG: CGFloat = (maxTravel > 0) ? (dragOffset / maxTravel) : 0
                let progress = Double(max(0, min(1, progressCG)))

                if progress >= 0.98 {
                    complete()
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                        dragOffset = 0
                    }
                }
            }
    }

    private func complete() {
        guard !didComplete else { return }
        didComplete = true
        HapticService.success()

        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
            dragOffset = 0
        }

        onCompleted()

        // kurzer lock verhindert doppeltes feuern direkt nach complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            didComplete = false
        }
    }

    @ViewBuilder
    private func progressFillOverlay(progress: Double, dragOffset: CGFloat, handleInset: CGFloat) -> some View {
        GeometryReader { _ in
            if progress > 0 {
                let gradient = LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: AppColors.textInverse.opacity(0.24), location: 0),
                        .init(color: AppColors.textInverse.opacity(0.18), location: 0.7),
                        .init(color: AppColors.textInverse.opacity(0.01), location: 1.0)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )

                Rectangle()
                    .fill(gradient)
                    .frame(width: dragOffset + handleInset + 80)
                    .transition(.opacity)
            }
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func slideTextOverlay(progress: Double, dragOffset: CGFloat) -> some View {
        GeometryReader { proxy in
            if isPressed || isDragging || dragOffset > 0 || progress > 0 {
                let revealWidth = proxy.size.width * progress
                let baseText = Text("SLIDE TO LOG")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .tracking(1.2)

                ZStack {
                    baseText.foregroundStyle(AppColors.textPrimary.opacity(0.35))

                    baseText
                        .foregroundStyle(AppColors.textPrimary.opacity(0.85))
                        .mask(alignment: .leading) {
                            Rectangle().frame(width: revealWidth)
                        }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .allowsHitTesting(false)
    }
}

private struct PressableCardButtonStyle: ButtonStyle {
    var disablePressTransform: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed && !disablePressTransform

        return configuration.label
            .scaleEffect(pressed ? 0.98 : 1.0)
            .brightness(pressed ? -0.03 : 0)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(AppColors.borderStrong.opacity(pressed ? 0.45 : 0.25), lineWidth: 1)
            )
            .shadow(
                color: Color.black.opacity(pressed ? 0.08 : 0.15),
                radius: pressed ? 2 : 4,
                x: 0,
                y: pressed ? 1 : 2
            )
    }
}
