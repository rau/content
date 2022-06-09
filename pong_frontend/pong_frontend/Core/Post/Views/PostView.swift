//
//  PostView.swift
//  SidechatMockup
//
//  Created by Khoi Nguyen on 6/4/22.
//

import SwiftUI

struct PostView: View {
    @Environment(\.presentationMode) var mode
    @StateObject var viewModel = PostViewModel()
    @StateObject var componentViewModel = ComponentsViewModel()
    @State private var message = ""
    var post: Post
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                mainPost
                LazyVStack {
                    ForEach(post.comments) { comment in
                        CommentBubble(comment: comment)
                    }
                }
            }
           
            HStack {
                CustomTextField(placeholder: Text("Enter your message here"), text: $message)
                
                Button {
                    print("DEBUG: Message sent")
                    message = ""
                } label: {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(.indigo)
                        .cornerRadius(50)
                }
            }
            .padding()
            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.white, lineWidth: 2))
            .background(Color.white)
        }
    }
    
    var postHeader: some View {
        ZStack{
            HStack(alignment: .center) {
                Button {
                    mode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "arrow.left")
                }
                .padding()
                Spacer()
            }
        }
    }
    
    var mainPost: some View {
        ScrollView {
            LazyVStack{
                Button(action: {
                    print("DEBUG: Open Post")
                }) {
                    VStack{
                        
                        HStack(alignment: .top){
                            VStack(alignment: .leading){
                                
                                Text("\(post.user) ~ \(post.created_at)")
                                    .font(.caption)
                                    .padding(.bottom, 4)

                                                       
                                Text(post.title)
                                    .multilineTextAlignment(.leading)
                                
                            }
                            
                            Spacer()
                            
                            VStack{
                                Button {
                                    print("DEBUG: Upvote")
                                } label: {
                                    Image(systemName: "arrow.up")
                                }
                                Text("\(post.total_score)")
                                Button {
                                    print("DEBUG: Downvote")
                                } label: {
                                    Image(systemName: "arrow.down")
                                }

                            }
                            
                        }
                        .padding(.bottom)
                        

                        //
                        HStack {
                            // comments, share, mail, flag

                            Spacer()
                            
                            Button {
                                print("DEBUG: Share")
                            } label: {
                                Image(systemName: "square.and.arrow.up")
                            }
                            Button {
                                print("DEBUG: DM")
                            } label: {
                                Image(systemName: "envelope")
                            }
                            Button {
                                print("DEBUG: Report")
                            } label: {
                                Image(systemName: "flag")
                            }
                        }
                    }
                    .font(.system(size: 18).bold())
                    .padding()
                    .foregroundColor(.black)
                }
                .background(Color.white) // If you have this
                .cornerRadius(20)         // You also need the cornerRadius here
                ZStack {
                    Divider()
                    Text("\(post.num_comments) Comments")
                        .font(.caption)
                        .background(Rectangle().fill(.white).frame(minWidth: 90))
                        
                }

            }
        }
    }
}

struct PostView_Previews: PreviewProvider {
    static var previews: some View {
        PostView(post: default_post)
    }
}
