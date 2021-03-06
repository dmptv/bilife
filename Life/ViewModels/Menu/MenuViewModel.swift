//
//  MenuViewModel.swift
//  Life
//
//  Created by Shyngys Kassymov on 14.02.2018.
//  Copyright © 2018 Shyngys Kassymov. All rights reserved.
//

import Foundation

struct MenuViewModel: ViewModel {
    var items = [MenuItemViewModel]()
}

extension MenuViewModel: Mockable {
    typealias T = MenuViewModel

    static func sample() -> MenuViewModel {
        var menuViewModel = MenuViewModel()

        let menu1 = MenuItemViewModel(
            title: "Обучение",
            subtitle: "2 новых видео",
            image: ""
        )
        let menu2 = MenuItemViewModel(
            title: "Развитие",
            subtitle: "Просмотрено",
            image: ""
        )
        let menu3 = MenuItemViewModel(
            title: NSLocalizedString("questions", comment: ""),
            subtitle: "Последний вопрос",
            image: ""
        )
        let menu4 = MenuItemViewModel(
            title: "Приложения",
            subtitle: "BI-Group",
            image: ""
        )
        let menu5 = MenuItemViewModel(
            title: NSLocalizedString("log_out", comment: ""),
            subtitle: "",
            image: ""
        )

        menuViewModel.items = [
            menu1,
            menu2,
            menu3,
            menu4,
            menu5
        ]

        return menuViewModel
    }
}

struct MenuItemViewModel: ViewModel {
    var title: String
    var subtitle: String
    var image: String
}
