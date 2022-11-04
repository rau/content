import SwiftUI

struct MessageView: View {
    @State private var text = ""
    @Binding var conversation: Conversation
    @StateObject var messageVM : MessageViewModel = MessageViewModel()
    @EnvironmentObject var dataManager : DataManager
    @Environment(\.presentationMode) var presentationMode
    @State var isLinkActive = false
    @State private var post = defaultPost

    // MARK: Body
    var body: some View {
        VStack(spacing: 0) {
            // MARK: Navigate to PostView Component
            Button {
                DispatchQueue.main.async {
                    messageVM.getPost(postId: conversation.postId!) { success in
                        post = success
                        isLinkActive = true
                    }
                }
            } label: {
                PostComponent
                    .background(Color.pongSystemBackground)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PlainButtonStyle())
            .onAppear() {
                messageVM.readPost(postId: conversation.postId!)
            }
            
            // MARK: Rest of the messaging
            ZStack() {
                // hidden postview
                NavigationLink(destination: PostView(post: $post), isActive: $isLinkActive) { EmptyView() }
                // MARK: Actual content of the conversation's messages
                ScrollViewReader { proxy in
                    List {
                        Rectangle()
                            .fill(Color.pongSystemBackground)
                            .frame(height: 50)
                            .listRowBackground(Color.pongSystemBackground)
                            .listRowSeparator(.hidden)
                            .id("bottom")
                        
                        ForEach(messageVM.conversation.messages.reversed(), id: \.id) { message in
                            chatBubble(userOwned: message.userOwned, message: message)
                                .flippedUpsideDown()
                                .listRowBackground(Color.pongSystemBackground)
                                .listRowSeparator(.hidden)
                        }
                    }
                    .scrollContentBackgroundCompat()
                    .background(Color.pongSystemBackground)
                    .listStyle(PlainListStyle())
                    .flippedUpsideDown()
                    .onChange(of: conversation.messages, perform: { newValue in
                        withAnimation {
                            proxy.scrollTo("bottom", anchor: .top)
                        }

                    })
                    .onAppear() {
                        withAnimation {
                            proxy.scrollTo("bottom", anchor: .top)
                        }
                    }
                }
                
                // MARK: OverLay of MessagingComponent
                VStack {
                    
                    Spacer()
                    
                    MessageComponent
                }

            }
        }
        .background(Color.clear)
        // onAppear load binding conversation into viewmodel
        .onAppear {
            self.messageVM.conversation = conversation
        }
        .onChange(of: self.conversation.id) { newValue in
            DispatchQueue.main.async {
                messageVM.conversation = self.conversation
            }
        }
        .navigationBarTitle("Chat", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        messageVM.showBlockConfirmationView = true
                    } label: {
                        Label("Block user", systemImage: "x.circle")
                    }
                    
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        messageVM.showBlockConfirmationView = true
                    } label: {
                        Label("Report", systemImage: "flag")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .frame(width: 30, height: 30)
                }
                .foregroundColor(Color.pongLabel)
            }
        }
        // MARK: Delete Confirmation
        .alert(isPresented: $messageVM.showBlockConfirmationView) {
            Alert(
                title: Text("Block user"),
                message: Text("Are you sure you want to block this user?"),
                primaryButton: .destructive(Text("Block")) {
                    messageVM.blockUser() { success in
                        dataManager.deleteConversationLocally(conversationId: conversation.id)
                    }
                },
                secondaryButton: .cancel()
            )
        }
        // logic to start/stop polling
        .onReceive(messageVM.timer) { _ in
            if messageVM.timePassed % 5 != 0 {
                messageVM.timePassed += 1
            }
            else {
                messageVM.getConversation()
                messageVM.timePassed += 1
            }
        }
        .onAppear {
            self.conversation.unreadCount = 0
            self.messageVM.readConversation()
            // timer for polling
//            self.messageVM.timer = Timer.publish (every: 1, on: .current, in: .common).autoconnect()
        }
        .onDisappear {
            // timer for polling
//            self.messageVM.timer.upstream.connect().cancel()
        }
        // action to do on update of conversation model
        .onChange(of: messageVM.messageUpdateTrigger) { newValue in
            if self.conversation.messages != messageVM.conversation.messages {
                self.messageVM.scrolledToBottom = false
                self.conversation.messages = messageVM.conversation.messages
            }
        }
    }
    
    // MARK: ChatBubble
    @ViewBuilder
    func chatBubble(userOwned: Bool, message: Message) -> some View {
        HStack {
            if userOwned {
                Spacer()
            }

            HStack {
                Text("\(message.message)")
                    .font(.headline)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 15)
            }
            .foregroundColor(userOwned ? Color.white: Color.black)
            .background(userOwned ? Color.pongAccent : Color.pongGray)
            .cornerRadius(20)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(userOwned ? Color.pongAccent : Color.pongGray, lineWidth: 1))
            
            if !userOwned {
                Spacer()
            }
        }
    }
    
    // MARK: MessageComponent
    var MessageComponent : some View {
        VStack(spacing: 0) {
            
            // MARK: Messaging Component
            VStack {
                // MARK: TextArea and Button Component
                HStack {
                    TextField("Message", text: $text)
                        .font(.headline)
                        .padding(5)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(20)
                        
                    // button component, should not be clickable if text empty
                    if text == "" {
                        ZStack {
                            Image(systemName: "paperplane")
                                .imageScale(.small)
                                .foregroundColor(Color(UIColor.quaternaryLabel))
                                .font(.largeTitle)
                        }
                        .frame(width: 40, height: 40, alignment: .center)
                        .cornerRadius(10)
                    } else {
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            messageVM.sendMessage(message: text)
                            text = ""
                            NotificationsManager.shared.registerForNotifications(forceRegister: false)
                        } label: {
                            ZStack {
                                Image(systemName: "paperplane")
                                    .imageScale(.small)
                                    .foregroundColor(Color(UIColor.label))
                                    .font(.largeTitle)
                            }
                            .frame(width: 40, height: 40, alignment: .center)
                            .cornerRadius(10)
                        }
                    }

                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.pongSystemBackground, lineWidth: 2))
            }
            .background(Color.pongSystemBackground)
        }
        .mask(Rectangle().padding(.top, -20))
    }
    
    // MARK: PostComponent
    var PostComponent: some View {
        HStack {
            HStack {
                VStack {
                    HStack {
                        Text("\(conversation.re)")
                            .font(.subheadline)
                        Spacer()
                    }
                }
                .padding(5)
            }
            .foregroundColor(Color(UIColor.label))
            .background(Color(UIColor.quaternaryLabel))
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(UIColor.quaternaryLabel), lineWidth: 1))
            .padding(5)
        }
        .background(Color.pongSystemBackground)
        .frame(maxWidth: .infinity)
    }
}
