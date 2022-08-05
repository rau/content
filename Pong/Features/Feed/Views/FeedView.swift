//
//  FeedView.swift
//  SidechatMockup
//
//  Created by Khoi Nguyen on 6/3/22.
//

import SwiftUI
import ScalingHeaderScrollView

struct FeedView: View {
    @Namespace var animation
    @State var selectedFilter: FeedFilterViewModel = .hot
    // observed objects
    @ObservedObject var feedVM: FeedViewModel
    @ObservedObject var postSettingsVM: PostSettingsViewModel
    // variables
    @State private var isRefreshing = false
    @State private var offset = CGSize.zero
    // tracks scroll to top on recentposts on new post
    @State private var newPost = false
    var school: String // will need to filter entire page by community

    init(school: String, selectedFilter: FeedFilterViewModel, feedVM: FeedViewModel, postSettingsVM: PostSettingsViewModel) {
        self.school = school
        self.selectedFilter = selectedFilter
        self.feedVM = feedVM
        self.postSettingsVM = postSettingsVM
    }
    
    var body: some View {
        // ORIGINAL
        NavigationView {
            VStack(spacing: 0) {
                feedFilterBar
                feedItself
            }
            .navigationTitle("Harvard")
        }
    }
    
    var feedFilterBar: some View {
        HStack {
            ForEach(FeedFilterViewModel.allCases, id: \.rawValue) { item in
                VStack {
                    Text(item.title)
                        .font(.subheadline.bold())
                        .foregroundColor(selectedFilter == item ? Color(UIColor.label) : .gray)
                    if selectedFilter == item {
                        Capsule()
                            .foregroundColor(Color(.systemBlue))
                            .frame(height: 3)
                            .matchedGeometryEffect(id: "filter", in: animation)
                    } else {
                        Capsule()
                            .foregroundColor(Color(.clear))
                            .frame(height: 3)
                    }
                }
                .onTapGesture {
                    withAnimation(.easeInOut) {
                        self.selectedFilter = item
                    }
                }
            }
        }
        .background(Color(UIColor.tertiarySystemBackground))
        .overlay(Divider().offset(x: 0, y: 16))
    }
    
    var feedItself: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $selectedFilter) {
                ForEach(FeedFilterViewModel.allCases, id: \.self) { view in
                    RefreshableScrollView {
                        ScrollViewReader { scrollReader in
                            // actual stack of post bubbles
                            LazyVStack {
                                // top
                                if view == .top {
                                    ForEach(feedVM.topPosts, id: \.self) { post in
                                        NavigationLink(destination: PostView(post: post)) {
                                            PostBubble(post: post, postSettingsVM: postSettingsVM)
                                        }
                                    }
                                }
                                // hot
                                else if view == .hot {
                                    ForEach(feedVM.hotPosts, id: \.self) { post in
                                        NavigationLink(destination: PostView(post: post)) {
                                            PostBubble(post: post, postSettingsVM: postSettingsVM)
                                        }
                                    }
                                }
                                // recent
                                else if view == .recent {
                                    ForEach(feedVM.recentPosts, id: \.self) { post in
                                        NavigationLink(destination: PostView(post: post)) {
                                            PostBubble(post: post, postSettingsVM: postSettingsVM)
                                        }
                                    }
                                }
                            }
                            .padding(.bottom, 150)
                            .onChange(of: newPost, perform: { value in
                                if value {
                                    print("DEBUG: Switch and Scroll to Top")
                                    selectedFilter = .recent
                                    scrollReader.scrollTo("top") // scrolls to component with id "top" which is a spacer piece in PullToRefresh view
                                    newPost = false
                                    feedVM.getPosts(selectedFilter: selectedFilter)
                                }
                            })
                        }
                    }
                    .refreshable {
                        feedVM.getPosts(selectedFilter: selectedFilter)
                    }
                    .onAppear {
//                        if !feedVM.topPostsInitalOpen && selectedFilter == .top {
//                            feedVM.getPosts(selectedFilter: .top)
//                        } else if !feedVM.hotPostsInitalOpen && selectedFilter == .hot {
//                            feedVM.getPosts(selectedFilter: .hot)
//                        } else if !feedVM.recentPostsInitalOpen && selectedFilter == .recent {
//                            feedVM.getPosts(selectedFilter: .recent)
//                        }
                        if selectedFilter == .top {
                            feedVM.getPosts(selectedFilter: .top)
                        } else if selectedFilter == .hot {
                            feedVM.getPosts(selectedFilter: .hot)
                        } else if selectedFilter == .recent {
                            feedVM.getPosts(selectedFilter: .recent)
                        }
                        feedVM.getPostsAlamofire(selectedFilter: selectedFilter)
                    }
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .ignoresSafeArea(.all, edges: .bottom)
            
            // NewPost Overlay
            NavigationLink {
                NewPostView(newPost: $newPost)
            } label: {
                Image(systemName: "arrowshape.bounce.forward.fill")
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: 50, height: 50)
                    .padding()
                    .foregroundColor(Color(UIColor.tertiarySystemBackground))
                    .background(Color(UIColor.label))
                    .clipShape(Circle())
                    .padding()
                    .shadow(radius: 10)
            }
        }
    }
}

struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView(school: "Harvard", selectedFilter: .hot, feedVM: FeedViewModel(), postSettingsVM: PostSettingsViewModel())
    }
}
