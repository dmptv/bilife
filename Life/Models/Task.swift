//
//  Task.swift
//  Life
//
//  Created by Shyngys Kassymov on 19.02.2018.
//  Copyright © 2018 Shyngys Kassymov. All rights reserved.
//

import Foundation

struct Task: Codable, Hashable {

    enum Status: Int, Codable {
        case new = 0
        case inProgress = 10
        case executed = 20
        case confirmed = 50
        case approved = 55
        case reject = 60

        var name: String {
            switch self {
            case .new:
                return NSLocalizedString("task_status_new", comment: "")
            case .inProgress:
                return NSLocalizedString("task_status_in_progress", comment: "")
            case .executed:
                return NSLocalizedString("task_status_executed", comment: "")
            case .confirmed:
                return NSLocalizedString("task_status_confirmed", comment: "")
            case .approved:
                return NSLocalizedString("task_status_approved", comment: "")
            case .reject:
                return NSLocalizedString("task_status_reject", comment: "")
            }
        }
    }

    enum TaskType: Int, Codable {
        case execute = 10
        case approve = 20

        var name: String {
            switch self {
            case .execute:
                return NSLocalizedString("task_type_execute", comment: "")
            case .approve:
                return NSLocalizedString("task_type_approve", comment: "")
            }
        }

        static func all() -> [TaskType] {
            var items = [TaskType]()
            items.append(.execute)
            items.append(.approve)
            return items
        }
    }

    enum Reminder: Int {
        case fiveMins = 5
        case tenMins = 10
        case fifteenMins = 15
        case thirtyMins = 30
        case oneHour = 60

        var name: String {
            switch self {
            case .fiveMins:
                return NSLocalizedString("five_minutes", comment: "")
            case .tenMins:
                return NSLocalizedString("ten_minutes", comment: "")
            case .fifteenMins:
                return NSLocalizedString("fifteen_minutes", comment: "")
            case .thirtyMins:
                return NSLocalizedString("thirty_minutes", comment: "")
            case .oneHour:
                return NSLocalizedString("one_hour", comment: "")
            }
        }

        static func all() -> [Reminder] {
            var items = [Reminder]()
            items.append(.fiveMins)
            items.append(.tenMins)
            items.append(.fifteenMins)
            items.append(.thirtyMins)
            items.append(.oneHour)
            return items
        }
    }

    var id: String
    var topic: String
    var authorCode: String
    var authorName: String
    var isAllDay: Bool
    var startDate: String?
    var endDate: String?
    var location: String?
    var statusCode: Status
    var isExpired: Bool
    var description: String
    var executorCode: String
    var executorName: String
    var reminder: Int
    var type: TaskType
    var approveEntityId: String
    var approveEntityType: String
    var label: String
    var participants: [Employee]
    var messages: [Message]
    var attachments: [String]
    var actions: [TaskAction]

    // MARK: - Decodable

    enum CodingKeys: String, CodingKey {
        case id
        case topic
        case authorCode
        case authorName
        case isAllDay
        case startDate
        case endDate
        case location
        case statusCode
        case isExpired
        case description
        case executorCode
        case executorName
        case reminder
        case type
        case approveEntityId
        case approveEntityType
        case label
        case participants
        case messages
        case attachments
        case actions
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decodeWrapper(key: .id, defaultValue: UUID().uuidString)
        self.topic = try container.decodeWrapper(key: .topic, defaultValue: "")
        self.authorCode = try container.decodeWrapper(key: .authorCode, defaultValue: "")
        self.authorName = try container.decodeWrapper(key: .authorName, defaultValue: "")
        self.isAllDay = try container.decodeWrapper(key: .isAllDay, defaultValue: false)
        self.startDate = try container.decodeWrapper(key: .startDate, defaultValue: "")
        self.endDate = try container.decodeWrapper(key: .endDate, defaultValue: "")
        self.location = try container.decodeWrapper(key: .location, defaultValue: "")
        self.statusCode = try container.decodeWrapper(key: .statusCode, defaultValue: Status.new)
        self.isExpired = try container.decodeWrapper(key: .isExpired, defaultValue: false)
        self.description = try container.decodeWrapper(key: .description, defaultValue: "")
        self.executorCode = try container.decodeWrapper(key: .executorCode, defaultValue: "")
        self.executorName = try container.decodeWrapper(key: .executorName, defaultValue: "")
        self.reminder = try container.decodeWrapper(key: .reminder, defaultValue: 0)
        self.type = try container.decodeWrapper(key: .type, defaultValue: TaskType.execute)
        self.approveEntityId = try container.decodeWrapper(key: .approveEntityId, defaultValue: "")
        self.approveEntityType = try container.decodeWrapper(key: .approveEntityType, defaultValue: "")
        self.label = try container.decodeWrapper(key: .label, defaultValue: "")
        self.participants = try container.decodeWrapper(key: .participants, defaultValue: [])
        self.messages = try container.decodeWrapper(key: .messages, defaultValue: [])
        self.attachments = try container.decodeWrapper(key: .attachments, defaultValue: [])
        self.actions = try container.decodeWrapper(key: .actions, defaultValue: [])
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(id, forKey: "id")
        aCoder.encode(topic, forKey: "topic")
        aCoder.encode(authorCode, forKey: "authorCode")
        aCoder.encode(authorName, forKey: "authorName")
        aCoder.encode(isAllDay, forKey: "isAllDay")
        aCoder.encode(startDate, forKey: "startDate")
        aCoder.encode(endDate, forKey: "endDate")
        aCoder.encode(location, forKey: "location")
        aCoder.encode(statusCode, forKey: "statusCode")
        aCoder.encode(isExpired, forKey: "isExpired")
        aCoder.encode(description, forKey: "description")
        aCoder.encode(executorCode, forKey: "executorCode")
        aCoder.encode(executorName, forKey: "executorName")
        aCoder.encode(reminder, forKey: "reminder")
        aCoder.encode(type, forKey: "type")
        aCoder.encode(approveEntityId, forKey: "approveEntityId")
        aCoder.encode(approveEntityType, forKey: "approveEntityType")
        aCoder.encode(label, forKey: "label")
        aCoder.encode(participants, forKey: "participants")
        aCoder.encode(messages, forKey: "messages")
        aCoder.encode(attachments, forKey: "attachments")
        aCoder.encode(actions, forKey: "actions")
    }

    // MARK: - Hashable

    var hashValue: Int {
        return id.hashValue
    }

    static func == (lhs: Task, rhs: Task) -> Bool {
        return lhs.id == rhs.id
    }

}

struct TaskAction: Codable {
    var authorCode: String
    var infoText: String
    var createDate: String
    var authorInitials: String
    var authorName: String

    // MARK: - Decodable

    enum CodingKeys: String, CodingKey {
        case authorCode
        case infoText
        case createDate
        case authorInitials
        case authorName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.authorCode = try container.decodeWrapper(key: .authorCode, defaultValue: UUID().uuidString)
        self.infoText = try container.decodeWrapper(key: .infoText, defaultValue: "")
        self.createDate = try container.decodeWrapper(key: .createDate, defaultValue: "")
        self.authorInitials = try container.decodeWrapper(key: .authorInitials, defaultValue: "")
        self.authorName = try container.decodeWrapper(key: .authorName, defaultValue: "")
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(authorCode, forKey: "authorCode")
        aCoder.encode(infoText, forKey: "infoText")
        aCoder.encode(createDate, forKey: "createDate")
        aCoder.encode(authorInitials, forKey: "authorInitials")
        aCoder.encode(authorName, forKey: "authorName")
    }

}

// MARK: - Persistable

extension Task: Persistable {
    init(managedObject: TaskObject) {
        id = managedObject.id
        topic = managedObject.topic
        authorCode = managedObject.authorCode
        authorName = managedObject.authorName
        isAllDay = managedObject.isAllDay
        startDate = managedObject.startDate
        endDate = managedObject.endDate
        location = managedObject.location
        statusCode = Task.Status(rawValue: managedObject.statusCode) ?? .new
        isExpired = managedObject.isExpired
        description = managedObject.descriptionText
        executorCode = managedObject.executorCode
        executorName = managedObject.executorName
        reminder = managedObject.reminder
        type = Task.TaskType(rawValue: managedObject.type) ?? .execute
        approveEntityId = managedObject.approveEntityId
        approveEntityType = managedObject.approveEntityType
        label = managedObject.label
        participants = managedObject.participants.map { Employee(managedObject: $0) }
        messages = managedObject.messages.map { Message(managedObject: $0) }
        attachments = managedObject.attachments.map { $0 }
        actions = managedObject.actions.map { TaskAction(managedObject: $0) }
    }

    func managedObject() -> TaskObject {
        let object = TaskObject()
        object.authorCode = authorCode
        object.id = id
        object.topic = topic
        object.authorCode = authorCode
        object.authorName = authorName
        object.isAllDay = isAllDay
        object.startDate = startDate
        object.endDate = endDate
        object.location = location
        object.statusCode = statusCode.rawValue
        object.isExpired = isExpired
        object.descriptionText = description
        object.executorCode = executorCode
        object.executorName = executorName
        object.reminder = reminder
        object.type = type.rawValue
        object.approveEntityId = approveEntityId
        object.approveEntityType = approveEntityType
        object.label = label
        object.participants.append(objectsIn: participants.map { $0.managedObject() })
        object.messages.append(objectsIn: messages.map { $0.managedObject() })
        object.attachments.append(objectsIn: attachments)
        object.actions.append(objectsIn: actions.map { $0.managedObject() })
        return object
    }
}

extension TaskAction: Persistable {
    init(managedObject: TaskActionObject) {
        authorCode = managedObject.authorCode
        infoText = managedObject.infoText
        createDate = managedObject.createDate
        authorInitials = managedObject.authorInitials
        authorName = managedObject.authorName
    }

    func managedObject() -> TaskActionObject {
        let object = TaskActionObject()
        object.authorCode = authorCode
        object.infoText = infoText
        object.createDate = createDate
        object.authorInitials = authorInitials
        object.authorName = authorName
        return object
    }
}
