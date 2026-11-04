import SwiftUI

struct ShopView: View {
    @Environment(GameStore.self) private var store
    @State private var slot: ItemSlot = .hat
    @State private var tryOn: ShopItem?
    @State private var celebrate = 0
    @State private var shake = 0
    @State private var message: String?
    @Namespace private var ns

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                HStack {
                    Text("Butik")
                        .font(.rounded(32, .heavy))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    FishCounter(fish: store.profile.fish)
                }
                .padding(.top, 12)

                preview

                slotPicker

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(Array(ShopCatalog.items(in: slot).enumerated()), id: \.element.id) { i, item in
                        ShopItemCard(item: item, selected: tryOn?.id == item.id) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { tryOn = item }
                        } onAction: {
                            act(on: item)
                        }
                        .appearIn(Double(i) * 0.05)
                    }
                }
                .id(slot)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Theme.cream.ignoresSafeArea())
    }

    private var preview: some View {
        let p = store.profile
        let hat = tryOn?.slot == .hat ? tryOn?.id : p.hat
        let glasses = tryOn?.slot == .glasses ? tryOn?.id : p.glasses
        let neck = tryOn?.slot == .neck ? tryOn?.id : p.neck
        let bg = tryOn?.slot == .background ? (tryOn?.id ?? p.background) : p.background
        return ZStack {
            SceneBackground(id: bg)
                .id(bg)
                .transition(.opacity)
            SealFigure(color: p.color, state: .happy, hat: hat, glasses: glasses, neck: neck)
                .frame(width: 170, height: 170)
                .offset(y: 20)
                .modifier(Wiggle(active: shake % 2 == 1))
            BurstView(trigger: celebrate, emojis: ["✨", "🎉", "💙", "🐟"], count: 14)
            if let message {
                Text(message)
                    .font(.rounded(15, .bold))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(.white))
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.top, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .frame(height: 250)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .animation(.easeInOut(duration: 0.5), value: bg)
    }

    private var slotPicker: some View {
        HStack(spacing: 6) {
            ForEach(ItemSlot.allCases) { s in
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        slot = s
                        tryOn = nil
                    }
                } label: {
                    VStack(spacing: 2) {
                        Text(s.icon).font(.system(size: 20))
                        Text(s.title).font(.rounded(12, .bold))
                    }
                    .foregroundStyle(slot == s ? Theme.oceanDark : Theme.inkSoft)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background {
                        if slot == s {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Theme.oceanLight)
                                .matchedGeometryEffect(id: "slot", in: ns)
                        }
                    }
                }
                .buttonStyle(BouncyStyle())
            }
        }
        .padding(6)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.white))
    }

    private func act(on item: ShopItem) {
        if store.owns(item) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                store.equip(item)
                tryOn = nil
            }
            return
        }
        if !item.isInSeason {
            flash("Kommer tilbage i \(item.seasonName.lowercased()) 🎁")
            return
        }
        if store.buy(item) {
            celebrate += 1
            tryOn = nil
            flash("Ny ting! \(store.profile.name) elsker den 💙")
        } else {
            shake += 1
            let missing = item.price - store.profile.fish
            flash("Du mangler \(missing) fisk – de kommer!")
        }
    }

    private func flash(_ text: String) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { message = text }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            if message == text {
                withAnimation(.easeOut) { message = nil }
            }
            shake = 0
        }
    }
}

struct ShopItemCard: View {
    @Environment(GameStore.self) private var store
    let item: ShopItem
    let selected: Bool
    var onTry: () -> Void
    var onAction: () -> Void

    var body: some View {
        let owned = store.owns(item)
        let equipped = store.isEquipped(item)
        VStack(spacing: 8) {
            Button(action: onTry) {
                ZStack(alignment: .topTrailing) {
                    Group {
                        if item.slot == .background {
                            ScenePreview(id: item.id).frame(height: 90)
                        } else {
                            AccessoryView(item: item, s: 150)
                                .frame(height: 90)
                                .frame(maxWidth: .infinity)
                                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.ice))
                        }
                    }
                    if item.isSeasonal {
                        Text(item.isInSeason ? "Sæson ✨" : item.seasonName)
                            .font(.rounded(10, .heavy))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(item.isInSeason ? Theme.rose : Theme.inkSoft))
                            .padding(6)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(BouncyStyle(scale: 0.95))

            Text(item.name)
                .font(.rounded(15, .heavy))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Button(action: onAction) {
                Group {
                    if owned {
                        Text(equipped ? "Tag af" : "Tag på")
                    } else {
                        Text("\(item.price) 🐟")
                    }
                }
                .font(.rounded(15, .heavy))
                .foregroundStyle(owned && equipped ? Theme.oceanDark : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(Capsule().fill(buttonColor(owned: owned, equipped: equipped)))
            }
            .buttonStyle(BouncyStyle())
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(selected ? Theme.ocean : (equipped ? Theme.mint : .clear), lineWidth: 3)
                )
                .shadow(color: Theme.oceanDark.opacity(0.06), radius: 8, x: 0, y: 4)
        )
        .scaleEffect(selected ? 1.03 : 1)
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: selected)
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: equipped)
    }

    private func buttonColor(owned: Bool, equipped: Bool) -> Color {
        if owned { return equipped ? Theme.oceanLight : Theme.mintDark }
        if !item.isInSeason { return Theme.iceDark }
        return store.profile.fish >= item.price ? Theme.oceanDeep : Theme.inkSoft.opacity(0.6)
    }
}
