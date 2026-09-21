import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject private var pairing: PairingStore
    @EnvironmentObject private var session: SpoofSession
    @Environment(\.dismiss) private var dismiss

    @State private var showImporter = false
    @State private var showPairOnDevice = false
    @State private var showNameEasterEgg = false
    @State private var tunnelIP = TunnelConfig.targetIP
    @State private var localDevVPNInstalled = LocalDevVPN.isInstalled
    @State private var tunnelConnected = LocalDevVPN.isConnected
    @Environment(\.scenePhase) private var scenePhase

    private var supportsOnDevicePairing: Bool {
        if #available(iOS 27.0, *) { return true }
        return false
    }

    private var appVersion: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.2"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        let label = short.hasSuffix("-zh") ? short : "\(short)-zh"
        return build.isEmpty ? label : "\(label) (\(build))"
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label {
                        Text(pairing.hasPairingFile ? "已安装 RPPairing 文件" : "尚未导入配对文件")
                    } icon: {
                        Image(systemName: pairing.hasPairingFile ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(pairing.hasPairingFile ? LocusTheme.statusGood : LocusTheme.statusWarn)
                    }

                    if supportsOnDevicePairing {
                        Button {
                            showPairOnDevice = true
                        } label: {
                            Label("在本机配对", systemImage: "iphone.gen3.radiowaves.left.and.right")
                        }
                    }

                    Button("导入 RPPairing 文件…") { showImporter = true }
                    Button("从剪贴板粘贴 RPPairing") {
                        do {
                            try pairing.importPairingFromClipboard()
                        } catch {
                            session.lastError = error.localizedDescription
                        }
                    }
                    if pairing.hasPairingFile {
                        Button("移除配对文件", role: .destructive) {
                            try? pairing.removePairing()
                        }
                    }
                } header: {
                    Text("开发者配对")
                } footer: {
                    Text(supportsOnDevicePairing
                         ? "在 iOS 27 上可使用「在本机配对」，无需电脑。Locus 会广播可配对主机；请在 设置 › 隐私与安全性 › 开发者模式 › 与主机配对 中确认 6 位验证码。较旧系统请从 idevice_pair 导入 RPPairing 文件（不要用 SideStore 的 .mobiledevicepairing）。LiveContainer：请为 Locus 开启 Fix File Picker，或使用粘贴 / 分享 → LiveContainer → Locus。"
                         : "请从 idevice_pair 导入 RPPairing 文件（不要用 SideStore 的 .mobiledevicepairing）。若文件选择器失败（LiveContainer 中很常见），请开启 Fix File Picker，将文件分享到 LiveContainer → Locus，或复制 plist 后使用粘贴。")
                }

                Section {
                    TextField("设备隧道 IP", text: $tunnelIP)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onSubmit {
                            TunnelConfig.setTargetIP(tunnelIP)
                        }
                    LabeledContent("状态") {
                        Text(tunnelConnected ? "已连接" : "未连接")
                            .foregroundStyle(tunnelConnected ? LocusTheme.statusGood : LocusTheme.statusWarn)
                    }
                    Button("保存隧道 IP") {
                        TunnelConfig.setTargetIP(tunnelIP)
                        refreshTunnel()
                    }
                    Button {
                        if localDevVPNInstalled {
                            LocalDevVPN.openInstalled()
                        } else {
                            LocalDevVPN.openAppStore()
                        }
                    } label: {
                        Label(
                            localDevVPNInstalled ? "打开 LocalDevVPN" : "获取 LocalDevVPN（App Store）",
                            systemImage: localDevVPNInstalled ? "lock.shield.fill" : "arrow.down.app.fill"
                        )
                    }
                } header: {
                    Text("隧道")
                } footer: {
                    Text("传送前请先连接 LocalDevVPN。对端隧道 IP 默认为 10.7.0.1（本机接口多为 10.7.1.1）。建议先在 Wi‑Fi 下启动模拟，之后蜂窝网络也可继续。")
                }

                Section("隐私") {
                    Text("完全在本机运行。收藏与最近记录仅保存在 UserDefaults。无分析、无账号、无上传。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("关于") {
                    LabeledContent("版本", value: appVersion)
                    LabeledContent("引擎", value: "idevice DVT 定位模拟")
                    Text("Locus 免费开源（MIT）。定位注入使用 MIT 许可的 idevice FFI。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button {
                        showNameEasterEgg = true
                    } label: {
                        Text("locus，名词——地点。源自拉丁语，意为你所在之处。")
                            .font(.footnote.italic())
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            }
            .navigationTitle("设置")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") {
                        TunnelConfig.setTargetIP(tunnelIP)
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showImporter) {
            PairingDocumentPicker(
                onPick: { url in
                    showImporter = false
                    do {
                        try pairing.importPairing(from: url)
                    } catch {
                        session.lastError = error.localizedDescription
                    }
                },
                onCancel: { showImporter = false }
            )
            .ignoresSafeArea()
        }
            .sheet(isPresented: $showPairOnDevice) {
                PairOnDeviceView()
                    .environmentObject(pairing)
            }
            .fullScreenCover(isPresented: $showNameEasterEgg) {
                LocusEasterEggView()
            }
            .onAppear { refreshTunnel() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { refreshTunnel() }
            }
            .task(id: scenePhase) {
                guard scenePhase == .active else { return }
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    refreshTunnel()
                }
            }
        }
    }

    private func refreshTunnel() {
        localDevVPNInstalled = LocalDevVPN.isInstalled
        tunnelConnected = LocalDevVPN.isConnected
    }
}

struct PlacesView: View {
    @EnvironmentObject private var session: SpoofSession
    @EnvironmentObject private var pairing: PairingStore
    @Environment(\.dismiss) private var dismiss

    @State private var placeToRename: SavedPlace?
    @State private var renameText = ""

    var body: some View {
        NavigationStack {
            List {
                Section("收藏") {
                    if session.favorites.isEmpty {
                        Text("在地图上给图钉加星即可收藏。")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(session.favorites) { place in
                        placeButton(place)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    session.removeFavorite(place)
                                } label: {
                                    Label("删除", systemImage: "trash.fill")
                                }
                                Button {
                                    placeToRename = place
                                    renameText = place.name
                                } label: {
                                    Label("重命名", systemImage: "pencil")
                                }
                                .tint(.gray)
                            }
                    }
                }

                Section("最近") {
                    if session.recents.isEmpty {
                        Text("传送记录会出现在这里。")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(session.recents) { place in
                        placeButton(place)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    session.removeRecent(place)
                                } label: {
                                    Label("删除", systemImage: "trash.fill")
                                }
                            }
                    }
                }
            }
            .navigationTitle("地点")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") { dismiss() }
                }
            }
            .alert("重命名收藏", isPresented: Binding(
                get: { placeToRename != nil },
                set: { if !$0 { placeToRename = nil } }
            )) {
                TextField("名称", text: $renameText)
                Button("取消", role: .cancel) {
                    placeToRename = nil
                }
                Button("保存") {
                    if let place = placeToRename {
                        session.renameFavorite(place, to: renameText)
                    }
                    placeToRename = nil
                }
            } message: {
                Text("取一个之后容易认出的名字。")
            }
        }
    }

    private func placeButton(_ place: SavedPlace) -> some View {
        Button {
            session.teleport(to: place.coordinate, pairing: pairing)
            dismiss()
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(place.name).foregroundStyle(.primary)
                Text(String(format: "%.5f, %.5f", place.latitude, place.longitude))
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
        }
    }
}
