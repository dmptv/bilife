//
//  TaskFormViewController.swift
//  Life
//
//  Created by Shyngys Kassymov on 05.03.2018.
//  Copyright © 2018 Shyngys Kassymov. All rights reserved.
//

import UIKit
import FileProvider
import IQMediaPickerController
import Photos
import RxSwift
import RxCocoa
import SnapKit
import UITextField_AutoSuggestion

class TaskFormViewController: UIViewController, Stepper {

    private(set) lazy var taskFormView = TaskFormView(frame: .zero)

    private(set) var viewModel: TaskFormViewModel

    let disposeBag = DisposeBag()

    var didCreateTask: (() -> Void)?

    init(viewModel: TaskFormViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
    }

    // MARK: - Methods

    private func pickFromDocuments() {
        let fileExplorer = FileExplorerViewController()
        fileExplorer.canChooseFiles = true
        fileExplorer.allowsMultipleSelection = true
        fileExplorer.delegate = self
        fileExplorer.fileFilters = [
            Filter.extension("png"),
            Filter.extension("jpg"),
            Filter.extension("jpeg"),
            Filter.extension("txt"),
            Filter.extension("pdf"),
            Filter.extension("xlsx"),
            Filter.extension("xls"),
            Filter.extension("xml"),
            Filter.extension("html"),
            Filter.extension("htm"),
            Filter.extension("doc"),
            Filter.extension("docx"),
            Filter.extension("rtf"),
            Filter.extension("gif"),
            Filter.extension("bmp"),
            Filter.extension("zip"),
            Filter.extension("tgz"),
            Filter.extension("tar.gz")
        ]
        self.present(fileExplorer, animated: true, completion: nil)
    }

    private func pickFromGallery() {
        let vc = IQMediaPickerController()
        vc.allowsPickingMultipleItems = true
        vc.delegate = self
        vc.mediaTypes = [
            NSNumber(value: IQMediaPickerControllerMediaType.photo.rawValue),
            NSNumber(value: IQMediaPickerControllerMediaType.video.rawValue)
        ]
        vc.sourceType = .library
        present(vc, animated: true, completion: nil)
    }

    private func pickAttachments() {
        let alert = UIAlertController(
            title: NSLocalizedString("choose_option", comment: ""),
            message: nil,
            preferredStyle: .actionSheet
        )
        alert.popoverPresentationController?.sourceView = view

        let captureAction = UIAlertAction(
            title: NSLocalizedString("pick_from_documents", comment: ""),
            style: .default) { [weak self] _ in
                self?.pickFromDocuments()
        }
        alert.addAction(captureAction)
        let libraryAction = UIAlertAction(
            title: NSLocalizedString("pick_from_gallery", comment: ""),
            style: .default) { [weak self] _ in
                self?.pickFromGallery()
        }
        alert.addAction(libraryAction)
        let cancelAction = UIAlertAction(
            title: NSLocalizedString("cancel", comment: ""),
            style: .cancel,
            handler: nil)
        alert.addAction(cancelAction)

        present(alert, animated: true, completion: nil)
    }

    private func add(videlURL: URL) {
        let fetchResult = PHAsset.fetchAssets(withALAssetURLs: [videlURL], options: nil)
        if let phAsset = fetchResult.firstObject {
            PHImageManager.default().requestAVAsset(
                forVideo: phAsset,
                options: PHVideoRequestOptions(),
                resultHandler: { (asset, _, _) -> Void in
                    if let asset = asset as? AVURLAsset {
                        let videoData = try? Data(contentsOf: asset.url)

                        let tempDir = NSTemporaryDirectory()
                        let tempDirPath = URL(fileURLWithPath: tempDir)
                        let videoName = UUID().uuidString
                        let videoPath = tempDirPath.appendingPathComponent("\(videoName).MOV")
                        if FileManager.default.fileExists(atPath: videoPath.path) {
                            try? FileManager.default.removeItem(at: videoPath)
                        }

                        let writeResult = try? videoData?.write(to: videoPath)
                        if writeResult != nil {
                            let attachment = Attachment(url: videoPath, type: .file)
                            self.taskFormView.add(attachments: [attachment])
                        }
                    }
            })
        }
    }

    // MARK: - UI

    private func setupUI() {
        view.backgroundColor = .white

        setupQuestionFormView()
    }

    private func setupQuestionFormView() {
        view.addSubview(taskFormView)
        taskFormView.snp.makeConstraints { (make) in
            make.top.equalTo(self.topLayoutGuide.snp.bottom)
            make.left.equalTo(self.view)
            make.bottom.equalTo(self.view)
            make.right.equalTo(self.view)
        }

        bindCloseButton()
        bindTopicField()
        bindIsAllDayButton()
        bindReminderField()
        bindStartDateField()
        bindEndDateField()
        bindExecutorAndParticipantsFields()
        bindTypeField()
        bindTextField()
        bindAttachmentButton()
        bindSendButton()
        bindOnRequestFinish()
    }

    private func bindOnRequestFinish() {
        viewModel.taskCreatedSubject.subscribe(onNext: { [weak self] statusCode in
            guard let `self` = self else { return }
            if statusCode == 200 {
                self.step.accept(AppStep.createTaskDone)
                if let didCreateTask = self.didCreateTask {
                    didCreateTask()
                }
            }
        }).disposed(by: disposeBag)
        viewModel.taskCreatedWithErrorSubject.subscribe(onNext: { [weak self] error in
            guard let `self` = self else { return }
            let errorMessages = error.parseMessages()
            if let key = errorMessages.keys.first,
                let message = errorMessages[key] {
                self.showToast(message)
            }
        }).disposed(by: disposeBag)
    }

    private func bindCloseButton() {
        taskFormView.headerView.closeButton?.rx.tap
            .asDriver()
            .throttle(0.5)
            .drive(onNext: { [weak self] in
                self?.step.accept(AppStep.createTaskDone)
            })
            .disposed(by: disposeBag)
    }

    private func bindTopicField() {
        taskFormView.topicField.rx
            .text
            .orEmpty
            .bind(to: viewModel.topicText)
            .disposed(by: disposeBag)
    }

    private func bindIsAllDayButton() {
        taskFormView.isAllDayButton
            .rx
            .tap
            .asDriver()
            .drive(onNext: { [weak self] in
                let isAllDayButton = self?.taskFormView.isAllDayButton
                let isAllDay = isAllDayButton?.isSelected ?? false
                isAllDayButton?.isSelected = !isAllDay
                isAllDayButton?.tintColor = !isAllDay ? App.Color.azure : App.Color.coolGrey
                self?.viewModel.isAllDay.onNext(!isAllDay)
            })
            .disposed(by: disposeBag)
    }

    private func bindReminderField() {
        taskFormView.reminderField.rx
            .text
            .orEmpty
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                let reminders = Task.Reminder.all()
                let idx = self.taskFormView.reminderField.pickerView.selectedRow(inComponent: 0)
                self.viewModel.reminder.onNext(reminders[idx].rawValue)
            })
            .disposed(by: disposeBag)
    }

    private func bindStartDateField() {
        taskFormView.startDateField.rx
            .text
            .orEmpty
            .subscribe(onNext: { [weak self] text in
                guard let `self` = self else { return }
                let date = self.taskFormView.startDateField.dateFormatter.date(from: text) ?? Date()
                self.viewModel.startDate.onNext(date)
            })
            .disposed(by: disposeBag)
    }

    private func bindEndDateField() {
        taskFormView.endDateField.rx
            .text
            .orEmpty
            .subscribe(onNext: { [weak self] text in
                guard let `self` = self else { return }
                let date = self.taskFormView.endDateField.dateFormatter.date(from: text) ?? Date()
                self.viewModel.endDate.onNext(date)
            })
            .disposed(by: disposeBag)
    }

    private func bindExecutorAndParticipantsFields() {
        if viewModel.employeesViewModel.employees.value.isEmpty {
            viewModel.employeesViewModel.getEmployees()
        }

        viewModel.employeesViewModel.onSuccess.subscribe(onNext: { [weak self] _ in
            self?.taskFormView.participantsField.reloadContents()
            if self?.taskFormView.participantsField.isFirstResponder ?? false {
                self?.taskFormView.participantsField.setLoading(
                    self?.viewModel.employeesViewModel.loading.value ?? false
                )
            }

            self?.taskFormView.executorField.reloadContents()
            if self?.taskFormView.executorField.isFirstResponder ?? false {
                self?.taskFormView.executorField.setLoading(
                    self?.viewModel.employeesViewModel.loading.value ?? false
                )
            }
        }).disposed(by: disposeBag)

        taskFormView.didDeleteParticipant = { [weak self] fullname in
            guard let `self` = self else { return }
            self.viewModel.participants = self.viewModel.participants.filter({ employee -> Bool in
                return employee.fullname != fullname
            })
        }

        viewModel.employeesViewModel.filteredEmployees
            .observeOn(MainScheduler.instance)
            .skip(1)
            .subscribe(onNext: { [weak self] _ in
                self?.taskFormView.participantsField.reloadContents()
                self?.taskFormView.executorField.reloadContents()
            })
            .disposed(by: disposeBag)

        taskFormView.participantsField.autoSuggestionDataSource = self
        taskFormView.participantsField.observeChanges()

        let emptyView1 = UIView()
        let label1 = UILabel()
        label1.text = NSLocalizedString("no_matches", comment: "")
        label1.font = App.Font.body
        label1.textAlignment = .center
        label1.textColor = App.Color.steel
        emptyView1.addSubview(label1)
        label1.snp.makeConstraints { (make) in
            make.edges.equalTo(emptyView1)
        }
        taskFormView.participantsField.emptyView = emptyView1

        taskFormView.participantsField.keyboardDistanceFromTextField = 50

        taskFormView.executorField.autoSuggestionDataSource = self
        taskFormView.executorField.observeChanges()

        let emptyView2 = UIView()
        let label2 = UILabel()
        label2.text = NSLocalizedString("no_matches", comment: "")
        label2.font = App.Font.body
        label2.textAlignment = .center
        label2.textColor = App.Color.steel
        emptyView2.addSubview(label2)
        label2.snp.makeConstraints { (make) in
            make.edges.equalTo(emptyView2)
        }
        taskFormView.executorField.emptyView = emptyView2
    }

    private func bindTypeField() {
        taskFormView.typeField.rx
            .text
            .orEmpty
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                let taskTypes = Task.TaskType.all()
                let idx = self.taskFormView.typeField.pickerView.selectedRow(inComponent: 0)
                self.viewModel.reminder.onNext(taskTypes[idx].rawValue)
            })
            .disposed(by: disposeBag)
    }

    private func bindTextField() {
        taskFormView.textField.rx
            .text
            .orEmpty
            .bind(to: viewModel.taskText)
            .disposed(by: disposeBag)
    }

    private func bindAttachmentButton() {
        taskFormView.attachmentsView.didTapAdd = { [weak self] in
            self?.pickAttachments()
        }
        taskFormView.addAttachmentButton.rx.tap.asDriver().throttle(0.5).drive(onNext: { [weak self] in
            self?.pickAttachments()
        }).disposed(by: disposeBag)
    }

    private func bindSendButton() {
        viewModel.taskCreateIsPendingSubject.subscribe(onNext: { [weak self] isPending in
            guard let `self` = self else { return }
            self.taskFormView.sendButton.buttonState = isPending ? .loading : .normal
        }).disposed(by: disposeBag)

        taskFormView.sendButton.rx.tap.asDriver().throttle(0.5).drive(onNext: { [weak self] in
            self?.view.endEditing(true)

            let attachments = self?.taskFormView.attachmentsView.attachments.map { $0.url } ?? []
            self?.viewModel.attachments.onNext(attachments)

            self?.viewModel.createTask()
        }).disposed(by: disposeBag)
    }

}

extension TaskFormViewController: IQMediaPickerControllerDelegate, UINavigationControllerDelegate {
    func mediaPickerController(_ controller: IQMediaPickerController,
                               didFinishMediaWithInfo info: [AnyHashable : Any]) {
        var attachments = [Attachment]()

        for key in info.keys where key is String {
            if let dicts = info[key] as? [[String: Any]] {
                for dict in dicts {
                    if let image = dict[IQMediaImage] as? UIImage {
                        let tempDir = NSTemporaryDirectory()
                        let tempDirPath = URL(fileURLWithPath: tempDir)
                        let imageName = UUID().uuidString
                        let imagePath = tempDirPath.appendingPathComponent("\(imageName).jpg")
                        if FileManager.default.fileExists(atPath: imagePath.path) {
                            try? FileManager.default.removeItem(at: imagePath)
                        }
                        let imageData = UIImageJPEGRepresentation(image, 1.0)
                        do {
                            try imageData?.write(to: imagePath)

                            let attachment = Attachment(url: imagePath, type: .image)
                            attachments.append(attachment)
                        } catch {
                            print("Failed to write image at path \(imagePath)")
                        }
                    } else if let url = dict[IQMediaURL] as? URL {
                        add(videlURL: url)
                    } else if let url = dict[IQMediaAssetURL] as? URL {
                        add(videlURL: url)
                    }
                }
            }
        }

        taskFormView.add(attachments: attachments)
    }

    func mediaPickerControllerDidCancel(_ controller: IQMediaPickerController) {
        print("Media pick cancelled ...")
    }
}

extension TaskFormViewController: FileExplorerViewControllerDelegate {
    func fileExplorerViewControllerDidFinish(_ controller: FileExplorerViewController) {
        print("File explorer did finish ...")
    }

    func fileExplorerViewController(_ controller: FileExplorerViewController, didChooseURLs urls: [URL]) {
        print("Attached files with urls - \(urls)")

        let attachments = urls.map { url -> Attachment in
            let extensionName = url.pathExtension.lowercased()
            if extensionName.hasSuffix("png")
                || extensionName.hasSuffix("jpg")
                || extensionName.hasSuffix("jpeg") {
                return Attachment(url: url, type: .image)
            }

            return Attachment(url: url, type: .file)
        }
        taskFormView.add(attachments: attachments)
    }
}

//swiftlint:disable line_length
extension TaskFormViewController: UITextFieldAutoSuggestionDataSource {
    func autoSuggestionField(_ field: UITextField!, tableView: UITableView!, cellForRowAt indexPath: IndexPath!, forText text: String!) -> UITableViewCell! {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: App.CellIdentifier.suggestionCellId)

        let cell = tableView.dequeueReusableCell(withIdentifier: App.CellIdentifier.suggestionCellId, for: indexPath)
        let employees = viewModel.employeesViewModel.filteredEmployees.value
        if employees.count > indexPath.row {
            cell.textLabel?.text = employees[indexPath.row].employee.fullname
        }
        return cell
    }

    func autoSuggestionField(_ field: UITextField!, tableView: UITableView!, numberOfRowsInSection section: Int, forText text: String!) -> Int {
        return viewModel.employeesViewModel.filteredEmployees.value.count
    }

    func autoSuggestionField(_ field: UITextField!, tableView: UITableView!, didSelectRowAt indexPath: IndexPath!, forText text: String!) {
        let employees = viewModel.employeesViewModel.filteredEmployees.value
        
        if employees.count > indexPath.row {
            if field == taskFormView.participantsField {
                viewModel.participants.insert(employees[indexPath.row].employee)
                taskFormView.tagsCollectionView.addTag(employees[indexPath.row].employee.fullname)
                taskFormView.participantsField.text = nil
            } else {
                viewModel.executor = employees[indexPath.row].employee
                taskFormView.executorField.text = employees[indexPath.row].employee.fullname
            }
        }
    }

    func autoSuggestionField(_ field: UITextField!, textChanged text: String!) {
        
        print("---- text", text)
        
        viewModel.employeesViewModel.filter(with: text)
    }
}
//swiftlint:enable line_length











