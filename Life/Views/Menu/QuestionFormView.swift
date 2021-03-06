//
//  QuestionFormView.swift
//  Life
//
//  Created by Shyngys Kassymov on 23.02.2018.
//  Copyright © 2018 Shyngys Kassymov. All rights reserved.
//

import UIKit
import IQKeyboardManagerSwift
import Material
import SnapKit
import TTGTagCollectionView

class QuestionFormView: UIView {

    private(set) lazy var headerView = NotificationHeaderView(
        image: nil,
        title: NSLocalizedString("add_question", comment: ""),
        subtitle: nil
    )
    private(set) lazy var scrollView = UIScrollView()
    private(set) lazy var contentView = UIView()
    private(set) lazy var textField = TextView(frame: .zero)
    private(set) lazy var tagsField = TextField(frame: .zero)
    private(set) lazy var tagsCollectionView = TTGTextTagCollectionView(frame: .zero)
    private(set) lazy var isAnonymousButton = FlatButton(
        title: NSLocalizedString("is_anonymous", comment: ""),
        titleColor: App.Color.steel
    )
    private(set) lazy var addButton = Button(
        title: NSLocalizedString("ask_question", comment: "").uppercased()
    )

    var didDeleteTag: ((String) -> Void)?
    var didTapAddTag: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Actions

    @objc
    private func handleAddTagButton() {
        if let didTapAddTag = didTapAddTag {
            didTapAddTag()
        }
    }

    // MARK: - UI

    private func setupUI() {
        setupHeaderView()
        setupScrollView()
    }

    private func setupHeaderView() {
        headerView.backgroundColor = .white
        addSubview(headerView)
        headerView.snp.makeConstraints { (make) in
            make.top.equalTo(self)
            make.left.equalTo(self)
            make.right.equalTo(self)
        }
    }

    private func setupScrollView() {
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        addSubview(scrollView)
        scrollView.snp.makeConstraints { (make) in
            make.top.equalTo(self.headerView.snp.bottom)
            make.left.equalTo(self)
            make.bottom.equalTo(self)
            make.right.equalTo(self)
        }

        setupContentView()
    }

    private func setupContentView() {
        scrollView.addSubview(contentView)
        sendSubview(toBack: scrollView)
        contentView.snp.makeConstraints { (make) in
            make.edges.equalTo(self.scrollView)
            make.width.equalTo(self.scrollView)
        }

        setupTextView()
        setupTagsField()
        setupTagsCollectionView()
        setupIsAnonymousButton()
        setupAddButton()
    }

    private func setupTextView() {
        textField.backgroundColor = App.Color.paleGrey
        textField.layer.borderColor = App.Color.coolGrey.cgColor
        textField.layer.borderWidth = 0.5
        textField.layer.cornerRadius = App.Layout.cornerRadius
        textField.layer.masksToBounds = true
        textField.placeholder = NSLocalizedString("question_text", comment: "")
        textField.textContainerInsets = EdgeInsets(
            top: 14,
            left: App.Layout.itemSpacingMedium,
            bottom: 14,
            right: App.Layout.itemSpacingMedium
        )
        contentView.addSubview(textField)
        textField.snp.makeConstraints { (make) in
            make.top
                .equalTo(self.contentView)
                .inset(App.Layout.itemSpacingMedium)
            make.left.equalTo(self.contentView).inset(App.Layout.sideOffset)
            make.right.equalTo(self.contentView).inset(App.Layout.sideOffset)
            make.height.equalTo(144)
        }
    }

    private func setupTagsField() {
        tagsField.placeholder = NSLocalizedString("tags", comment: "")
        tagsField.addRightButtonOnKeyboardWithText(
            NSLocalizedString("create_tag", comment: ""),
            target: self,
            action: #selector(handleAddTagButton)
        )
        tagsField.keyboardToolbar.tintColor = .black
        contentView.addSubview(tagsField)
        tagsField.snp.makeConstraints { (make) in
            make.top
                .equalTo(self.textField.snp.bottom)
                .offset(App.Layout.sideOffset)
            make.left.equalTo(self.contentView).inset(App.Layout.sideOffset)
            make.right.equalTo(self.contentView).inset(App.Layout.sideOffset)
        }
    }

    private func setupTagsCollectionView() {
        tagsCollectionView.delegate = self
        tagsCollectionView.showsVerticalScrollIndicator = false
        tagsCollectionView.horizontalSpacing = 6.0
        tagsCollectionView.verticalSpacing = 8.0
        contentView.addSubview(tagsCollectionView)

        let config = tagsCollectionView.defaultConfig
        config?.tagTextFont = App.Font.body
        config?.tagTextColor = .white
        config?.tagSelectedTextColor = .white
        config?.tagBackgroundColor = App.Color.azure
        config?.tagSelectedBackgroundColor = App.Color.azure
        config?.tagBorderColor = .clear
        config?.tagSelectedBorderColor = .clear
        config?.tagBorderWidth = 0
        config?.tagSelectedBorderWidth = 0
        config?.tagShadowColor = .clear
        config?.tagShadowOffset = .zero
        config?.tagShadowOpacity = 0
        config?.tagShadowRadius = 0
        config?.tagCornerRadius = App.Layout.cornerRadiusSmall / 2

        tagsCollectionView.snp.makeConstraints { (make) in
            make.top
                .equalTo(self.tagsField.snp.bottom)
                .offset(App.Layout.itemSpacingSmall)
            make.left.equalTo(self.contentView).inset(App.Layout.sideOffset)
            make.right.equalTo(self.contentView).inset(App.Layout.sideOffset)
        }
    }

    private func setupIsAnonymousButton() {
        isAnonymousButton.setImage(#imageLiteral(resourceName: "checkbox_empty"), for: .normal)
        isAnonymousButton.setImage(#imageLiteral(resourceName: "checkbox_tick"), for: .selected)
        isAnonymousButton.setImage(#imageLiteral(resourceName: "checkbox_tick"), for: .highlighted)
        isAnonymousButton.tintColor = App.Color.coolGrey
        isAnonymousButton.titleEdgeInsets = .init(top: 0, left: 4, bottom: 0, right: 0)
        isAnonymousButton.titleLabel?.font = App.Font.caption
        isAnonymousButton.titleLabel?.textColor = App.Color.steel
        isAnonymousButton.contentHorizontalAlignment = .left
        contentView.addSubview(isAnonymousButton)
        isAnonymousButton.snp.makeConstraints { (make) in
            make.top.equalTo(self.tagsCollectionView.snp.bottom).offset(App.Layout.itemSpacingMedium)
            make.left.equalTo(self.contentView).inset(App.Layout.sideOffset)
            make.right.equalTo(self.contentView).inset(App.Layout.sideOffset)
        }
    }

    private func setupAddButton() {
        contentView.addSubview(addButton)
        addButton.snp.makeConstraints { (make) in
            make.top.equalTo(self.isAnonymousButton.snp.bottom).offset(App.Layout.itemSpacingMedium)
            make.left.equalTo(self.contentView).inset(App.Layout.sideOffset)
            make.bottom.equalTo(self.contentView).inset(App.Layout.sideOffset)
            make.right.equalTo(self.contentView).inset(App.Layout.sideOffset)
        }
    }

}

extension QuestionFormView: TTGTextTagCollectionViewDelegate {
    //swiftlint:disable line_length
    func textTagCollectionView(_ textTagCollectionView: TTGTextTagCollectionView!, didTapTag tagText: String!, at index: UInt, selected: Bool) {
        textTagCollectionView.removeTag(at: index)

        if let didDeleteTag = didDeleteTag {
            didDeleteTag(tagText)
        }
    }
    //swiftlint:enable line_length
}
