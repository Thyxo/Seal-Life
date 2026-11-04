import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(GameStore.self) private var store
    @State private var name = ""
    @State private var notifications = NotificationScheduler.enabled
    @State private var maxPerDay = NotificationScheduler.maxPerDay
    @State private var liveActivity = LiveActivityManager.enabled
    @State private var shareFile: ShareFile?
    @State private var importing = false
    @State private var status: String?
    @State private var confirmImportURL: URL?

    var body: some View {
        let p = store.profile
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                HStack {
                    Text("Mig & \(p.name)")
                        .font(.rounded(32, .heavy))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                }
                .padding(.top, 12)

                VStack(spacing: 12) {
                    SealFigure(color: p.color, state: store.displayState, hat: p.hat, glasses: p.glasses, neck: p.neck)
                        .frame(width: 140, height: 140)
                    TextField("Navn", text: $name)
                        .font(.rounded(22, .heavy))
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.ice))
                        .onSubmit { saveName() }
                    HStack(spacing: 10) {
                        ForEach(SealColor.allCases) { c in
                            Button {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                    p.color = c
                                    store.save()
                                    store.syncOutside()
                                }
                            } label: {
                                Text(c.displayName)
                                    .font(.rounded(14, .bold))
                                    .foregroundStyle(p.color == c ? .white : Theme.ink)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Capsule().fill(p.color == c ? Theme.oceanDeep : Theme.ice))
                            }
                            .buttonStyle(BouncyStyle())
                        }
                    }
                    Text("Humør: \(Int(p.mood)) / 100 · \(store.moodState.displayName)")
                        .font(.rounded(14, .semibold))
                        .foregroundStyle(Theme.inkSoft)
                }
                .card()
                .appearIn(0)

                VStack(alignment: .leading, spacing: 12) {
                    title("Påmindelser")
                    Toggle(isOn: $notifications) { rowText("Blide påmindelser fra sælen") }
                        .tint(Theme.oceanDeep)
                        .onChange(of: notifications) { _, v in
                            NotificationScheduler.enabled = v
                            if v { NotificationScheduler.requestAuthorization() }
                            store.syncOutside()
                        }
                    HStack {
                        rowText("Maks. pr. dag")
                        Spacer()
                        Picker("", selection: $maxPerDay) {
                            Text("1").tag(1)
                            Text("2").tag(2)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 120)
                        .onChange(of: maxPerDay) { _, v in
                            NotificationScheduler.maxPerDay = v
                            store.syncOutside()
                        }
                    }
                    Toggle(isOn: $liveActivity) { rowText("Sælen på låseskærmen (Live Activity)") }
                        .tint(Theme.oceanDeep)
                        .onChange(of: liveActivity) { _, v in
                            LiveActivityManager.enabled = v
                            store.syncOutside()
                        }
                }
                .card()
                .appearIn(0.06)

                VStack(alignment: .leading, spacing: 12) {
                    title("Backup")
                    Text("Sideloadede apps udløber efter 7 dage. Gem en backup, så du altid kan hente \(p.name) tilbage.")
                        .font(.rounded(14, .medium))
                        .foregroundStyle(Theme.inkSoft)
                    if let last = p.lastBackup {
                        Text("Sidste backup: \(last.formatted(date: .abbreviated, time: .shortened))")
                            .font(.rounded(13, .semibold))
                            .foregroundStyle(Theme.oceanDark)
                    }
                    Button("Eksportér backup") { exportBackup() }
                        .buttonStyle(SoftButtonStyle())
                    Button("Importér backup") { importing = true }
                        .buttonStyle(SoftButtonStyle(color: Theme.sand, foreground: Theme.ink))
                    if let status {
                        Text(status)
                            .font(.rounded(14, .semibold))
                            .foregroundStyle(Theme.ink)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .card()
                .appearIn(0.12)

                VStack(alignment: .leading, spacing: 8) {
                    title("Om Sælliv")
                    Text("Alt ligger lokalt på din telefon. Ingen konto, ingen server, ingen iCloud.")
                        .font(.rounded(14, .medium))
                        .foregroundStyle(Theme.inkSoft)
                    Text(AppGroup.isShared ? "Widget-deling: aktiv ✓" : "Widget-deling: ikke tilgængelig (App Group mangler)")
                        .font(.rounded(12, .semibold))
                        .foregroundStyle(Theme.inkSoft)
                    Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                        .font(.rounded(12, .semibold))
                        .foregroundStyle(Theme.inkSoft)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .card()
                .appearIn(0.18)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Theme.cream.ignoresSafeArea())
        .onAppear { name = store.profile.name }
        .onDisappear { saveName() }
        .sheet(item: $shareFile) { f in ActivityView(items: [f.url]) }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            if case .success(let url) = result { confirmImportURL = url }
        }
        .confirmationDialog("Importér backup?", isPresented: Binding(get: { confirmImportURL != nil }, set: { if !$0 { confirmImportURL = nil } }), titleVisibility: .visible) {
            Button("Ja, erstat mine data") {
                if let url = confirmImportURL { importBackup(url) }
                confirmImportURL = nil
            }
        } message: {
            Text("Det, der ligger i appen nu, bliver erstattet af backuppen.")
        }
    }

    private func title(_ t: String) -> some View {
        Text(t).font(.rounded(19, .heavy)).foregroundStyle(Theme.ink)
    }

    private func rowText(_ t: String) -> some View {
        Text(t).font(.rounded(15, .semibold)).foregroundStyle(Theme.ink)
    }

    private func saveName() {
        let clean = name.trimmingCharacters(in: .whitespaces)
        guard !clean.isEmpty, clean != store.profile.name else { return }
        store.profile.name = clean
        store.save()
        store.syncOutside()
    }

    private func exportBackup() {
        do {
            let url = try BackupManager.makeFile(store: store)
            shareFile = ShareFile(url: url)
            store.didExportBackup()
            show("Backup klar – gem den i Filer 💾")
        } catch {
            show("Hov, backuppen drillede. Prøv igen.")
        }
    }

    private func importBackup(_ url: URL) {
        do {
            try BackupManager.restore(from: url, store: store)
            name = store.profile.name
            show("Velkommen tilbage! Alt er hentet 💙")
        } catch {
            show(error.localizedDescription)
        }
    }

    private func show(_ text: String) {
        withAnimation(.spring) { status = text }
    }
}
