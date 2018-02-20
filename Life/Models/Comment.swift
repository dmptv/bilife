//
//  Comment.swift
//  Life
//
//  Created by Shyngys Kassymov on 19.02.2018.
//  Copyright © 2018 Shyngys Kassymov. All rights reserved.
//

import Foundation

struct Comment: Codable {

    var id: String
    var authorCode: String
    var authorName: String
    var createDate: String
    var text: String
    var likesQuantity: Int
    var dislikesQuantity: Int
    var userVote: Int
    var type: Int

    // MARK: - Decodable

    enum CodingKeys: String, CodingKey {
        case id
        case authorCode
        case authorName
        case createDate
        case text
        case likesQuantity
        case dislikesQuantity
        case userVote
        case type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decodeWrapper(key: .id, defaultValue: UUID().uuidString)
        self.authorCode = try container.decodeWrapper(key: .authorCode, defaultValue: "")
        self.authorName = try container.decodeWrapper(key: .authorName, defaultValue: "")
        self.createDate = try container.decodeWrapper(key: .createDate, defaultValue: "")
        self.text = try container.decodeWrapper(key: .text, defaultValue: "")
        self.likesQuantity = try container.decodeWrapper(key: .likesQuantity, defaultValue: 0)
        self.dislikesQuantity = try container.decodeWrapper(key: .dislikesQuantity, defaultValue: 0)
        self.userVote = try container.decodeWrapper(key: .userVote, defaultValue: 0)
        self.type = try container.decodeWrapper(key: .type, defaultValue: 0)
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(id, forKey: "id")
        aCoder.encode(authorCode, forKey: "authorCode")
        aCoder.encode(authorName, forKey: "authorName")
        aCoder.encode(createDate, forKey: "createDate")
        aCoder.encode(text, forKey: "text")
        aCoder.encode(likesQuantity, forKey: "likesQuantity")
        aCoder.encode(dislikesQuantity, forKey: "dislikesQuantity")
        aCoder.encode(userVote, forKey: "userVote")
        aCoder.encode(type, forKey: "type")
    }

}