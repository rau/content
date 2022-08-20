import SwiftUI
import Firebase
import UniformTypeIdentifiers

struct SettingsView: View {
    @StateObject private var settingsVM = SettingsViewModel()
    
    @State private var notifications = false
    
    var body: some View {
        LoadingView(isShowing: .constant(false)) {
            List {
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String)
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("Build")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleVersion"] as! String)
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("Environment")
                        Spacer()
                        #if DEBUG
                            Text("Debug")
                                .foregroundColor(.gray)
                        #else
                            Text("Release")
                                .foregroundColor(.gray)
                        #endif
                    }
                }.modifier(ProminentHeaderModifier())
                Section(header: Text("Account").foregroundColor(.gray)) {
                    Button(action: {
                        UIPasteboard.general.setValue(DAKeychain.shared["userId"] ?? "Invalid",
                                    forPasteboardType: UTType.plainText.identifier)
                    }) {
                        HStack {
                            Text("User ID").foregroundColor(Color(uiColor: UIColor.label))
                            Spacer()
                            Text( DAKeychain.shared["userId"]?.prefix(16) ?? "Invalid")
                                .foregroundColor(.gray)
                        }
                    }
                    Button(action: {
                        UIPasteboard.general.setValue(DAKeychain.shared["token"] ?? "Invalid",
                                    forPasteboardType: UTType.plainText.identifier)
                    }) {
                        HStack {
                            Text("Token").foregroundColor(Color(uiColor: UIColor.label))
                            Spacer()
                            Text( DAKeychain.shared["token"]?.prefix(16) ?? "Invalid")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    if (AuthManager.authManager.isAdmin) {
                        NavigationLink(destination: AdminFeedView()){
                            HStack {
                                Text("Admin Feed View").foregroundColor(Color(uiColor: UIColor.label))
                                Spacer()
                            }
                        }
                    }
                    
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        AuthManager.authManager.signout()
                    } label: {
                        HStack {
                            Text("Sign Out").foregroundColor(.red)
                            Spacer()
                            Image(systemName: "arrow.uturn.left").foregroundColor(.red)
                        }
                    }
                    
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        print("DEBUG: Delete Account")
                    } label: {
                        HStack {
                            Text("Delete Account").foregroundColor(.red).bold()
                            Spacer()
                            Image(systemName: "trash").foregroundColor(.red).font(Font.body.weight(.bold))
                        }
                    }
                }.modifier(ProminentHeaderModifier())
                Section(header: Text("Preferences").foregroundColor(.gray)) {
                    HStack(spacing: 0) {
                        Text("Theme")
                        Spacer(minLength: 20)
                        Picker("Display Mode", selection: $settingsVM.displayMode) {
                            Text("System").tag(DisplayMode.system)
                            Text("Dark").tag(DisplayMode.dark)
                            Text("Light").tag(DisplayMode.light)
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: settingsVM.displayMode) { newValue in
                            settingsVM.displayMode.setAppDisplayMode()
                        }
                    }
                    Toggle("Notifications", isOn: $notifications)
                }.modifier(ProminentHeaderModifier())
                #if DEBUG
                Section(header: Text("Debug").foregroundColor(.gray)) {
                    Button(action: {
                        UIPasteboard.general.string = DAKeychain.shared["userId"]
                    }) {
                        Text("Copy User ID").foregroundColor(.pink)
                    }
                    Button(action: {
                        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
                        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { _, _ in }
                        UIApplication.shared.registerForRemoteNotifications()
                    }) {
                        Text("Register for APNS").foregroundColor(.blue)
                    }
                    Button(action: {
                        Messaging.messaging().token { token, error in
                          if let error = error {
                              UIPasteboard.general.string = "Error Fetching FCM Registration Token: \(error)"
                          } else if let token = token {
                              UIPasteboard.general.string = token
                          }
                        }
                    }) {
                        Text("Copy FCM Token").foregroundColor(.blue)
                    }
                }.modifier(ProminentHeaderModifier())
                #endif
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                UITableView.appearance().showsVerticalScrollIndicator = false
            }
//            .navigationBarTitleDisplayMode(.inline)
            .background(Color(UIColor.systemGroupedBackground))
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
