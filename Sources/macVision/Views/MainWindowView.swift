import SwiftUI

struct MainWindowView: View {
    let appState: AppState
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceTransparency) private var systemReduceTransparency
    @Environment(\.scenePhase) private var scenePhase
    @State private var hoveredSection: AppSection?

    private var opaque: Bool { systemReduceTransparency || appState.presentation.reduceTransparency }

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Rectangle().fill(VisionStyle.hairline).frame(width: 1)
            ScrollView {
                VStack(alignment: .leading, spacing: VisionStyle.sectionGap) {
                    switch appState.selectedSection {
                    case .overview: OverviewPane(appState: appState)
                    case .gestures: GesturesPane(appState: appState)
                    case .practice: PracticePane(appState: appState)
                    case .settings: PreferencesPane(appState: appState)
                    }
                }
                .padding(VisionStyle.pagePadding)
                .padding(.top, 20)
                .frame(maxWidth: 780, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .top)
            }
            .background(VisionStyle.canvas(scheme).opacity(opaque ? 1 : 0.94))
        }
        .background {
            if opaque { VisionStyle.canvas(scheme) }
            else { GlassMaterial(material: .underWindowBackground) }
        }
        .background(WindowAppearance().frame(width: 0, height: 0))
        .font(.system(size: 13))
        .tint(VisionStyle.green)
        .frame(minWidth: 800, minHeight: 600)
        .ignoresSafeArea(.container, edges: .top)
        .preferredColorScheme(appState.presentation.colorScheme)
        .sheet(isPresented: Binding(get: { appState.showsOnboarding }, set: { appState.showsOnboarding = $0 })) {
            OnboardingView(appState: appState)
                .preferredColorScheme(appState.presentation.colorScheme)
        }
        .onAppear {
            if !appState.hasPresentedOnboarding {
                appState.hasPresentedOnboarding = true
                appState.showsOnboarding = !appState.settings.preferences.onboardingComplete
            }
        }
        .onChange(of: appState.selectedSection) { _, section in
            if section == .practice && appState.actionsEnabled { appState.setActionsEnabled(false) }
        }
        .onChange(of: appState.showsOnboarding) { _, shown in
            if shown && appState.actionsEnabled { appState.setActionsEnabled(false) }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { appState.refreshPermissions(); appState.presentation.refreshLoginStatus() }
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 28) {
            HStack(spacing: 9) {
                AppMark(size: 30)
                Text("mac\(Text("Vision").fontWeight(.semibold))")
                    .font(.system(size: 15)).tracking(-0.4)
            }
            .padding(.horizontal, 10)

            VStack(spacing: 4) {
                ForEach(AppSection.allCases) { section in
                    Button {
                        appState.selectedSection = section
                    } label: {
                        HStack(spacing: 9) {
                            Image(systemName: section.symbol).font(.system(size: 14))
                                .foregroundStyle(appState.selectedSection == section ? VisionStyle.green : .secondary)
                                .frame(width: 18)
                            Text(section == .practice ? "Practice" : section.title).font(.system(size: 13, weight: appState.selectedSection == section ? .medium : .regular))
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 10).frame(height: 38)
                        .contentShape(Rectangle())
                        .background(appState.selectedSection == section ? VisionStyle.green.opacity(0.10) : hoveredSection == section ? Color.primary.opacity(0.035) : .clear,
                                    in: RoundedRectangle(cornerRadius: 9))
                    }
                    .buttonStyle(.plain)
                    .onHover { hoveredSection = $0 ? section : nil }
                    .help(section.title)
                    .accessibilityLabel(section.title)
                    .accessibilityAddTraits(appState.selectedSection == section ? .isSelected : [])
                }
            }
            Spacer()
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 7) {
                    Circle().fill(appState.isActive ? VisionStyle.green : Color.secondary.opacity(0.6))
                        .frame(width: 6, height: 6)
                    Text(appState.modeTitle).font(.system(size: 11, weight: .medium))
                }
                Divider()
                Label("Processed on this Mac", systemImage: "lock.shield")
                    .font(.system(size: 10)).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
        }
        .padding(.horizontal, 10).padding(.top, 54).padding(.bottom, 20)
        .frame(width: 204)
        .background {
            if opaque { VisionStyle.canvas(scheme) }
            else { GlassMaterial(material: .sidebar) }
        }
    }
}
