//
//  EmployeesViewController.swift
//  Life
//
//  Created by Shyngys Kassymov on 14.02.2018.
//  Copyright © 2018 Shyngys Kassymov. All rights reserved.
//

import UIKit
import Material
import Moya
import RxSwift
import RxCocoa
import SnapKit

class EmployeesViewController: UIViewController, ViewModelBased {

    typealias ViewModelType = EmployeesViewModel

    var onUnathorizedError: (() -> Void)?

    var viewModel: EmployeesViewModel!
    var didSelectEmployee: ((Employee) -> Void)?

    private let itemsChangeSubject = PublishSubject<[EmployeeViewModel]>()

    private var employeesView: EmployeesView!

    private let disposeBag = DisposeBag()
    private let dataSource =
        RxTableViewSectionedReloadDataSource<SectionModel<EmployeesViewModel, EmployeeViewModel>>(
            configureCell: { (_, tv, indexPath, element) in
                let cellId = App.CellIdentifier.employeeCellId

                let someCell = tv.dequeueReusableCell(withIdentifier: cellId) as? EmployeeCell
                guard let cell = someCell else {
                    return EmployeeCell(style: .default, reuseIdentifier: cellId)
                }

                cell.set(employeeCode: element.employee.code)
                cell.set(title: element.employee.fullname)
                cell.set(subtitle: element.employee.jobPosition)
                cell.minimumHeight = 72

                let itemsCount = tv.numberOfRows(inSection: indexPath.section)
                if indexPath.row == itemsCount - 1 {
                    cell.view?.dividerView?.isHidden = true
                } else {
                    cell.view?.dividerView?.isHidden = false
                }

                return cell
        },
            viewForHeaderInSection: { (_, _, _) in
                let someHeader = HeaderView(frame: .zero)
                let title = NSLocalizedString("employees", comment: "")
                someHeader.titleLabel?.font = App.Font.headline
                someHeader.titleLabel?.text = title
                someHeader.set(insets: .init(
                    top: 0,
                    left: App.Layout.sideOffset,
                    bottom: App.Layout.itemSpacingSmall,
                    right: App.Layout.sideOffset))
                return someHeader
        }
    )

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        bind()

        employeesView.startLoading()
        viewModel.getEmployees { [weak self] error in
            guard let `self` = self
                else { return }

            self.employeesView.stopLoading()

            if let moyaError = error as? MoyaError,
                moyaError.response?.statusCode == 401,
                let onUnathorizedError = self.onUnathorizedError {
                onUnathorizedError()
            } else {
                self.itemsChangeSubject.onNext(self.viewModel.employees)
            }
        }
    }

    // MARK: - Bind

    private func bind() {
        guard let tableView = employeesView.tableView else { return }

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
                if let didSelectEmployee = self.didSelectEmployee {
                    didSelectEmployee(pair.1.employee)
                }
            })
            .disposed(by: disposeBag)

        tableView.rx
            .setDelegate(employeesView)
            .disposed(by: disposeBag)

        employeesView.configureViewForHeader = { (tableView, section) in
            return dataSource.tableView(tableView, viewForHeaderInSection: section)
        }

        itemsChangeSubject.onNext(viewModel.employees)
    }

    // MARK: - UI

    private func setupUI() {
        view.backgroundColor = App.Color.whiteSmoke

        setupTabItem()
        setupEmployeesView()
    }

    private func setupTabItem() {
        tabItem.title = NSLocalizedString("all", comment: "").uppercased()
        tabItem.titleLabel?.font = App.Font.buttonSmall
    }

    private func setupEmployeesView() {
        employeesView = EmployeesView(frame: .zero)
        employeesView.searchView?.didType = { [weak self] text in
            guard let `self` = self else { return }

            if !text.isEmpty {
                self.viewModel.filter(with: text)
                self.itemsChangeSubject.onNext(self.viewModel.filteredEmployees)
            } else {
                self.itemsChangeSubject.onNext(self.viewModel.employees)
            }
        }
        view.addSubview(employeesView)
        employeesView.snp.makeConstraints({ [weak self] (make) in
            guard let `self` = self else { return }
            make.edges.equalTo(self.view)
        })
    }

}
