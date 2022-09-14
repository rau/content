import SwiftUI

struct AdminFeedView: View {
    // MARK: ViewModels
    @StateObject var adminFeedVM = AdminFeedViewModel()
    
    //        ScrollView(showsIndicators: false) {
    //            LazyVStack {
    //               ForEach($adminFeedVM.flaggedPosts, id: \.id) { $post in
    //                    AdminPostBubble(post: $post)
    //                        .buttonStyle(PlainButtonStyle())
    //                        .environmentObject(adminFeedVM)
    //                }
    //            }
    //            .padding(.top)
    //        }
    
    var body: some View {
        VStack {
            toolbarPickerComponent
                .padding(.vertical)
            
            TabView(selection: $adminFeedVM.selectedFilter) {
                ForEach(AdminFilter.allCases, id: \.self) { tab in
                    List {
                       ForEach($adminFeedVM.flaggedPosts, id: \.id) { $post in
                            AdminPostBubble(post: $post)
                                .buttonStyle(PlainButtonStyle())
                                .environmentObject(adminFeedVM)
                        }
                    }
                    .refreshable {
                        print("DEBUG: Refresh")
                    }
                }
                .background(Color(UIColor.secondarySystemBackground))
            }
            .background(Color(UIColor.systemGroupedBackground))
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
        }
        .onAppear {
            adminFeedVM.getPosts()
        }
        .navigationBarTitle("Admin View")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    var toolbarPickerComponent : some View {
        HStack(spacing: 30) {
            ForEach(AdminFilter.allCases, id: \.self) { filter in
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    adminFeedVM.selectedFilter = filter
                } label: {
                    if adminFeedVM.selectedFilter == filter {
                        HStack(spacing: 5) {
                            Image(systemName: filter.filledImageName)
                            Text(filter.title)
                                .bold()
                        }
                        .shadow(color: SchoolManager.shared.schoolPrimaryColor(), radius: 10, x: 0, y: 0)
                        .foregroundColor(SchoolManager.shared.schoolPrimaryColor())

                    } else {
                        HStack(spacing: 5) {
                            Image(systemName: filter.imageName)
                            Text(filter.title)
                        }
                        .foregroundColor(SchoolManager.shared.schoolPrimaryColor())
                    }
                }
            }
        }
    }
}

struct AdminFeedView_Previews: PreviewProvider {
    static var previews: some View {
        AdminFeedView()
    }
}
