//
//  TasksAndRequestsViewController.swift
//  Life
//
//  Created by Shyngys Kassymov on 21.02.2018.
//  Copyright © 2018 Shyngys Kassymov. All rights reserved.
//

import UIKit
import IGListKit
import Material
import RxSwift
import RxCocoa
import SnapKit

class TasksAndRequestsViewController: UIViewController, ViewModelBased, Stepper {

    typealias ViewModelType = TasksAndRequestsViewModel

    var viewModel: TasksAndRequestsViewModel!

    private var tasksAndRequestsView: TasksAndRequetsView!

    private let itemsChangeSubject = PublishSubject<[ListDiffable]>()

    private let disposeBag = DisposeBag()
    private let dataSource =
        RxTableViewSectionedReloadDataSource<SectionModel<TasksAndRequestsViewModel, ListDiffable>>(
            configureCell: { (_, tv, _, element) in
                let cellId = App.CellIdentifier.taskOrReqeustCellId

                let someCell = tv.dequeueReusableCell(withIdentifier: cellId) as? TasksAndRequetsCell
                guard let cell = someCell else {
                    return TasksAndRequetsCell(style: .default, reuseIdentifier: cellId)
                }

                if let viewModel = element as? TaskViewModel {
                    cell.set(title: viewModel.task.topic)
                    cell.set(subtitle: viewModel.task.endDate?.prettyDateString(format: "dd.MM.yyyy HH:mm"))
                } else if let viewModel = element as? RequestViewModel {
                    cell.set(title: viewModel.request.topic)
                    cell.set(subtitle: viewModel.request.endDate.prettyDateString(format: "dd.MM.yyyy HH:mm"))
                }

                return cell
        }
    )

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        bind()
    }

    // MARK: - Bind

    private func bind() {
        guard let tableView = tasksAndRequestsView.tableView else { return }

        let dataSource = self.dataSource

        let observable = itemsChangeSubject.asObservable()
        let items = observable.concatMap { (items) in
            return Observable.just([SectionModel(model: self.viewModel!, items: items)])
        }

        items
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)

        tableView.rx
            .itemSelected
            .map { indexPath in
                return (indexPath, dataSource[indexPath])
            }
            .subscribe(onNext: { pair in
                print("Tapped `\(pair.1)` @ \(pair.0)")
            })
            .disposed(by: disposeBag)

        tableView.rx
            .setDelegate(tasksAndRequestsView)
            .disposed(by: disposeBag)

        itemsChangeSubject.onNext(viewModel.currentItems)
    }

    // MARK: - UI

    private func setupUI() {
        view.backgroundColor = .white

        setupTaskAndRequestsView()
    }

    private func setupTaskAndRequestsView() {
        tasksAndRequestsView = TasksAndRequetsView(frame: .zero)
        tasksAndRequestsView.didTapCloseButton = { [weak self] in
            self?.step.accept(AppStep.tasksAndRequestsDone)
        }
        tasksAndRequestsView.didTapTabItem = { [weak self] index in
            self?.viewModel.selectedItemsType = index == 0 ? .inbox : .outbox
            self?.itemsChangeSubject.onNext(self?.viewModel.currentItems ?? [])
        }
        view.addSubview(tasksAndRequestsView)
        tasksAndRequestsView.snp.makeConstraints({ [weak self] (make) in
            guard let `self` = self else { return }
            make.top.equalTo(self.topLayoutGuide.snp.bottom)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.bottom.equalTo(self.view)
        })
    }

}