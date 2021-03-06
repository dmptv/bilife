//
//  MyInfoDataSourse.swift
//  Life
//
//  Created by 123 on 01.08.2018.
//  Copyright © 2018 Shyngys Kassymov. All rights reserved.
//

import UIKit
import Kingfisher
import Material
import RxSwift
import RxCocoa
import SnapKit

class MyInfoDataSourse:  NSObject {
    var items = [ProfileViewModelItem]()
    var profile: UserProfile?

    var reloadSections: ( (_ section: Int) -> Void )?
    var showVCDetails: ( (_ profile: UserProfile) -> Void )?
    var showVCHistoryDetails: ( (_ profile: UserProfile) -> Void )?
    var scrolToRow: ( (_ indexPath: IndexPath) -> Void )?
    var indexPathForscroll: IndexPath!
    
    private let disposeBag = DisposeBag()
    
    override init() {
        super.init()
        
        bind()
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
        
        if let profile = profile {
            let pictureItem = ProfileViewModePictureItem()
            items.append(pictureItem)
            
            let headerItem = ProfileViewModeHeaderItem()
            items.append(headerItem)
            
            let personalItem = ProfileViewModelPersonalItem()
            items.append(personalItem)
            
            let workActivities = ProfileViewModelWorkActivitiesItem()
            items.append(workActivities)
            
            let medicalItem = ProfileViewModelMedicalItem()
            items.append(medicalItem)
            
            let educationItem = ProfileViewModelEducationItem(profile: profile)
            items.append(educationItem)
            
            let history = ProfileViewModelHistoryItem(profile: profile)
            items.append(history)
        }
    }
    
}

// MARK: - UITableView DataSource
extension MyInfoDataSourse: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let item = items[section]
        guard item.isCollapsible else {
            return item.rowCount
        }
        
        // when the section is collapsed, we will set its row count to zero
        if item.isCollapsed {
            return 0
        } else {
            return item.rowCount
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let modelItem = items[indexPath.section]
        switch modelItem.type {
        case .bigPicture:
                if let cell = tableView.dequeueReusableCell(withIdentifier: UserPictureCell.identifier, for: indexPath) as? UserPictureCell {
                    cell.item = profile
                    cell.modelItem = modelItem
                    return cell
            }
        case .nameAndPicture:
            if let cell = tableView.dequeueReusableCell(withIdentifier: UserHeaderTableCell.identifier, for: indexPath) as? UserHeaderTableCell {
                cell.item = profile
                cell.modelItem = modelItem
                
                if indexPath.row == 0 {
                    cell.pictureImageView.image = #imageLiteral(resourceName: "domain").withRenderingMode(.alwaysTemplate)
                    cell.companyLabel.text = profile?.company
                } else if indexPath.row == 1 {
                    cell.pictureImageView.image = #imageLiteral(resourceName: "mobile").withRenderingMode(.alwaysTemplate)
                    cell.companyLabel.text = profile?.mobilePhoneNumber
                } else if indexPath.row == 2 {
                    cell.pictureImageView.image = #imageLiteral(resourceName: "mail").withRenderingMode(.alwaysTemplate)
                    cell.companyLabel.text = profile?.email
                } else if indexPath.row == 3 {
                    cell.pictureImageView.image = #imageLiteral(resourceName: "phone-inactive").withRenderingMode(.alwaysTemplate)
                    cell.companyLabel.text = profile?.workPhoneNumber
                }
                                
                return cell
            }
        case .personal:
            if let cell = tableView.dequeueReusableCell(withIdentifier: UserPersonalCell.identifier, for: indexPath) as? UserPersonalCell {
                cell.modelItem = modelItem
                
                self.indexPathForscroll = indexPath
                
                if indexPath.row == 0 {
                    cell.txtLabel.text = NSLocalizedString("ИИН", comment: "")
                    cell.detailLabel.text = NSLocalizedString("\(String(describing: profile?.iin ?? ""))", comment: "")
                    cell.rightTxtLabel.text = NSLocalizedString("Дата рождения", comment: "")
                    cell.rightDetailLabel.text = NSLocalizedString("\(String(describing: profile?.birthDate ?? "").prettyDateStringNoSeconds())", comment: "")
                    
                } else if indexPath.row == 1 {
                    cell.txtLabel.text = NSLocalizedString("Семейное положение", comment: "")
                    cell.detailLabel.text = NSLocalizedString("\(String(describing: profile?.familyStatus ?? ""))", comment: "")
                    cell.rightTxtLabel.text = NSLocalizedString("Пол", comment: "")
                    cell.rightDetailLabel.text = NSLocalizedString("\(String(describing: profile?.gender ?? ""))", comment: "")
                    
                } else if indexPath.row == 2 {
                    cell.txtLabel.text = NSLocalizedString("Дети", comment: "")
                    cell.detailLabel.text = NSLocalizedString("\(String(describing: profile?.childrenQuantity ?? ""))", comment: "")
                    cell.rightTxtLabel.text = NSLocalizedString("Размер одежды", comment: "")
                    cell.rightDetailLabel.text = NSLocalizedString("\(String(describing: profile?.clothingSize ?? ""))", comment: "")
                }
                
                return cell
            }
        case .workexperiance:
            if let cell = tableView.dequeueReusableCell(withIdentifier: UserPersonalCell.identifier, for: indexPath) as? UserPersonalCell {
                cell.modelItem = modelItem
                
                self.indexPathForscroll = indexPath
                
                if indexPath.row == 0 {
                    cell.txtLabel.text = NSLocalizedString("Корпоративный стаж (мес)", comment: "")
                    cell.detailLabel.text = NSLocalizedString("\(String(describing: profile?.corporateExperience ?? ""))", comment: "")
                    cell.rightTxtLabel.text = NSLocalizedString("Общий стаж в ГК BI Group (мес)", comment: "")
                    cell.rightDetailLabel.text = NSLocalizedString("\(String(describing: profile?.totalExperience ?? ""))", comment: "")
                    
                } else if indexPath.row == 1 {
                    cell.txtLabel.text = NSLocalizedString("Административный руководитель", comment: "")
                    cell.detailLabel.text = NSLocalizedString("\(String(describing: profile?.administrativeChiefName ?? ""))", comment: "")
                    cell.rightTxtLabel.text = NSLocalizedString("Функциональный руководитель", comment: "")
                    cell.rightDetailLabel.text = NSLocalizedString("\(String(describing: profile?.functionalChiefName ?? ""))", comment: "")
                }
                
                return cell
            }
        case .medical:
            if let cell = tableView.dequeueReusableCell(withIdentifier: UserPersonalCell.identifier, for: indexPath) as? UserPersonalCell {
                cell.modelItem = modelItem
                
                self.indexPathForscroll = indexPath
                
                if indexPath.row == 0 {
                    cell.txtLabel.text = NSLocalizedString("Последнее прохождение", comment: "")
                    cell.detailLabel.text = NSLocalizedString("\(String(describing: profile?.medicalExamination.last ?? "").prettyDateStringNoSeconds())", comment: "")
                    cell.rightTxtLabel.text = NSLocalizedString("Ближайшее", comment: "")
                    cell.rightDetailLabel.text = NSLocalizedString("\(String(describing: profile?.medicalExamination.next ?? "").prettyDateStringNoSeconds())", comment: "")
                }
                return cell
            }
        case .education:
            if let cell = tableView.dequeueReusableCell(withIdentifier: UserEducationCell.identifier, for: indexPath) as? UserEducationCell, let educations = profile?.educations {
                cell.modelItem = modelItem
                
                self.indexPathForscroll = indexPath
                
                let education = educations[indexPath.row]
                
                cell.txtLabel.text = "Вид образования"
                cell.detailLabel.text = education.educationTypeName
                
                cell.rightTxtLabel.text = "Учебное заведение"
                cell.rightDetailLabel.text = education.institutionName
                
                cell.txtLabel1.text = "Специальность"
                cell.detailLabel1.text = education.specialty
                
                cell.rightTxtLabel1.text = "Год окончания"
                cell.rightDetailLabel1.text = "\(education.graduationYear)"
                
                return cell
            }
        case .history:
            if let cell = tableView.dequeueReusableCell(withIdentifier: UserEducationCell.identifier, for: indexPath) as? UserEducationCell, let history = profile?.history {
                cell.modelItem = modelItem
                
                self.indexPathForscroll = indexPath
                
                let historyOne = history[indexPath.row]
                
                cell.txtLabel.text = "Тип"
                cell.detailLabel.text = historyOne.employmentType
                
                cell.rightTxtLabel.text = "Должность"
                cell.rightDetailLabel.text = historyOne.position
                
                cell.txtLabel1.text = "Организация"
                cell.detailLabel1.text = historyOne.organization
                
                cell.rightTxtLabel1.text = "Отдел"
                cell.rightDetailLabel1.text = historyOne.department
                
                return cell
            }
        }
        return UITableViewCell()
    }
}


// MARK: - UITableView Delegate
extension MyInfoDataSourse: UITableViewDelegate {
  
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = UIColor.white
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: UserFoldHeaderView.identifier) as? UserFoldHeaderView {
            
            let modelItem = items[section]
            headerView.modelItem = modelItem
            headerView.section = section
            headerView.delegate = self
            
            return headerView
        }
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let modelItem = items[section]
        switch modelItem.type {
        case .nameAndPicture, .bigPicture:
            return 0
        default:
            return 44.0
        }
    }
 
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let modelItem = items[indexPath.section]
        switch modelItem.type {
        case .bigPicture:
            return 154.00
        case .nameAndPicture:
            return 44.00
        case .personal:
            return 61.00
        case .medical, .workexperiance:
            return 98.33
        default:
            return UITableViewAutomaticDimension
        }
    }
    
}

extension MyInfoDataSourse: HeaderViewDelegate {
    func showHistoryDetails(header: UserFoldHeaderView) {
        if let showVCHistoryDetails = showVCHistoryDetails,
            let profile = profile {
            showVCHistoryDetails(profile)
        }
    }
    
    func showDetails(header: UserFoldHeaderView) { 
        if let showVCDetails = showVCDetails,
            let profile = profile {
            showVCDetails(profile)
        }
    }
    
    func toggleSection(header: UserFoldHeaderView, section: Int) {
        var item = items[section]
        if item.isCollapsible {
            // Toggle collapse
            let collapsed = !item.isCollapsed
            item.isCollapsed = collapsed
            header.setCollapsed(collapsed: collapsed)
            
            // Adjust the number of the rows inside the section
            DispatchQueue.main.async { [weak self] in
                if let reloadSections = self?.reloadSections {
                    reloadSections(section)
                }
                
                if item.isCollapsed == false,
                    let scrolToRow = self?.scrolToRow,
                    let indexpath = self?.indexPathForscroll {
                    
                    scrolToRow(indexpath)
                }
            }
        }
    }
    
}















