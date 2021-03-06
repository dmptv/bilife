//
//  QuestionSectionController.swift
//  Life
//
//  Created by Shyngys Kassymov on 22.02.2018.
//  Copyright © 2018 Shyngys Kassymov. All rights reserved.
//

import UIKit
import AsyncDisplayKit
import IGListKit
import Moya
import RxSwift
import RxCocoa

class QuestionSectionController: ASCollectionSectionController {
    private(set) weak var viewModel: QuestionsViewModel?

    let disposeBag = DisposeBag()

    var onUnathorizedError: (() -> Void)?
    var didSelectVideo: ((String) -> Void)?

    init(viewModel: QuestionsViewModel) {
        self.viewModel = viewModel

        super.init()

        supplementaryViewSource = self

        viewModel.questionsSubject.asDriver(onErrorJustReturn: []).drive(onNext: { [weak self] _ in
            self?.updateContents()
        }).disposed(by: disposeBag)
    }

    override func didUpdate(to object: Any) {
        viewModel = object as? QuestionsViewModel
        updateContents()
    }

    override func cellForItem(at index: Int) -> UICollectionViewCell {
        return ASIGListSectionControllerMethods.cellForItem(at: index, sectionController: self)
    }

    override func sizeForItem(at index: Int) -> CGSize {
        return ASIGListSectionControllerMethods.sizeForItem(at: index)
    }

    override func didSelectItem(at index: Int) {
        if let answer = items[index] as? AnswerViewModel,
            !answer.answer.videoStreamId.isEmpty,
            let didSelectVideo = didSelectVideo {
            didSelectVideo(answer.answer.videoStreamId)
        }
    }

    // MARK: - Methods

    public func add(question: Question) {
        viewModel?.add(question: question)
    }

    public func add(answer: Answer, to questions: [String]) {
        viewModel?.add(answer: answer, to: questions)
    }

    private func updateContents(animated: Bool = false, completion: (() -> Void)? = nil) {
        var items = [ListDiffable]()

        if let viewModel = viewModel {
            for question in viewModel.questions {
                items.append(question)

                for answer in question.question.answers {
                    let answerViewModel = AnswerViewModel(answer: answer)
                    items.append(answerViewModel)
                }
            }
        }

        set(items: items, animated: animated, completion: completion)
    }

}

extension QuestionSectionController: ASSectionController {
    func nodeBlockForItem(at index: Int) -> ASCellNodeBlock {
        guard index < items.count else {
            return {
                return ASCellNode()
            }
        }

        if let question = items[index] as? QuestionItemViewModel {
            return {
                return QuestionCell(viewModel: question)
            }
        } else if let answer = items[index] as? AnswerViewModel {
            return {
                return AnswerCell(viewModel: answer)
            }
        }

        return {
            return ASCellNode()
        }
    }

    func beginBatchFetch(with context: ASBatchContext) {
        context.completeBatchFetching(true)
    }

    func shouldBatchFetch() -> Bool {
        return false
    }
}

extension QuestionSectionController: RefreshingSectionControllerType {
    func refreshContent(with completion: (() -> Void)?) {
        viewModel?.getQuestions { [weak self] error in
            if let moyaError = error as? MoyaError,
                moyaError.response?.statusCode == 401,
                let onUnathorizedError = self?.onUnathorizedError {
                onUnathorizedError()
            }
        }
    }
}

extension QuestionSectionController: ASSupplementaryNodeSource {
    func nodeBlockForSupplementaryElement(ofKind elementKind: String, at index: Int) -> ASCellNodeBlock {
        return {
            return TopQuestionsHeader(
                title: NSLocalizedString("questions_and_answers", comment: "")
            )
        }
    }

    func sizeRangeForSupplementaryElement(ofKind elementKind: String, at index: Int) -> ASSizeRange {
        if elementKind == UICollectionElementKindSectionHeader {
            return ASSizeRangeUnconstrained
        } else {
            return ASSizeRangeZero
        }
    }
}

extension QuestionSectionController: ListSupplementaryViewSource {
    func supportedElementKinds() -> [String] {
        return [UICollectionElementKindSectionHeader]
    }

    func viewForSupplementaryElement(ofKind elementKind: String, at index: Int) -> UICollectionReusableView {
        return ASIGListSupplementaryViewSourceMethods
            .viewForSupplementaryElement(
                ofKind: elementKind,
                at: index,
                sectionController: self)
    }

    func sizeForSupplementaryView(ofKind elementKind: String, at index: Int) -> CGSize {
        return ASIGListSupplementaryViewSourceMethods.sizeForSupplementaryView(ofKind: elementKind, at: index)
    }

}
