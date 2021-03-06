//
//  ProfileViewController2.swift
//  Life
//
//  Created by 123 on 31.07.2018.
//  Copyright © 2018 Shyngys Kassymov. All rights reserved.
//

import UIKit
import Kingfisher
import Material
import RxSwift
import RxCocoa
import SnapKit

class MyInfoViewControllerTableView: UIViewController {
    
    fileprivate let dataSource = MyInfoDataSourse()
    fileprivate var profile: UserProfile?
    fileprivate let disposeBag = DisposeBag()
    
    private var fabButton: FABButton = {
        let fabImg = #imageLiteral(resourceName: "profile_fab").resize(toWidth: 25)?.resize(toHeight: 25)
        let fabButton = FABButton(image: fabImg, tintColor: .white)
        fabButton.pulseColor = .white
        fabButton.backgroundColor = App.Color.white
        fabButton.shadowColor = App.Color.black24
        fabButton.depth = Depth(offset: Offset.init(horizontal: 0, vertical: 12), opacity: 1, radius: 12)
        fabButton.addTarget(self, action: #selector(onTappedFabButton), for: .touchUpInside)
        return fabButton
    }()
    
    fileprivate var collapsed = false
    
    public var didTapAvatar: (() -> Void)?
   
    lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.dataSource = dataSource
        tv.delegate = dataSource
        return tv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bindToDataSorceClousers()
        bind()
        setupViews()
    }
    
    fileprivate func bindToDataSorceClousers() {

        dataSource.reloadSections = { [weak self] section in
            guard let `self` = self else { return }
            
            self.tableView.beginUpdates()
            self.tableView.reloadSections([section], with: .automatic)
            self.tableView.endUpdates()
        }

        dataSource.scrolToRow = { [weak self] indexPath in
            guard let `self` = self else { return }
            
            self.tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
        }
    
    }
    
    // MARK: - Setup Views
    fileprivate func setupViews() {
        setupTabItem()
        setupTableView()
        setupFabButton()
    }
    
    fileprivate func setupTabItem() {
        tabItem.title = NSLocalizedString("данные", comment: "").uppercased()
        tabItem.titleLabel?.font = App.Font.buttonSmall
    }
    
    fileprivate func setupTableView() {
        tableView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
        view.addSubview(tableView)
        
        tableView.register(UserFoldHeaderView.self, forHeaderFooterViewReuseIdentifier: UserFoldHeaderView.identifier)
        
        tableView.register(UserHeaderTableCell.self, forCellReuseIdentifier: UserHeaderTableCell.identifier)
        tableView.register(UserPersonalCell.self, forCellReuseIdentifier: UserPersonalCell.identifier)
        tableView.register(UserPictureCell.self, forCellReuseIdentifier: UserPictureCell.identifier)
        tableView.register(UserEducationCell.self, forCellReuseIdentifier: UserEducationCell.identifier)

        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.contentInset = UIEdgeInsetsMake(0, 0, 200, 0)
        tableView.bounces = true
    }

    // MARK: - Bind
    fileprivate func bind() {
        User.current.updated.asDriver().drive(onNext: { [weak self] profile in
            guard let `self` = self else { return }
            
            self.updateUI(with: profile)
        }).disposed(by: disposeBag)
    }
    
    private func updateUI(with profile: UserProfile?) {
        self.profile = profile
    }
    
    private func setupFabButton() {
        view.addSubview(fabButton)
        fabButton.snp.makeConstraints { (make) in
            make.bottom.equalTo(self.view).inset(App.Layout.tabBarHeight)
            make.right.equalTo(self.view).inset(App.Layout.sideOffset)
            make.size.equalTo(CGSize(width: 56, height: 56))
        }
    }

}

extension MyInfoViewControllerTableView {
    @objc fileprivate
    func onTappedFabButton() {
        let vc = ProfileSubmitViewController()
        let nav = UINavigationController(rootViewController: vc)
        
        present(nav, animated: true, completion: nil)
    }
}















