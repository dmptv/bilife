//
//  TasksAndRequestsViewModel.swift
//  Life
//
//  Created by Shyngys Kassymov on 19.02.2018.
//  Copyright © 2018 Shyngys Kassymov. All rights reserved.
//

import Foundation
import DateToolsSwift
import IGListKit
import Moya
import RxSwift
import RxCocoa

class TasksAndRequestsViewModel: NSObject, ViewModel, ListDiffable {
    private(set) var tasks = TasksViewModel()
    private(set) var requests = RequestsViewModel()

    private let disposeBag = DisposeBag()
    let tasksAndRequestsSubject = PublishSubject<[ListDiffable]>()
    private var tasksAndRequestsObservable: Observable<[ListDiffable]>?

    let isLoadingSubject = BehaviorRelay<Bool>(value: false)
    let errorSubject = PublishSubject<Error>()

    var onUnathorizedError: (() -> Void)?

    var minimized = true

    enum SelectedItemsType {
        case inbox, outbox
    }

    var selectedItemsType = SelectedItemsType.inbox

    var items: [ListDiffable] {
        var allItems = [ListDiffable]()
        allItems.append(contentsOf: tasks.tasks as [ListDiffable])
        allItems.append(contentsOf: requests.requests as [ListDiffable])
        return allItems
    }

    var currentItems: [ListDiffable] {
        if selectedItemsType == .outbox {
            return outboxItems
        }
        return inboxItems
    }

    var inboxItems: [ListDiffable] {
        let items = (tasks.inboxTasks as [ListDiffable]) + (requests.inboxRequests as [ListDiffable])
        return items.sorted(by: { (item1, item2) -> Bool in
            var date1 = Date()
            if let item1 = item1 as? RequestViewModel {
                date1 = item1.request.registrationDate.date
            } else if let item1 = item1 as? TaskViewModel {
                date1 = (item1.task.startDate ?? "").date
            }

            var date2 = Date()
            if let item2 = item2 as? RequestViewModel {
                date2 = item2.request.registrationDate.date
            } else if let item2 = item2 as? TaskViewModel {
                date2 = (item2.task.startDate ?? "").date
            }

            return date1.isLater(than: date2)
        })
    }

    var outboxItems: [ListDiffable] {
        let items = (tasks.outboxTasks as [ListDiffable]) + (requests.outboxRequests as [ListDiffable])
        return items.sorted(by: { (item1, item2) -> Bool in
            var date1 = Date()
            if let item1 = item1 as? RequestViewModel {
                date1 = item1.request.registrationDate.date
            } else if let item1 = item1 as? TaskViewModel {
                date1 = (item1.task.startDate ?? "").date
            }

            var date2 = Date()
            if let item2 = item2 as? RequestViewModel {
                date2 = item2.request.registrationDate.date
            } else if let item2 = item2 as? TaskViewModel {
                date2 = (item2.task.startDate ?? "").date
            }

            return date1.isLater(than: date2)
        })
    }

    var inboxCount: Int {
        return tasks.inboxTasks.count + requests.inboxRequests.count
    }

    var outboxCount: Int {
        return tasks.outboxTasks.count + requests.outboxRequests.count
    }

    // MARK: - Bind

    private func bind() {
        let tasksInboxObservable = tasks.inboxTasksSubject.asObservable()
        let tasksOutboxObservable = tasks.outboxTasksSubject.asObservable()
        let requestsInboxObservable = requests.inboxRequestsSubject.asObservable()
        let requestsOutboxObservable = requests.outboxRequestsSubject.asObservable()

        tasksAndRequestsObservable = Observable.zip(
            tasksInboxObservable,
            tasksOutboxObservable,
            requestsInboxObservable,
            requestsOutboxObservable
        ) { (inboxTasks, outboxTasks, inboxRequests, outboxRequests) -> [ListDiffable] in
            var allItems = [ListDiffable]()
            allItems.append(contentsOf: inboxTasks as [ListDiffable])
            allItems.append(contentsOf: outboxTasks as [ListDiffable])
            allItems.append(contentsOf: inboxRequests as [ListDiffable])
            allItems.append(contentsOf: outboxRequests as [ListDiffable])
            return allItems
            }
        tasksAndRequestsObservable?
            .bind { (items) in
                self.isLoadingSubject.accept(false)
                self.tasksAndRequestsSubject.onNext(items)
            }.disposed(by: disposeBag)
    }

    // MARK: - Methods

    public func getAllTasksAndRequests() {
        bind()

        isLoadingSubject.accept(true)

        getAllTasks()
        getAllRequests()
    }

    public func getAllTasks() {
        tasks.getInbox { error in
            guard let error = error else { return }
            self.errorSubject.onNext(error)
        }

        tasks.getOutbox { error in
            guard let error = error else { return }
            self.errorSubject.onNext(error)
        }
    }

    public func getAllRequests() {
        requests.getInbox { error in
            guard let error = error else { return }
            self.errorSubject.onNext(error)
        }

        requests.getOutbox { error in
            guard let error = error else { return }
            self.errorSubject.onNext(error)
        }
    }

    // MARK: - ListDiffable

    func diffIdentifier() -> NSObjectProtocol {
        return self
    }

    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        if let object = object as? TasksAndRequestsViewModel {
            return self == object
        }
        return false
    }
}

extension TasksAndRequestsViewModel: Mockable {
    typealias T = TasksAndRequestsViewModel

    static func sample() -> TasksAndRequestsViewModel {
        let sample = TasksAndRequestsViewModel()

        sample.tasks = TasksViewModel.sample()
        sample.requests = RequestsViewModel.sample()

        return sample
    }
}

extension TasksAndRequestsViewModel: Stepper {
    public func createNewRequest(category: Request.Category, didCreateRequest: @escaping (() -> Void)) {
        self.step.accept(AppStep.createRequest(category: category, didCreateRequest: didCreateRequest))
    }

    public func createNewTask(didCreateTask: @escaping (() -> Void)) {
        self.step.accept(AppStep.createTask(didCreateTask: didCreateTask))
    }
}
