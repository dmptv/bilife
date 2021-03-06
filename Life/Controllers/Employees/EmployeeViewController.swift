//
//  EmployeeViewController.swift
//  Life
//
//  Created by Shyngys Kassymov on 21.02.2018.
//  Copyright © 2018 Shyngys Kassymov. All rights reserved.
//

import UIKit
import Kingfisher
import Lightbox
import Material
import Moya
import RxSwift
import RxCocoa
import SnapKit

class EmployeeViewController: UIViewController, ViewModelBased, Stepper {

    private var employeeView: EmployeeView!

    var onUnathorizedError: (() -> Void)?

    typealias ViewModelType = EmployeeViewModel
    var viewModel: EmployeeViewModel!

    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        bind()

        viewModel.getEmployeeInfo { [weak self] error in
            guard let `self` = self
                else { return }

            if let moyaError = error as? MoyaError,
                moyaError.response?.statusCode == 401,
                let onUnathorizedError = self.onUnathorizedError {
                onUnathorizedError()
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if !isMovingFromParentViewController {
            self.navigationController?.setNavigationBarHidden(false, animated: true)
        }
    }

    // MARK: - Bind

    private func bind() {
        viewModel.employeeVariable.asDriver().drive(onNext: { [weak self] employee in
            guard let `self` = self else { return }

            self.employeeView.fullname = employee.fullname
            self.employeeView.image = employee.code
            self.employeeView.position = employee.jobPosition
            self.employeeView.birthdate = employee.birthDate.prettyDateString(format: "dd MMMM")
            self.employeeView.administrativeChief = employee.administrativeChiefName ?? ""
            self.employeeView.functionalChief = employee.functionalChiefName ?? ""
            self.employeeView.phone = employee.workPhoneNumber
            self.employeeView.email = employee.email
        }).disposed(by: disposeBag)
    }

    // MARK: - Methods

    private func openAvatar() {
        guard let avatarURL = ImageDownloader.url(for: "", employeeCode: viewModel.employee.code),
            viewModel.employee.hasAvatar else {
            return
        }
        let avatarImage = LightboxImage(imageURL: avatarURL)
        let controller = LightboxController(images: [avatarImage])
        controller.dynamicBackground = true
        controller.footerView.isHidden = true

        present(controller, animated: true, completion: nil)
    }

    private func openShareSheet() {
        let actionSheet = UIAlertController(
            title: NSLocalizedString("choose_option", comment: ""),
            message: nil,
            preferredStyle: .actionSheet
        )

        actionSheet.addAction(
            UIAlertAction(
                title: NSLocalizedString("share_contact", comment: ""),
                style: .default,
                handler: { [weak self] _ in
                    self?.shareContact()
                }
            )
        )

        if !self.viewModel.contactsService.isContactExists(for: self.viewModel.employee) {
            actionSheet.addAction(
                UIAlertAction(
                    title: NSLocalizedString("add_to_contacts", comment: ""),
                    style: .default,
                    handler: { [weak self] _ in
                        guard let `self` = self,
                            let navVC = self.navigationController else { return }
                        self.viewModel.contactsService.contactSaveCompletion = { _ in }
                        self.viewModel.contactsService.save(
                            employee: self.viewModel.employee,
                            presentIn: navVC
                        )
                    }
                )
            )
        }

        actionSheet.addAction(
            UIAlertAction(
                title: NSLocalizedString("cancel", comment: ""),
                style: .cancel,
                handler: nil
            )
        )

        present(actionSheet, animated: true, completion: nil)
    }

    private func shareContact() {
        let shareText =
        """
        ФИО: "\(viewModel.employee.fullname)"
        Должность: \(viewModel.employee.jobPosition)
        День рождения: \(viewModel.employee.birthDate.prettyDateString(format: "dd MMMM"))
        Рабочий телефон: \(viewModel.employee.workPhoneNumber)
        Эл. почта: \(viewModel.employee.email)
        """

        let shareItems = [shareText]
        let activityViewController = UIActivityViewController(
            activityItems: shareItems,
            applicationActivities: nil
        )
        activityViewController.popoverPresentationController?.sourceView = self.view

        present(activityViewController, animated: true, completion: nil)
    }

    // MARK: - UI

    private func setupUI() {
        view.backgroundColor = .white

        setupEmployeeView()
    }

    private func setupEmployeeView() {
        employeeView = EmployeeView(frame: .zero)
        employeeView.didTapCloseButton = { [weak self] in
            self?.step.accept(AppStep.employeeDone)
        }
        employeeView.didTapAvatar = { [weak self] in
            self?.openAvatar()
        }
        employeeView.didTapCallButton = {
            let telUrl = "telprompt://\(self.viewModel.employee.workPhoneNumber)"
            if let url = URL(string: telUrl) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        employeeView.didTapEmailButton = {
            if let url = URL(string: "mailto:\(self.viewModel.employee.email)") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        employeeView.didTapAddContactButton = { [weak self] in
            self?.openShareSheet()
        }
        view.addSubview(employeeView)
        employeeView.snp.makeConstraints({ [weak self] (make) in
            guard let `self` = self else { return }
            make.top.equalTo(self.topLayoutGuide.snp.bottom)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.bottom.equalTo(self.view)
        })

        DispatchQueue.global().async { [weak self] in
            guard let `self` = self else { return }
            _ = self.viewModel.contactsService.isContactExists(for: self.viewModel.employee)
            DispatchQueue.main.async { [weak self] in
                guard let `self` = self else { return }
                self.employeeView.shareButton.isHidden = false
            }
        }
    }

}
