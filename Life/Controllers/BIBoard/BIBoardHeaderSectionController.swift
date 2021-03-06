//
//  BIBoardHeaderSectionController.swift
//  Life
//
//  Created by Shyngys Kassymov on 19.02.2018.
//  Copyright © 2018 Shyngys Kassymov. All rights reserved.
//

import UIKit
import AsyncDisplayKit
import IGListKit
import Moya
import RxSwift
import RxCocoa

class BIBoardHeaderSectionController: ASCollectionSectionController {
    private(set) weak var viewModel: NewsViewModel?
    let disposeBag = DisposeBag()

    var onUnathorizedError: (() -> Void)?
    var didSelectNews: ((String) -> Void)?

    var sectionTimestamp = DateCell()

    private var loading = BehaviorRelay(value: false)

    init(viewModel: NewsViewModel) {
        self.viewModel = viewModel

        super.init()

        viewModel.loadingTop3.bind(to: loading).disposed(by: disposeBag)
        viewModel.top3NewsObservable.subscribe(onNext: { [weak self] _ in
            guard let `self` = self else { return }
            self.sectionTimestamp.update()
            self.collectionContext?.performBatch(animated: true, updates: { (context) in
                context.reload(self)
            }, completion: nil)
        }).disposed(by: disposeBag)
    }

    override func didUpdate(to object: Any) {
        viewModel = object as? NewsViewModel
        self.sectionTimestamp.update()
        set(items: [sectionTimestamp], animated: false, completion: nil)
    }

    override func cellForItem(at index: Int) -> UICollectionViewCell {
        return ASIGListSectionControllerMethods.cellForItem(at: index, sectionController: self)
    }

    override func sizeForItem(at index: Int) -> CGSize {
        return ASIGListSectionControllerMethods.sizeForItem(at: index)
    }

    override func didSelectItem(at index: Int) {
    }
}

extension BIBoardHeaderSectionController: ASSectionController {
    func nodeBlockForItem(at index: Int) -> ASCellNodeBlock {
        guard let viewModel = viewModel else {
            return {
                return ASCellNode()
            }
        }

        return {
            let slides = viewModel.top3News.map { (viewModel) -> SliderViewModel in
                var image = viewModel.news.imageStreamId ?? ""
                if image.isEmpty {
                    image = viewModel.news.imageUrl
                }
                return SliderViewModel(
                    title: viewModel.news.title,
                    label: NSLocalizedString("news_single", comment: "").uppercased(),
                    image: image
                )
            }

            let height = max(200 * UIScreen.main.bounds.size.width / 375.0, 200)

            let cell = BoardSliderCell(
                slides: slides,
                height: height,
                hideSpinner: !self.loading.value
            )
            cell.didSelectSlide = { index in
                if let didSelectNews = self.didSelectNews {
                    didSelectNews(viewModel.top3News[index].news.id)
                }
            }
            cell.backgroundColor = App.Color.whiteSmoke
            
            return cell
        }
    }

    func beginBatchFetch(with context: ASBatchContext) {
        context.completeBatchFetching(true)
    }

    func shouldBatchFetch() -> Bool {
        return false
    }
}

extension BIBoardHeaderSectionController: RefreshingSectionControllerType {
    func refreshContent(with completion: (() -> Void)?) {
        viewModel?.getTop3News { [weak self] error in
            if let moyaError = error as? MoyaError,
                moyaError.response?.statusCode == 401,
                let onUnathorizedError = self?.onUnathorizedError {
                onUnathorizedError()
            }
            if let completion = completion {
                completion()
            }
        }
    }
}
