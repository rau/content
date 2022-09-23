// MIT License
//
// Copyright (c) 2017-2020 MessageKit
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import InputBarAccessoryView
import MessageKit
import SwiftUI

// MARK: - MessageSwiftUIVC

final class MessageSwiftUIVC: MessagesViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Because SwiftUI wont automatically make our controller the first responder, we need to do it on viewDidAppear
        becomeFirstResponder()
        messagesCollectionView.scrollToLastItem(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout {
            layout.setMessageIncomingAvatarSize(.zero)
            layout.setMessageOutgoingAvatarSize(.zero)
            layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            layout.minimumInteritemSpacing = 0
            layout.minimumLineSpacing = 0
            messagesCollectionView.messagesCollectionViewFlowLayout.setMessageIncomingMessageBottomLabelAlignment(LabelAlignment(textAlignment: .left, textInsets: .zero))
            messagesCollectionView.messagesCollectionViewFlowLayout.setMessageOutgoingMessageBottomLabelAlignment(LabelAlignment(textAlignment: .right, textInsets: .zero))
            messagesCollectionView.messagesCollectionViewFlowLayout.setMessageIncomingMessageTopLabelAlignment(LabelAlignment(textAlignment: .left, textInsets: .zero))
            messagesCollectionView.messagesCollectionViewFlowLayout.setMessageOutgoingMessageTopLabelAlignment(LabelAlignment(textAlignment: .right, textInsets: .zero))
        }
    }
}

// MARK: - MessagesView

struct MessagesView: UIViewControllerRepresentable {
  // MARK: Internal

    final class Coordinator {
        // MARK: Lifecycle

        init(messages: Binding<[MessageType]>, messageVM: MessageViewModel) {
            self.messages = messages
            self.messageVM = messageVM
        }

        // MARK: Internal

        let formatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter
        }()

        var messages: Binding<[MessageType]>
        var messageVM : MessageViewModel
    }


    @State var initialized = false
    @Binding var messages: [MessageType]
    @ObservedObject var messageVM : MessageViewModel

    func makeUIViewController(context: Context) -> MessagesViewController {
        let messagesVC = MessageSwiftUIVC()

        messagesVC.messagesCollectionView.messagesDisplayDelegate = context.coordinator
        messagesVC.messagesCollectionView.messagesLayoutDelegate = context.coordinator
        messagesVC.messagesCollectionView.messagesDataSource = context.coordinator
        messagesVC.messageInputBar.delegate = context.coordinator
        messagesVC.scrollsToLastItemOnKeyboardBeginsEditing = true // default false
        messagesVC.maintainPositionOnInputBarHeightChanged = true // default false
        messagesVC.showMessageTimestampOnSwipeLeft = true // default false

        return messagesVC
    }

    func updateUIViewController(_ uiViewController: MessagesViewController, context _: Context) {
        uiViewController.messagesCollectionView.reloadData()
        if !messageVM.scrolledToBottom {
            scrollToBottom(uiViewController)
            DispatchQueue.main.async {
                messageVM.scrolledToBottom = true
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(messages: $messages, messageVM: messageVM)
    }

  // MARK: Private

    private func scrollToBottom(_ uiViewController: MessagesViewController) {
        DispatchQueue.main.async {
            // The initialized state variable allows us to start at the bottom with the initial messages without seeing the initial scroll flash by
            uiViewController.messagesCollectionView.scrollToLastItem(animated: self.initialized)
            self.initialized = true
        }
    }
}

// MARK: - MessagesView.Coordinator + MessagesDataSource

extension MessagesView.Coordinator: MessagesDataSource {
    var currentSender: SenderType {
        MockUser(senderId: "1", displayName: "Me")
    }

    func messageForItem(at indexPath: IndexPath, in _: MessagesCollectionView) -> MessageType {
        messages.wrappedValue[indexPath.section]
    }

    func numberOfSections(in _: MessagesCollectionView) -> Int {
        messages.wrappedValue.count
    }

//    func messageTopLabelAttributedText(for message: MessageType, at _: IndexPath) -> NSAttributedString? {
//        let name = message.sender.displayName
//        return NSAttributedString(
//        string: name,
//        attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1)])
//    }

//    func messageBottomLabelAttributedText(for message: MessageType, at _: IndexPath) -> NSAttributedString? {
//        let dateString = formatter.string(from: message.sentDate)
//        return NSAttributedString(
//        string: dateString,
//        attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption2)])
//    }

    func messageTimestampLabelAttributedText(for message: MessageType, at _: IndexPath) -> NSAttributedString? {
        let sentDate = message.sentDate
        let sentDateString = MessageKitDateFormatter.shared.string(from: sentDate)
        let timeLabelFont: UIFont = .boldSystemFont(ofSize: 10)
        let timeLabelColor: UIColor = .systemGray
        return NSAttributedString(
        string: sentDateString,
        attributes: [NSAttributedString.Key.font: timeLabelFont, NSAttributedString.Key.foregroundColor: timeLabelColor])
    }
}

// MARK: - MessagesView.Coordinator + InputBarAccessoryViewDelegate

extension MessagesView.Coordinator: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        messageVM.scrolledToBottom = false
        messageVM.sendMessage(message: text)
        inputBar.inputTextView.text = ""
    }
}

// MARK: - MessagesView.Coordinator + MessagesLayoutDelegate, MessagesDisplayDelegate
// just added custom avatar where image is nil and initials are an empty string
extension MessagesView.Coordinator: MessagesLayoutDelegate, MessagesDisplayDelegate {
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at _: IndexPath, in _: MessagesCollectionView) {
        avatarView.isHidden = true
    }

    func messageTopLabelHeight(for _: MessageType, at _: IndexPath, in _: MessagesCollectionView) -> CGFloat {
        20
    }

    func messageBottomLabelHeight(for _: MessageType, at _: IndexPath, in _: MessagesCollectionView) -> CGFloat {
        16
    }
    
    func backgroundColor(for message: MessageType, at  indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        switch message.kind {
        case .emoji:
            return .clear
        default:
            guard let dataSource = messagesCollectionView.messagesDataSource else {
                return .white
            }
            return dataSource.isFromCurrentSender(message: message) ? .systemBlue : .systemGray
        }
    }
}
