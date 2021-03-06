//
//  MainMenuFlow.swift
//  Life
//
//  Created by Shyngys Kassymov on 15.02.2018.
//  Copyright © 2018 Shyngys Kassymov. All rights reserved.
//

import UIKit
import Material

class MainMenuFlow: Flow {

    private lazy var notificationsViewModel = NotificationsViewModel()
    private lazy var tasksAndRequestsViewModel = TasksAndRequestsViewModel()
    private lazy var stuffViewModel = StuffViewModel()
    private lazy var topQuestionsViewModel = TopQuestionsViewModel()

    var root: Presentable {
        return self.rootViewController
    }

    private let rootViewController: AppToolbarController
    private let viewController: AppTabBarController

    init() {
        viewController = AppTabBarController()

        rootViewController = AppToolbarController(rootViewController: viewController)
        rootViewController.setupToolbarButtons(for: viewController)
        rootViewController.didTapNotifications = { [weak self] in
            self?.viewController.step.accept(AppStep.notifications)
        }
//        rootViewController.didTapProfile = { [weak self] in
//            self?.viewController.step.accept(AppStep.profile)
//        }
        rootViewController.didTapSearch = { [weak self] in
            self?.viewController.step.accept(AppStep.newsSearch)
        }
    }

    func navigate(to step: Step) -> NextFlowItems {
        guard let step = step as? AppStep else { return NextFlowItems.stepNotHandled }

        switch step {
        case .mainMenu:
            return navigationToMainMenuScreen()
        case .notifications:
            return navigationToNotifications()
        case .notificationsDone:
            return navigationFromNotifications()
        case .profile:
            return navigationToProfileScreen()
        case .unauthorized:
            onUnauthorized()
            return .stepNotHandled
        case .login:
            navigateToLogin()
            return .stepNotHandled
        case .newsSearch:
            return navigationToNewsSearch()
        //case .userProfile: return navigationToUserProfileScreen()
        default:
            return NextFlowItems.stepNotHandled
        }
    }

    // MARK: - Navigation

    //swiftlint:disable function_body_length
    private func navigationToMainMenuScreen() -> NextFlowItems {
        let tabBarFlowItem = NextFlowItem(
            nextPresentable: rootViewController,
            nextStepper: viewController
        )

        let biOfficeVC = configuredBIOffice()
        let biOfficeFlow = BIOfficeFlow(
            viewController: biOfficeVC,
            notificationsViewModel: notificationsViewModel,
            tasksAndRequestsViewModel: tasksAndRequestsViewModel,
            employeesViewModel: stuffViewModel.employeesViewModel
        )
        let biOfficeFlowItem = NextFlowItem(
            nextPresentable: biOfficeFlow,
            nextStepper: OneStepper(withSingleStep: AppStep.biOffice)
        )

        let lentaVC = configuredLenta()
        let lentaFlow = LentaFlow(
            viewController: lentaVC,
            notificationsViewModel: notificationsViewModel
        )
        let lentaFlowItem = NextFlowItem(
            nextPresentable: lentaFlow,
            nextStepper: OneStepper(withSingleStep: AppStep.lenta)
        )

        let employeesViewController = configuredStuff()
        let employeesFlow = EmployeesFlow(
            viewController: employeesViewController
        )
        let employeesFlowItem = NextFlowItem(
            nextPresentable: employeesFlow,
            nextStepper: OneStepper(withSingleStep: AppStep.employees)
        )

        let menuVC = configuredMenu()
        let menuFlow = MenuFlow(
            navigationController: rootViewController,
            viewController: menuVC,
            topQuestionsViewModel: topQuestionsViewModel,
            notificationsViewModel: notificationsViewModel
        )
        let menuFlowItem = NextFlowItem(
            nextPresentable: menuFlow,
            nextStepper: OneStepper(withSingleStep: AppStep.menu)
        )

        viewController.viewControllers = [
            biOfficeVC,
            lentaVC,
            employeesViewController,
            menuVC
        ]

        return NextFlowItems.multiple(
            flowItems: [
                tabBarFlowItem,
                biOfficeFlowItem,
                lentaFlowItem,
                employeesFlowItem,
                menuFlowItem
            ]
        )
    }
    //swiftlint:enable function_body_length

    private func onUnauthorized() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        appDelegate.coordinator.coordinate(
            flow: appDelegate.appFlow,
            withStepper: OneStepper(withSingleStep: AppStep.unauthorized)
        )
    }

    private func navigateToLogin() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        appDelegate.coordinator.coordinate(
            flow: appDelegate.appFlow,
            withStepper: OneStepper(withSingleStep: AppStep.login)
        )
    }

    private func navigationToProfileScreen() -> NextFlowItems {
        let vc = ProfileViewController.configuredVC
        let flow = ProfileFlow(viewController: vc)
        rootViewController.pushViewController(vc, animated: true)
        return NextFlowItems.one(flowItem:
            NextFlowItem(
                nextPresentable: flow,
                nextStepper: vc)
        )
    }

    private func navigationToNotifications() -> NextFlowItems {
        let notificationsViewController = NotificationsViewController.instantiate(
            withViewModel: notificationsViewModel
        )
        rootViewController.present(notificationsViewController, animated: true, completion: nil)
        return NextFlowItems.one(flowItem:
            NextFlowItem(
                nextPresentable: notificationsViewController,
                nextStepper: notificationsViewController)
        )
    }

    private func navigationFromNotifications() -> NextFlowItems {
        rootViewController.presentedViewController?.dismiss(animated: true, completion: nil)
        return NextFlowItems.none
    }
    
    // Kanat 
    private func navigationToNewsSearch() -> NextFlowItems {
        let vc = configuredNewsSearch()
//        let nav = UINavigationController(rootViewController: vc)
        rootViewController.pushViewController(vc, animated: true)
//        rootViewController.present(nav, animated: true, completion: nil)
        return NextFlowItems.one(flowItem: NextFlowItem(nextPresentable: vc, nextStepper: vc as! Stepper))
    }
    
//    private func navigationToUserProfileScreen() -> NextFlowItems {
//        let userProfileVC = MyInfoViewControllerTableView()
//        let flow = UserProfileFlow(viewController: userProfileVC)
//        rootViewController.pushViewController(userProfileVC, animated: true)
//        return NextFlowItems.one(flowItem:
//            NextFlowItem(
//                nextPresentable: flow,
//                nextStepper: userProfileVC)
//        )
//    }

    // MARK: - Methods

    private func configuredBIOffice() -> BIOfficeViewController {
        let biOfficeViewModel = BIOfficeViewModel(
            tasksAndRequestsViewModel: tasksAndRequestsViewModel,
            topQuestionsViewModel: topQuestionsViewModel
        )
        let biOfficeVC = BIOfficeViewController(
            viewModel: biOfficeViewModel
        )
        return biOfficeVC
    }

    private func configuredBIBoard() -> BIBoardViewController {
        let biBoardViewModel = BIBoardViewModel(
            stuffViewModel: stuffViewModel,
            topQuestionsViewModel: topQuestionsViewModel
        )

        let biBoardVC = BIBoardViewController(viewModel: biBoardViewModel)
        return biBoardVC
    }

    private func configuredLenta() -> LentaViewController {
        let lentaVC = LentaViewController()
        lentaVC.viewModel = LentaViewModel(stuffViewModel: stuffViewModel)
        return lentaVC
    }

    private func configuredStuff() -> StuffViewController {
        let stuffVC = StuffViewController(stuffViewModel: stuffViewModel)
        return stuffVC
    }

    private func configuredMenu() -> MenuViewController {
        let menuVC = MenuViewController.instantiate(withViewModel: MenuViewModel())
        return menuVC
    }

    private func configuredNewsSearch() -> UIViewController {
        let vc = GlobalSearchViewController()
        return vc
    }

}









