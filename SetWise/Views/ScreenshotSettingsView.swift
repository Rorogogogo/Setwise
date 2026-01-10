import SwiftUI
import AppKit

struct ScreenshotSettingsView: View {
    @ObservedObject var viewModel: ScreenshotSettingsViewModel
    @State private var showOrganizerSettings = false

    var body: some View {
        let locationBinding = Binding<String>(
            get: { viewModel.editedSettings.location },
            set: { _ in }
        )
        let formatBinding = Binding<ScreenshotFormat>(
            get: { viewModel.editedSettings.format },
            set: { viewModel.editedSettings.format = $0 }
        )
        let shadowBinding = Binding<Bool>(
            get: { viewModel.editedSettings.shadowsEnabled },
            set: { viewModel.editedSettings.shadowsEnabled = $0 }
        )

        VStack(alignment: .leading, spacing: 16) {
            if let banner = viewModel.statusBanner {
                StatusBannerView(banner: banner)
            }

            Form {
                Section("Save Location") {
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("", text: locationBinding)
                            .textFieldStyle(.roundedBorder)
                            .disabled(true)
                            .textSelection(.enabled)

                        HStack(spacing: 8) {
                            Button("Choose Folder...") {
                                chooseFolder()
                            }

                            Button {
                                viewModel.copyLocationToPasteboard()
                            } label: {
                                Label("Copy Path", systemImage: "doc.on.doc")
                            }

                            Button {
                                viewModel.openLocationInFinder()
                            } label: {
                                Label("Open Folder", systemImage: "folder")
                            }
                        }
                    }
                }

                Section("Image Format") {
                    Picker("Screenshot Format", selection: formatBinding) {
                        ForEach(ScreenshotFormat.allCases) { format in
                            Text(format.displayName).tag(format)
                        }
                    }
                }

                Section("Shadow") {
                    Toggle("Enable Drop Shadow", isOn: shadowBinding)
                }

                Section {
                    Text("Choose a folder to clean by moving images and recordings into dated subfolders.")
                        .font(.callout)
                        .foregroundColor(.secondary)

                    Button("Choose Folder to Clean...") {
                        chooseFolderToClean()
                    }
                    .disabled(viewModel.organizerIsWorking)

                    if viewModel.organizerIsWorking {
                        ProgressView()
                            .controlSize(.small)
                    }
                } header: {
                    HStack {
                        Text("Organizer")
                        Spacer()
                        Button {
                            showOrganizerSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                        }
                        .buttonStyle(.borderless)
                        .help("Organizer options")
                    }
                }

                Section {
                    if viewModel.needsRestartNote {
                        HStack(alignment: .center, spacing: 8) {
                            Text("⚠️ Requires restarting SystemUIServer for changes to take effect.")
                                .font(.callout)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button("Restart SystemUIServer") {
                                viewModel.requestRestart()
                            }
                        }
                    }

                    HStack {
                        if viewModel.isWorking {
                            ProgressView()
                                .controlSize(.small)
                        }
                        Spacer()
                        Button("Restore Defaults") {
                            viewModel.restoreDefaults()
                        }
                        .disabled(!viewModel.canRestore)

                        Button("Apply Changes") {
                            viewModel.applyChanges()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!viewModel.canApply)
                    }
                }
            }
            .formStyle(.grouped)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .navigationTitle("Screenshot")
        .task {
            viewModel.loadIfNeeded()
        }
        .alert("Restart SystemUIServer?", isPresented: $viewModel.showRestartConfirmation) {
            Button("Restart", role: .destructive) {
                viewModel.restartSystemUIServer()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This refreshes the menu bar and applies screenshot changes immediately.")
        }
        .sheet(isPresented: $showOrganizerSettings) {
            OrganizerSettingsView()
        }
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.prompt = "Choose"

        if panel.runModal() == .OK, let url = panel.url {
            viewModel.updateLocation(url.path)
        }
    }

    private func chooseFolderToClean() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = false
        panel.prompt = "Clean"

        if panel.runModal() == .OK, let url = panel.url {
            viewModel.organizeFolder(at: url)
        }
    }
}
