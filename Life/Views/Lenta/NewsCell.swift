//
//  NewsCell.swift
//  Life
//
//  Created by Shyngys Kassymov on 16.02.2018.
//  Copyright © 2018 Shyngys Kassymov. All rights reserved.
//

import UIKit
import AsyncDisplayKit
import Hue
import Kingfisher

class NewsCell: ASCellNode {

    private weak var viewModel: LentaItemViewModel?

    private(set) var backgroundNode: ASDisplayNode!

    private(set) var authorAvatarNode: ASNetworkImageNode!
    private(set) var authorNameNode: ASTextNode!
    private(set) var createDateNode: ASTextNode!
    private(set) var shareNode: ASButtonNode!

    private(set) var titleNode: ASTextNode!
    private(set) var imageNode: ASNetworkImageNode?

    private(set) var likesIconNode: ASImageNode!
    private(set) var likesNode: ASTextNode!

    private(set) var commentsIconNode: ASImageNode!
    private(set) var commentsNode: ASTextNode!

    private(set) var viewsIconNode: ASImageNode!
    private(set) var viewsNode: ASTextNode!

    private let item: Lenta
    private let image: String

    var didTapShare: ((Lenta) -> Void)?

    fileprivate func setupHeader(_ viewModel: LentaItemViewModel) {
        self.viewModel = viewModel

        if !item.isPublishedAsGroup {
            authorAvatarNode = ASNetworkImageNode()
            authorAvatarNode.cornerRadius = 8
            authorAvatarNode.image = #imageLiteral(resourceName: "ic-user")
            backgroundNode.addSubnode(authorAvatarNode)
        }

        createDateNode = ASTextNode()
        createDateNode.attributedText = attDetailText(viewModel.timeAgo)
        createDateNode.maximumNumberOfLines = 1
        backgroundNode.addSubnode(createDateNode)

        authorNameNode = ASTextNode()
        authorNameNode.attributedText = attUserText(viewModel.item.authorName)
        authorNameNode.maximumNumberOfLines = 1
        authorNameNode.truncationMode = .byTruncatingTail
        backgroundNode.addSubnode(authorNameNode)

        shareNode = ASButtonNode()
        shareNode.contentMode = .scaleAspectFit
        shareNode.setImage(#imageLiteral(resourceName: "more"), for: .normal)
        shareNode.addTarget(self, action: #selector(handleShare), forControlEvents: .touchUpInside)
        backgroundNode.addSubnode(shareNode)
    }

    fileprivate func setupFooter(_ viewModel: LentaItemViewModel) {
        likesIconNode = ASImageNode()
        likesIconNode.contentMode = .scaleAspectFit
        likesIconNode.image = #imageLiteral(resourceName: "like-inactive")
        likesIconNode.imageModificationBlock = ASImageNodeTintColorModificationBlock(
            viewModel.item.isLikedByMe ? App.Color.azure : App.Color.coolGrey
        )
        backgroundNode.addSubnode(likesIconNode)

        likesNode = ASTextNode()
        likesNode.maximumNumberOfLines = 1
        likesNode.attributedText = attDetailText("\(viewModel.item.likesQuantity)")
        backgroundNode.addSubnode(likesNode)

        commentsIconNode = ASImageNode()
        commentsIconNode.contentMode = .scaleAspectFit
        commentsIconNode.image = #imageLiteral(resourceName: "chat-inactive")
        backgroundNode.addSubnode(commentsIconNode)

        commentsNode = ASTextNode()
        commentsNode.maximumNumberOfLines = 1
        commentsNode.attributedText = attDetailText("\(viewModel.item.commentsQuantity)")
        backgroundNode.addSubnode(commentsNode)

        viewsIconNode = ASImageNode()
        viewsIconNode.contentMode = .scaleAspectFit
        viewsIconNode.image = viewModel.item.entityType.code != .questionnaire ? #imageLiteral(resourceName: "view") : #imageLiteral(resourceName: "poll")
        backgroundNode.addSubnode(viewsIconNode)

        viewsNode = ASTextNode()
        viewsNode.maximumNumberOfLines = 1
        if viewModel.item.entityType.code != .questionnaire {
            viewsNode.attributedText = attDetailText("\(viewModel.item.viewsQuantity)")
        } else {
            viewsNode.attributedText = attDetailText("\(viewModel.item.questionsQuantity)")
        }
        backgroundNode.addSubnode(viewsNode)
    }

    init(viewModel: LentaItemViewModel) {
        self.item = viewModel.item

        if viewModel.item.entityType.code != .questionnaire {
            self.image = viewModel.item.image
        } else {
            self.image = viewModel.item.imageStreamId ?? viewModel.item.image
        }

        super.init()

        clipsToBounds = false

        shadowColor = App.Color.black12.cgColor
        shadowOffset = CGSize(width: 0, height: App.Layout.cornerRadiusSmall)
        shadowRadius = App.Layout.cornerRadiusSmall
        shadowOpacity = 1

        backgroundNode = ASDisplayNode()
        backgroundNode.backgroundColor = .white
        backgroundNode.cornerRadius = App.Layout.cornerRadius
        addSubnode(backgroundNode)

        setupHeader(viewModel)

        titleNode = ASTextNode()
        titleNode.attributedText = attTitleText(viewModel.item.title)
        titleNode.maximumNumberOfLines = 0
        backgroundNode.addSubnode(titleNode)

        if !image.isEmpty {
            imageNode = ASNetworkImageNode()
            imageNode?.backgroundColor = App.Color.paleGreyTwo

            var size = CGSize(width: 200, height: 200)
            if viewModel.item.imageSize.width > 0 && viewModel.item.imageSize.height > 0 {
                size = CGSize(width: viewModel.item.imageSize.width, height: viewModel.item.imageSize.height)
            }
            imageNode?.style.preferredSize = size
            backgroundNode.addSubnode(imageNode!)
        }

        setupFooter(viewModel)
    }

    override func didLoad() {
        super.didLoad()

        guard let viewModel = self.viewModel else { return }

        if !item.isPublishedAsGroup {
            ImageDownloader.download(
                image: "",
                employeeCode: viewModel.item.authorCode,
                placeholderImage: #imageLiteral(resourceName: "ic-user"),
                size: CGSize(width: 40, height: 40)) { (image) in
                self.authorAvatarNode.image = image
            }
        }

        var size = CGSize(width: 200, height: 200)
        if viewModel.item.imageSize.width > 0 && viewModel.item.imageSize.height > 0 {
            size = CGSize(width: viewModel.item.imageSize.width, height: viewModel.item.imageSize.height)
        }
        let width = UIScreen.main.bounds.size.width - 2 * App.Layout.sideOffset
        let height = size.height * width / size.width

        ImageDownloader.download(
            image: image,
            size: CGSize(width: width, height: height)) { (image) in
            self.imageNode?.image = image
        }
    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        backgroundNode.layoutSpecBlock = { (node: ASDisplayNode, constrainedSize: ASSizeRange) in
            return self.bodySpec()
        }

        let finalInsetSpec = ASInsetLayoutSpec(
            insets: .init(
                top: App.Layout.itemSpacingSmall / 2,
                left: App.Layout.sideOffset,
                bottom: App.Layout.itemSpacingSmall / 2,
                right: App.Layout.sideOffset
            ),
            child: backgroundNode)

        return finalInsetSpec
    }

    private func bodySpec() -> ASLayoutSpec {
        let headerInsetSpec = layoutHeader()

        let titleInsetSpec = ASInsetLayoutSpec(
            insets: .init(
                top: App.Layout.itemSpacingSmall,
                left: App.Layout.itemSpacingMedium,
                bottom: App.Layout.itemSpacingMedium,
                right: App.Layout.itemSpacingMedium
            ),
            child: titleNode)

        let footerInsetSpec = layoutFooter()

        let verticalLayout = ASStackLayoutSpec.vertical()

        if let imageNode = self.imageNode {
            let size = imageNode.style.preferredSize
            let imageSpec = ASRatioLayoutSpec(ratio: size.height / size.width, child: imageNode)

            verticalLayout.children = [
                headerInsetSpec,
                titleInsetSpec,
                imageSpec,
                footerInsetSpec
            ]
        } else {
            verticalLayout.children = [
                headerInsetSpec,
                titleInsetSpec,
                footerInsetSpec
            ]
        }

        verticalLayout.style.minWidth = ASDimension(
            unit: .points,
            value: UIScreen.main.bounds.size.width - App.Layout.sideOffset * 2
        )

        return verticalLayout
    }

    private func layoutHeader() -> ASLayoutSpec {
        if !item.isPublishedAsGroup {
            authorAvatarNode.style.preferredSize = CGSize(width: 40, height: 40)
        }
        shareNode.style.preferredSize = CGSize(width: 40, height: 40)

        authorNameNode.style.maxWidth = ASDimension(
            unit: .points,
            value: UIScreen.main.bounds.size.width
                - App.Layout.sideOffset * 2
                - App.Layout.itemSpacingMedium * 3
                - App.Layout.itemSpacingSmall / 2
                - 2 * 40
        )

        let userDateStack = ASStackLayoutSpec.vertical()
        userDateStack.children = [
            authorNameNode,
            createDateNode
        ]
        userDateStack.spacing = 5

        let avatarUserDateStack = ASStackLayoutSpec.horizontal()
        if !item.isPublishedAsGroup {
            avatarUserDateStack.children = [
                authorAvatarNode,
                userDateStack
            ]
        } else {
            avatarUserDateStack.children = [userDateStack]
        }
        avatarUserDateStack.spacing = 16

        let headerStack = ASStackLayoutSpec.horizontal()
        headerStack.children = [avatarUserDateStack, shareNode]
        headerStack.justifyContent = .spaceBetween
        headerStack.spacing = 16

        let headerInsetSpec = ASInsetLayoutSpec(
            insets: .init(
                top: App.Layout.itemSpacingMedium,
                left: App.Layout.itemSpacingMedium,
                bottom: App.Layout.itemSpacingMedium,
                right: App.Layout.itemSpacingSmall / 2
            ),
            child: headerStack)

        return headerInsetSpec
    }

    private func layoutFooter() -> ASLayoutSpec {
        let likesStack = ASStackLayoutSpec.horizontal()
        likesStack.children = [likesIconNode, likesNode]
        likesStack.spacing = App.Layout.itemSpacingSmall
        likesStack.alignItems = .center

        let commentsStack = ASStackLayoutSpec.horizontal()
        commentsStack.children = [commentsIconNode, commentsNode]
        commentsStack.spacing = App.Layout.itemSpacingSmall
        commentsStack.alignItems = .center

        let viewsStack = ASStackLayoutSpec.horizontal()
        viewsStack.children = [viewsIconNode, viewsNode]
        viewsStack.spacing = App.Layout.itemSpacingSmall
        viewsStack.alignItems = .center

        let likesCommentsStack = ASStackLayoutSpec.horizontal()
        likesCommentsStack.children = [
            likesStack,
            commentsStack
        ]
        likesCommentsStack.spacing = App.Layout.itemSpacingMedium

        let footerStack = ASStackLayoutSpec.horizontal()
        footerStack.children = [
            likesCommentsStack,
            viewsStack
        ]
        footerStack.justifyContent = .spaceBetween

        let footerInsetSpec = ASInsetLayoutSpec(
            insets: .init(
                top: App.Layout.itemSpacingMedium,
                left: App.Layout.itemSpacingMedium,
                bottom: App.Layout.itemSpacingMedium,
                right: App.Layout.itemSpacingMedium
            ),
            child: footerStack)
        return footerInsetSpec
    }

    // MARK: - Actions

    @objc
    private func handleShare() {
        didTapShare?(item)
    }

    // MARK: - Methods

    private func attUserText(_ string: String) -> NSMutableAttributedString {
        let attText = NSMutableAttributedString(string: string)

        let allRange = NSRange(location: 0, length: attText.length)
        attText.addAttribute(.font, value: App.Font.bodyAlts, range: allRange)
        attText.addAttribute(.foregroundColor, value: UIColor.black, range: allRange)

        return attText
    }

    private func attTitleText(_ string: String) -> NSMutableAttributedString {
        let attText = NSMutableAttributedString(string: string)

        let allRange = NSRange(location: 0, length: attText.length)
        attText.addAttribute(.font, value: App.Font.subhead, range: allRange)
        attText.addAttribute(.foregroundColor, value: UIColor.black, range: allRange)

        return attText
    }

    private func attDetailText(_ string: String) -> NSMutableAttributedString {
        let attText = NSMutableAttributedString(string: string)

        let allRange = NSRange(location: 0, length: attText.length)
        attText.addAttribute(.font, value: App.Font.caption, range: allRange)
        attText.addAttribute(.foregroundColor, value: App.Color.steel, range: allRange)

        return attText
    }

}
