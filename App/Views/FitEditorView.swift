import SwiftUI

/// Finjustér placering, størrelse og rotation af det tøj sælen har på.
struct FitEditorView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    /// Ting der kan justeres (påtaget tøj, evt. en ting man prøver i butikken).
    let itemIDs: [String]

    @State private var draft: [String: ItemFit] = [:]
    @State private var selected: String = ""
    @State private var dragStart: ItemFit?
    @State private var pinchStart: ItemFit?
    @State private var rotateStart: ItemFit?

    private let previewSize: CGFloat = 280
    private typealias A = Tuning.Accessory

    private var items: [ShopItem] { itemIDs.compactMap { ShopCatalog.item($0) } }

    private var current: ItemFit { draft[selected] ?? .identity }

    var body: some View {
        let p = store.profile
        let hat = items.first { $0.slot == .hat }?.id
        let glasses = items.first { $0.slot == .glasses }?.id
        let neck = items.first { $0.slot == .neck }?.id

        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    if items.isEmpty {
                        Text("Tag noget tøj på i butikken først – så kan du tilpasse det her.")
                            .font(.rounded(16, .semibold))
                            .foregroundStyle(Theme.inkSoft)
                            .multilineTextAlignment(.center)
                            .card()
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Theme.oceanLight)
                            SealFigure(color: p.color, state: .content, hat: hat, glasses: glasses, neck: neck,
                                       animated: false, fits: draft)
                                .frame(width: previewSize, height: previewSize)
                        }
                        .frame(height: previewSize + 30)
                        .contentShape(Rectangle())
                        .gesture(dragGesture)
                        .simultaneousGesture(pinchGesture)
                        .simultaneousGesture(rotateGesture)

                        Text("Træk for at flytte · knib for størrelse · drej med to fingre")
                            .font(.rounded(12, .semibold))
                            .foregroundStyle(Theme.inkSoft)

                        picker
                        sliders
                    }
                }
                .padding(16)
            }
            .background(Theme.cream.ignoresSafeArea())
            .navigationTitle("Tilpas tøj")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annullér") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Gem") { saveAndClose() }.bold()
                }
            }
        }
        .onAppear {
            var d: [String: ItemFit] = [:]
            for id in itemIDs { d[id] = FitStore.shared.fit(id) }
            draft = d
            if selected.isEmpty { selected = items.first?.id ?? "" }
        }
    }

    // MARK: Vælg ting

    private var picker: some View {
        HStack(spacing: 8) {
            ForEach(items) { item in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { selected = item.id }
                } label: {
                    VStack(spacing: 2) {
                        Text(item.emoji).font(.system(size: 20))
                        Text(item.name)
                            .font(.rounded(12, .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .foregroundStyle(selected == item.id ? Theme.oceanDark : Theme.inkSoft)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(selected == item.id ? Theme.oceanLight : Color.white))
                }
                .buttonStyle(BouncyStyle())
            }
        }
    }

    // MARK: Skydere

    private var sliders: some View {
        VStack(alignment: .leading, spacing: 14) {
            fitSlider("Vandret", value: binding(\.dx), range: -A.maxOffset...A.maxOffset, step: 0.005,
                      label: String(format: "%.0f", current.dx * 100))
            fitSlider("Lodret", value: binding(\.dy), range: -A.maxOffset...A.maxOffset, step: 0.005,
                      label: String(format: "%.0f", current.dy * 100))
            fitSlider("Størrelse", value: binding(\.scale), range: A.minScale...A.maxScale, step: 0.01,
                      label: String(format: "%.0f%%", current.scale * 100))
            fitSlider("Rotation", value: binding(\.rotation), range: -180...180, step: 1,
                      label: String(format: "%.0f°", current.rotation))

            HStack(spacing: 10) {
                nudge("arrow.left") { change { $0.dx -= 0.005 } }
                nudge("arrow.right") { change { $0.dx += 0.005 } }
                nudge("arrow.up") { change { $0.dy -= 0.005 } }
                nudge("arrow.down") { change { $0.dy += 0.005 } }
                Spacer()
                Button("Nulstil") {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { draft[selected] = .identity }
                }
                .font(.rounded(15, .bold))
                .foregroundStyle(Theme.oceanDark)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(Theme.ice))
            }
        }
        .card()
    }

    private func fitSlider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).font(.rounded(15, .bold)).foregroundStyle(Theme.ink)
                Spacer()
                Text(label)
                    .font(.rounded(13, .heavy))
                    .foregroundStyle(Theme.oceanDark)
                    .monospacedDigit()
            }
            Slider(value: value, in: range, step: step)
                .tint(Theme.oceanDeep)
        }
    }

    private func nudge(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .heavy))
                .foregroundStyle(Theme.oceanDark)
                .frame(width: 36, height: 36)
                .background(Circle().fill(Theme.ice))
        }
        .buttonStyle(BouncyStyle())
    }

    private func binding(_ key: WritableKeyPath<ItemFit, Double>) -> Binding<Double> {
        Binding(
            get: { current[keyPath: key] },
            set: { v in change { $0[keyPath: key] = v } }
        )
    }

    private func change(_ f: (inout ItemFit) -> Void) {
        guard !selected.isEmpty else { return }
        var fit = current
        f(&fit)
        fit.dx = min(A.maxOffset, max(-A.maxOffset, fit.dx))
        fit.dy = min(A.maxOffset, max(-A.maxOffset, fit.dy))
        fit.scale = min(A.maxScale, max(A.minScale, fit.scale))
        if fit.rotation > 180 { fit.rotation -= 360 }
        if fit.rotation < -180 { fit.rotation += 360 }
        draft[selected] = fit
    }

    // MARK: Fagter

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { v in
                if dragStart == nil { dragStart = current }
                guard let start = dragStart else { return }
                change {
                    $0.dx = start.dx + Double(v.translation.width / previewSize)
                    $0.dy = start.dy + Double(v.translation.height / previewSize)
                }
            }
            .onEnded { _ in dragStart = nil }
    }

    private var pinchGesture: some Gesture {
        MagnifyGesture()
            .onChanged { v in
                if pinchStart == nil { pinchStart = current }
                guard let start = pinchStart else { return }
                change { $0.scale = start.scale * Double(v.magnification) }
            }
            .onEnded { _ in pinchStart = nil }
    }

    private var rotateGesture: some Gesture {
        RotateGesture()
            .onChanged { v in
                if rotateStart == nil { rotateStart = current }
                guard let start = rotateStart else { return }
                change { $0.rotation = start.rotation + v.rotation.degrees }
            }
            .onEnded { _ in rotateStart = nil }
    }

    private func saveAndClose() {
        let fs = FitStore.shared
        for (id, fit) in draft { fs.set(fit, for: id) }
        fs.save()
        store.syncOutside()
        dismiss()
    }
}
