import SwiftUI
import AlertToast

struct PostBubble: View {
    @Binding var post : Post
    @EnvironmentObject var feedVM : FeedViewModel
    @StateObject var postBubbleVM = PostBubbleViewModel()
    
    // MARK: Some local view logic
    @State private var showScore = false
    @State private var sheet = false
    
    var body: some View {
        VStack {
            ZStack {
                NavigationLink(destination: PostView(post: $post)) {
                    EmptyView()
                }
                .opacity(0.0)
                .buttonStyle(PlainButtonStyle())
                
                HStack(alignment: .top) {
                    VStack(alignment: .leading) {
                        Text("\(post.timeSincePosted)")
                            .font(.caption)
                            .padding(.bottom, 4)
          
                        Text(post.title)
                            .multilineTextAlignment(.leading)
                        
//                        if let imageUrl = postBubbleVM.post.image {
//                            let _ = print("DEBUG: \(postBubbleVM.post.image)")
//                            let _ = print("DEBUG: \(imageUrl)")
//                            AsyncImage(url: URL(string: imageUrl)) { image in
//                                image.resizable()
//                            } placeholder: {
//                                ProgressView()
//                            }
//                            .frame(width: 50, height: 50)
//                        }
                        
                        // MARK: Poll
                        if post.poll != nil {
                            PollView(post: $post)
                        }
                    }
                    .padding(.bottom)
                    
                    Spacer()
                    
                    VoteComponent
                }
            }

            Color.black.frame(height:CGFloat(1) / UIScreen.main.scale)

            HStack {
                
                ZStack {
                    NavigationLink(destination: PostView(post: $post)) {
                        EmptyView()
                    }
                    .opacity(0.0)
                    .buttonStyle(PlainButtonStyle())
                    
                    HStack {
                        Image(systemName: "bubble.left")
                        Text("\(post.numComments)")
                            .font(.subheadline).bold()

                        Spacer()
                    }
                }

                
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    sheet.toggle()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .sheet(isPresented: $sheet) {
                    ShareSheet(items: ["ponged: \(postBubbleVM.post.title)"])
                }
                
                // MARK: Delete or More Button
                if post.userOwned {
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        DispatchQueue.main.async {
                            postBubbleVM.post = postBubbleVM.post
                            postBubbleVM.showDeleteConfirmationView.toggle()
                        }
                    } label: {
                        Image(systemName: "trash")
                    }
                } else {
                    Menu {
                        if post.saved {
                            Button {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                postBubbleVM.unsavePost(post: post)
                            } label: {
                                Label("Unsave", systemImage: "bookmark.fill")
                            }
                        } else if !post.saved {
                            Button {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                postBubbleVM.savePost(post: post)
                            } label: {
                                Label("Save", systemImage: "bookmark")
                            }
                        }
                        
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            postBubbleVM.blockPost(post: post, feedVM: feedVM)
                        } label: {
                            Label("Block user", systemImage: "x.circle")
                        }
                        
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            postBubbleVM.reportPost(post: post, feedVM: feedVM)
                        } label: {
                            Label("Report", systemImage: "flag")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .frame(width: 30, height: 30)
                    }
                    .frame(width: 25, height: 25)
                }
            }
        }
        .font(.system(size: 18).bold())
        .padding(0)
        .padding(.top, 10)
        .onChange(of: postBubbleVM.post) { change in
            self.post = postBubbleVM.post
        }
        
        // MARK: Delete Confirmation
        .alert(isPresented: $postBubbleVM.showDeleteConfirmationView) {
            Alert(
                title: Text("Delete post"),
                message: Text("Are you sure you want to delete \(post.title)"),
                primaryButton: .destructive(Text("Delete")) {
                    postBubbleVM.deletePost(post: post, feedVM: feedVM)
                },
                secondaryButton: .cancel()
            )
        }
        .toast(isPresenting: $postBubbleVM.savedPostConfirmation){
            AlertToast(type: .regular, title: "Post saved!")
        }
    }
    
    var VoteComponent: some View {
        VStack {
            if !showScore {
                // if not upvoted or downvoted
                if post.voteStatus == 0 {
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        postBubbleVM.postVote(direction: 1, post: post)
                    } label: {
                        Image(systemName: "arrow.up")
                    }
                    
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        withAnimation {
                            showScore.toggle()
                        }

                    } label: {
                        Text("\(post.score)")
                    }
                    
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        postBubbleVM.postVote(direction: -1, post: post)
                    } label: {
                        Image(systemName: "arrow.down")
                    }
                } else if post.voteStatus == 1 {
                    // if upvoted
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        postBubbleVM.postVote(direction: 1, post: post)
                    } label: {
                        Image(systemName: "arrow.up")
                            .foregroundColor(.yellow)
                    }
                    
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        withAnimation {
                            showScore.toggle()
                        }

                    } label: {
                        Text("\(post.score + 1)")
                    }
                    
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        postBubbleVM.postVote(direction: -1, post: post)
                    } label: {
                        Image(systemName: "arrow.down")
                    }
                }
                // IF POST BUBBLE IS DOWNVOTES
                else if post.voteStatus == -1 {
                    // upvote
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        postBubbleVM.postVote(direction: 1, post: post)
                    } label: {
                        Image(systemName: "arrow.up")
                    }
                    
                    // score
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        withAnimation {
                            showScore.toggle()
                        }
                    } label: {
                        Text("\(post.score - 1)")
                    }
                    
                    // downvote
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        postBubbleVM.postVote(direction: -1, post: post)
                    } label: {
                        Image(systemName: "arrow.down")
                            .foregroundColor(.yellow)
                    }
                }
            } else {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    withAnimation {
                        showScore.toggle()
                    }

                } label: {
                    VStack {
                        if post.voteStatus == 1 {
                            Text("\(post.numUpvotes + 1)")
                                .foregroundColor(.green)
                            Text("\(post.numDownvotes)")
                                .foregroundColor(.red)
                        }
                        else if post.voteStatus == -1 {
                            Text("\(post.numUpvotes)")
                                .foregroundColor(.green)
                            Text("\(post.numDownvotes + 1)")
                                .foregroundColor(.red)
                        }
                        else if post.voteStatus == 0 {
                            Text("\(post.numUpvotes)")
                                .foregroundColor(.green)
                            Text("\(post.numDownvotes)")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
        }
        .frame(width: 25, height: 50)
    }
}



struct PostBubbleView_Previews: PreviewProvider {
    static var previews: some View {
        PostBubble(post: .constant(defaultPost))
    }
}
