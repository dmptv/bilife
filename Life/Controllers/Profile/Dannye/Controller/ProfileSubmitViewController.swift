//
//  ProfileSubmitViewController.swift
//  Life
//
//  Created by 123 on 05.08.2018.
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
import Moya
import Moya_ModelMapper
import Material


class ProfileSubmitViewController: UIViewController {

    lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.dataSource = self
        tv.delegate = self
        tv.contentInset = UIEdgeInsetsMake(0, 0, 100, 0)
        return tv
    }()

    var image: UIImage?
    var addedImageView: UIImageView = {
        let iv = UIImageView()
        iv.isHidden = true
        return iv
    }()
    var addPhotoLabel: UILabel = {
        let lbl = UILabel()
         lbl.isHidden = false
        return lbl
    }()
    var descriptionTextView: UITextView = {
        let tv = UITextView()
        return tv
    }()
    
    lazy var hrCardTableView: HRCardTableView = {
        let view = HRCardTableView()
        view.isHidden = true
        view.delegate = self
        return view
    }()
    
    var pickedHRTextfield: UITextField = {
        let tf = UITextField()
        return tf
    }()

    private let disposeBag = DisposeBag()
    
    private let provider = MoyaProvider<UserProfileService>(
        plugins: [
            AuthPlugin(tokenClosure: {
                return User.current.token
            })
        ]
    )
    
    var attachments = [URL]()
    var hrperson: HRPerson?
    
    var isLoading = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
    
        setupViews()
    }

    private func setupViews() {
        setupTableView()
        setupCloseButton()
        setupHRCardTableView()
    }
    
    fileprivate func setupTableView() {
        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        tableView.register(UserSubmitDescriptionCell.self, forCellReuseIdentifier: UserSubmitDescriptionCell.identifier)
        tableView.register(UserSubmitImageCell.self, forCellReuseIdentifier: UserSubmitImageCell.identifier)
        tableView.register(UserPickExecutorCell.self, forCellReuseIdentifier: UserPickExecutorCell.identifier)
        tableView.register(UserSendButtonCell.self, forCellReuseIdentifier: UserSendButtonCell.identifier)
        
        tableView.separatorStyle = .none
        tableView.allowsSelection = true
    }
    
    fileprivate func setupHRCardTableView() {
        view.addSubview(hrCardTableView)
        hrCardTableView.snp.makeConstraints {
            $0.top.equalTo(view.snp.top)
            $0.left.equalTo(view.snp.left)
            $0.right.equalTo(view.snp.right)
            $0.height.equalTo(300)
            
        }
    }
    
    fileprivate func setupCloseButton() {
        let closeBtn = UIBarButtonItem(image: #imageLiteral(resourceName: "close-circle-dark").withRenderingMode(.alwaysOriginal), style: .done, target: self, action: #selector(closeAction))
        navigationItem.rightBarButtonItem = closeBtn
    }
    
    @objc
    fileprivate func closeAction() {
        sendCloseAction()
    }
    
    private func sendCloseAction() {
        dismiss(animated: true, completion: nil)
    }
    
    deinit {
        print("*** deinit \(self)")
    }
  
}

//MARK: - UITableView DataSource
extension ProfileSubmitViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            let cell = tableView.dequeueReusableCell(withIdentifier: UserSubmitDescriptionCell.identifier, for: indexPath) as! UserSubmitDescriptionCell
            
            self.descriptionTextView = cell.descriptionTextView
            
            return cell
        case (1, 0):
            let cell = tableView.dequeueReusableCell(withIdentifier: UserSubmitImageCell.identifier, for: indexPath) as! UserSubmitImageCell
            
            cell.addPhotoLabel.text = NSLocalizedString("Выбрать фото", comment: "")
            self.addPhotoLabel = cell.addPhotoLabel
            self.addedImageView = cell.addImageView
            
            return cell
        case (2,0):
            let cell = tableView.dequeueReusableCell(withIdentifier: UserPickExecutorCell.identifier, for: indexPath) as! UserPickExecutorCell
            
            self.pickedHRTextfield = cell.executorTextField
            cell.delegate = self
            
            return cell
        case (3,0):
            let cell = tableView.dequeueReusableCell(withIdentifier: UserSendButtonCell.identifier, for: indexPath) as! UserSendButtonCell
            
            cell.sendButton.addTarget(self, action: #selector(ProfileSubmitViewController.sendData(_:)), for: .touchUpInside)
            
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    @objc
    private func sendData(_ sender : Button) {
        guard let hrperson = hrperson else { return }
        
        isLoading = false
        
        sender.buttonState = isLoading ? .loading : .normal
    
        provider
        .rx
        .request(.errors(
            executor: hrperson.code,
            description: descriptionTextView.text,
            attachments: attachments)
            )
            .filterSuccessfulStatusCodes()
            .subscribe { [weak self] response in
                guard let weakSelf = self else { return }
                
                weakSelf.isLoading = true
                sender.buttonState = weakSelf.isLoading ? .loading : .normal

                switch response {
                case .success(let json):
                    
                    print(json)
                    
                    weakSelf.sendCloseAction()
                  
                case .error(let error):
                    
                    let errorMessages = error.parseMessages()
                    if let key = errorMessages.keys.first,
                        let message = errorMessages[key] {
                        weakSelf.showToast(message)
                    }

                    print(error)
                }
            }
            .disposed(by: disposeBag)
        
    }
  
}

//MARK: - UITableView Delegate
extension ProfileSubmitViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath.section == 0 || indexPath.section == 1 || indexPath.section == 3 {
            // only three sections are tappable
            return indexPath
        } else {
            // tap здесь не срабатывает
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 && indexPath.row == 0 {
            // if we tap not exactly on text view
      
            let cell = tableView.cellForRow(at: indexPath) as! UserSubmitDescriptionCell
            cell.descriptionTextView.becomeFirstResponder()
            
        } else if indexPath.section == 1 && indexPath.row == 0 {
            tableView.deselectRow(at: indexPath, animated: true)
            pickPhoto()
            
        } else if indexPath.section == 3 && indexPath.row == 0 {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch (section) {
        case (0):
            return 50
        default:
            return 50
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            return 88
        case (1, 0):
            return addedImageView.isHidden ? 44 : 280
        case (2, 0):
            return 84
        default:
            return 44
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch (section) {
        case (0):
            return NSLocalizedString("Описание", comment: "")
        case 1:
            return NSLocalizedString("Изображение", comment: "")
        case 2:
            return NSLocalizedString("Исполнитель", comment: "")
        default:
            return ""
        }
    }
}

//MARK: - UserPickExecutorCell Delegate
extension ProfileSubmitViewController: UserPickExecutorCellDelegate {
    func showTableView(sender: UserPickExecutorCell, hrList: [HRPerson]) {
        // Cell tels to show card with table
        hrCardTableView.isHidden = false
        hrCardTableView.hrPersons = hrList
    }
}

//MARK: - HRCardTableView Delegate
extension ProfileSubmitViewController: HRCardTableViewDelegate {
    
    // Card tels that person is picked
    func hideView(sender: HRCardTableView, hr: HRPerson?) {
        DispatchQueue.main.async { [weak self] in
            UIView.animate(withDuration: 0.3, delay: 0.1, usingSpringWithDamping: 1, initialSpringVelocity: 0.1, options: UIViewAnimationOptions.curveEaseInOut, animations: {
                if let hr = hr {
                    self?.hrperson = hr
                    self?.pickedHRTextfield.text = hr.fullname
                }
                self?.hrCardTableView.isHidden = true
            })
        }
    }
}


//MARK: - UIImagePickerController Delegate
extension ProfileSubmitViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {

    
        let imageUrl          = info[UIImagePickerControllerReferenceURL] as! NSURL
        let imageName         = imageUrl.lastPathComponent
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let photoURL          = NSURL(fileURLWithPath: documentDirectory)
        let localPath         = photoURL.appendingPathComponent(imageName!)
        let image             = info[UIImagePickerControllerOriginalImage] as! UIImage
        let data              = UIImagePNGRepresentation(image)
        
        do {
            try data?.write(to: localPath!, options: Data.WritingOptions.atomic)
        } catch {
            // Catch exception here and act accordingly
        }
        
        if let url = localPath {
            attachments.append(url)
            show(image: image)
        }
        
        //---
        
        tableView.reloadData()
        dismiss(animated: true, completion: nil)
    }
    
    func show(image: UIImage) {
        addedImageView.image = image
        addedImageView.isHidden = false
        addedImageView.frame = CGRect(x: 10, y: 10, width: 260, height: 260)
        addPhotoLabel.isHidden = true
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    fileprivate func takePhotoWithCamera() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }
    
    fileprivate func choosePhotoFromLibrary() {
        let imagePicker = MyImagePickerController()
        imagePicker.view.tintColor = view.tintColor
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }
    
    fileprivate func pickPhoto() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            showPhotoMenu()
        } else {
            choosePhotoFromLibrary()
        }
    }
    
    fileprivate func showPhotoMenu() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        let takePhotoAction = UIAlertAction(title: "Take Photo", style: .default) { _ in
            self.takePhotoWithCamera()
        }
        alertController.addAction(takePhotoAction)
        let chooseFromLibraryAction = UIAlertAction(title:"Choose From Library", style: .default) { _ in self.choosePhotoFromLibrary()
        }
        alertController.addAction(chooseFromLibraryAction)
        present(alertController, animated: true, completion: nil)
    }
}

class MyImagePickerController: UIImagePickerController {
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
}


















