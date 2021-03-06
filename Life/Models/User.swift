//
//  User.swift
//  Life
//
//  Created by Shyngys Kassymov on 14.02.2018.
//  Copyright © 2018 Shyngys Kassymov. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift
import RxCocoa

struct User: Codable {

    enum Role: String, Codable {
        case hr = "HR"
        case pr = "PR"
        case lean = "LEAN"
        case moderator = "MODERATOR"
        case top7 = "TOP7"
    }

    var token: String?
    var login: String
    var employeeCode: String
    var roles = [Role]()

    //swiftlint:disable redundant_optional_initialization
    var profile: UserProfile? = nil
    //swiftlint:enable redundant_optional_initialization

    let updated = BehaviorRelay<UserProfile?>(value: nil)

    var canCreateNews: Bool {
        return roles.contains(.hr) || roles.contains(.pr) || roles.contains(.moderator)
    }

    var canVideoAnswerTopQuestion: Bool {
        return roles.contains(.top7) || roles.contains(.moderator)
    }

    init(token: String?, login: String, employeeCode: String, roles: [Role]) {
        self.token = token
        self.login = login
        self.employeeCode = employeeCode
        self.roles = roles
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case token
        case login
        case employeeCode
        case roles
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.token = try container.decodeWrapper(key: .token, defaultValue: "")
        self.login = try container.decodeWrapper(key: .login, defaultValue: "")
        self.employeeCode = try container.decodeWrapper(key: .employeeCode, defaultValue: "")

        self.roles = []
        if let strRoles = (try? container.decodeWrapper(key: .roles, defaultValue: [String]())) {
            self.roles = strRoles.compactMap { Role(rawValue: $0) }
        }
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(token, forKey: "token")
        aCoder.encode(login, forKey: "login")
        aCoder.encode(employeeCode, forKey: "employeeCode")
        aCoder.encode(roles.map { $0.rawValue }, forKey: "roles")
    }

    // MARK: - Methods

    private static var _current: User?
    static var current: User {
        get {
            if _current != nil {
                return _current!
            }

            let token = UserDefaults.standard.string(forKey: App.Key.userToken)
            let login = UserDefaults.standard.string(forKey: App.Key.userLogin) ?? ""
            let employeeCode = UserDefaults.standard.string(forKey: App.Key.userEmployeeCode) ?? ""

            var roles = [Role]()
            if let strRoles = UserDefaults.standard.object(forKey: App.Key.userRoles) as? [String] {
                roles = strRoles.compactMap { Role(rawValue: $0) }
            }

            _current = User(token: token, login: login, employeeCode: employeeCode, roles: roles)

            if let profileData = UserDefaults.standard.data(forKey: App.Key.userProfile),
                let profile = try? PropertyListDecoder().decode(UserProfile.self, from: profileData) {
                _current?.profile = profile
                _current?.updated.accept(profile)
            }

            return _current!
        }
        set(newValue) {
            _current = newValue
        }
    }

    var isAuthenticated: Bool {
        return token != nil
    }

    public func save() {
        if let token = token {
            UserDefaults.standard.set(token, forKey: App.Key.userToken)
        }
        if let profile = profile,
            let data = try? PropertyListEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: App.Key.userProfile)
        }
        UserDefaults.standard.set(login, forKey: App.Key.userLogin)
        UserDefaults.standard.set(employeeCode, forKey: App.Key.userEmployeeCode)
        UserDefaults.standard.set(roles.map { $0.rawValue }, forKey: App.Key.userRoles)
        UserDefaults.standard.synchronize()

        updated.accept(profile)
    }

    public func logout() {
        User._current = nil

        UserDefaults.standard.set(nil, forKey: App.Key.userToken)
        UserDefaults.standard.set(nil, forKey: App.Key.userProfile)
        UserDefaults.standard.set(login, forKey: App.Key.userLogin)
        UserDefaults.standard.set(nil, forKey: App.Key.userEmployeeCode)
        UserDefaults.standard.set(nil, forKey: App.Key.userRoles)
        UserDefaults.standard.synchronize()

        removeUserRelatedData()
    }

    private func removeUserRelatedData() {
        DispatchQueue.global().async {
            do {
                // tasks and requests
                var tasksAndRequestsRealms = [Realm]()

                let inboxTasksRealm = try App.Realms.inboxTasksAndRequests()
                tasksAndRequestsRealms.append(inboxTasksRealm)

                let outboxTasksRealm = try App.Realms.outboxTasksAndRequests()
                tasksAndRequestsRealms.append(outboxTasksRealm)

                for realm in tasksAndRequestsRealms {
                    realm.beginWrite()
                    realm.delete(realm.objects(TaskObject.self))
                    realm.delete(realm.objects(RequestObject.self))
                    try realm.commitWrite()
                }

                // notifications
                let notifictationsRealm = try App.Realms.notifications()
                notifictationsRealm.beginWrite()
                notifictationsRealm.delete(notifictationsRealm.objects(NotificationObject.self))
                try notifictationsRealm.commitWrite()
            } catch {
                print("Failed to access the Realm database")
            }
        }
    }

}

struct UserProfile: Codable {
    var fullname: String
    var employeeCode: String
    var jobPosition: String
    var company: String
    var iin: String
    var birthDate: String
    var gender: String
    var familyStatus: String
    var childrenQuantity: String
    var clothingSize: String
    var shoeSize: String
    var email: String
    var workPhoneNumber: String
    var mobilePhoneNumber: String
    var address: String
    var totalExperience: String
    var corporateExperience: String
    var administrativeChiefName: String?
    var functionalChiefName: String?
    var educations: [Education]
    var medicalExamination: MedicalExamination
    var adLogin: String
    var history: [HistoryRelocation]

    // MARK: - Decodable

    enum CodingKeys: String, CodingKey {
        case fullname
        case employeeCode
        case jobPosition
        case company
        case iin
        case birthDate
        case gender
        case familyStatus
        case childrenQuantity
        case clothingSize
        case shoeSize
        case email
        case workPhoneNumber
        case mobilePhoneNumber
        case address
        case totalExperience
        case corporateExperience
        case administrativeChiefName
        case functionalChiefName
        case educations
        case medicalExamination
        case adLogin
        case history
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.fullname = try container.decodeWrapper(key: .fullname, defaultValue: "")
        self.employeeCode = try container.decodeWrapper(key: .employeeCode, defaultValue: "")
        self.jobPosition = try container.decodeWrapper(key: .jobPosition, defaultValue: "")
        self.company = try container.decodeWrapper(key: .company, defaultValue: "")
        self.iin = try container.decodeWrapper(key: .iin, defaultValue: "")
        self.birthDate = try container.decodeWrapper(key: .birthDate, defaultValue: "")
        self.gender = try container.decodeWrapper(key: .gender, defaultValue: "")
        self.familyStatus = try container.decodeWrapper(key: .familyStatus, defaultValue: "")
        self.childrenQuantity = try container.decodeWrapper(key: .childrenQuantity, defaultValue: "")
        self.clothingSize = try container.decodeWrapper(key: .clothingSize, defaultValue: "")
        self.shoeSize = try container.decodeWrapper(key: .shoeSize, defaultValue: "")
        self.email = try container.decodeWrapper(key: .email, defaultValue: "")
        self.workPhoneNumber = try container.decodeWrapper(key: .workPhoneNumber, defaultValue: "")
        self.mobilePhoneNumber = try container.decodeWrapper(key: .mobilePhoneNumber, defaultValue: "")
        self.address = try container.decodeWrapper(key: .address, defaultValue: "")
        self.totalExperience = try container.decodeWrapper(key: .totalExperience, defaultValue: "")
        self.corporateExperience = try container.decodeWrapper(key: .corporateExperience, defaultValue: "")
        self.administrativeChiefName = try container.decodeWrapper(
            key: .administrativeChiefName,
            defaultValue: ""
        )
        self.functionalChiefName = try container.decodeWrapper(key: .functionalChiefName, defaultValue: "")
        self.educations = try container.decodeWrapper(
            key: .educations,
            defaultValue: []
        )
        self.medicalExamination = try container.decodeWrapper(
            key: .medicalExamination,
            defaultValue: MedicalExamination(
                last: "",
                next: ""
            )
        )
        self.history = try container.decodeWrapper(
            key: .history,
            defaultValue: []
        )
        
        self.adLogin = try container.decodeWrapper(key: .adLogin, defaultValue: "")
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(fullname, forKey: "fullname")
        aCoder.encode(employeeCode, forKey: "employeeCode")
        aCoder.encode(jobPosition, forKey: "jobPosition")
        aCoder.encode(company, forKey: "company")
        aCoder.encode(iin, forKey: "iin")
        aCoder.encode(birthDate, forKey: "birthDate")
        aCoder.encode(gender, forKey: "gender")
        aCoder.encode(familyStatus, forKey: "familyStatus")
        aCoder.encode(childrenQuantity, forKey: "childrenQuantity")
        aCoder.encode(clothingSize, forKey: "clothingSize")
        aCoder.encode(email, forKey: "email")
        aCoder.encode(workPhoneNumber, forKey: "workPhoneNumber")
        aCoder.encode(mobilePhoneNumber, forKey: "mobilePhoneNumber")
        aCoder.encode(address, forKey: "address")
        aCoder.encode(totalExperience, forKey: "totalExperience")
        aCoder.encode(corporateExperience, forKey: "corporateExperience")
        aCoder.encode(administrativeChiefName, forKey: "administrativeChiefName")
        aCoder.encode(functionalChiefName, forKey: "functionalChiefName")
        aCoder.encode(educations, forKey: "educations")
        aCoder.encode(medicalExamination, forKey: "medicalExamination")
        aCoder.encode(adLogin, forKey: "adLogin")
        aCoder.encode(history, forKey: "history")
    }
}

struct Education: Codable {
    var educationTypeName: String
    var institutionName: String
    var graduationYear: Int
    var specialty: String

    // MARK: - Decodable

    enum CodingKeys: String, CodingKey {
        case educationTypeName
        case institutionName
        case graduationYear
        case specialty
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.educationTypeName = try container.decodeWrapper(key: .educationTypeName, defaultValue: "")
        self.institutionName = try container.decodeWrapper(key: .institutionName, defaultValue: "")
        self.graduationYear = try container.decodeWrapper(key: .graduationYear, defaultValue: 0)
        self.specialty = try container.decodeWrapper(key: .specialty, defaultValue: "")
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(educationTypeName, forKey: "educationTypeName")
        aCoder.encode(institutionName, forKey: "institutionName")
        aCoder.encode(graduationYear, forKey: "graduationYear")
        aCoder.encode(specialty, forKey: "specialty")
    }
}

// ---------------------

struct HistoryRelocation: Codable {
    var employmentType: String
    var eventType: String
    var employeeName: String
    var position: String
    var organization: String
    var department: String
    var eventDate: String
    var employeeCode: String
    
    // MARK: - Decodable
    
    enum CodingKeys: String, CodingKey {
        case employmentType
        case eventType
        case employeeName
        case position
        case organization
        case department
        case eventDate
        case employeeCode
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.employmentType = try container.decodeWrapper(key: .employmentType, defaultValue: "")
        self.eventType = try container.decodeWrapper(key: .eventType, defaultValue: "")
        self.employeeName = try container.decodeWrapper(key: .employeeName, defaultValue: "")
        self.position = try container.decodeWrapper(key: .position, defaultValue: "")
        
        self.organization = try container.decodeWrapper(key: .organization, defaultValue: "")
        self.department = try container.decodeWrapper(key: .department, defaultValue: "")
        self.eventDate = try container.decodeWrapper(key: .eventDate, defaultValue: "")
        self.employeeCode = try container.decodeWrapper(key: .employeeCode, defaultValue: "")
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(employmentType, forKey: "employmentType")
        aCoder.encode(eventType, forKey: "eventType")
        aCoder.encode(employeeName, forKey: "employeeName")
        aCoder.encode(position, forKey: "position")
        aCoder.encode(organization, forKey: "organization")
        aCoder.encode(department, forKey: "department")
        aCoder.encode(eventDate, forKey: "eventDate")
        aCoder.encode(employeeCode, forKey: "employeeCode")
    }
}

// ---------------------

struct MedicalExamination: Codable {
    var last: String?
    var next: String?

    init(last: String?, next: String?) {
        self.last = last
        self.next = next
    }

    // MARK: - Decodable

    enum CodingKeys: String, CodingKey {
        case last
        case next
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.last = try container.decodeWrapper(key: .last, defaultValue: nil)
        self.next = try container.decodeWrapper(key: .next, defaultValue: nil)
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(last, forKey: "last")
        aCoder.encode(next, forKey: "next")
    }
}
