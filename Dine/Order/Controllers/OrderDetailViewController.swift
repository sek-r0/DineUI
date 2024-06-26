//
//  OrderDetailViewController.swift
//  Dine
//
//  Created by doss-zstch1212 on 14/06/24.
//

import UIKit
import SwiftUI
import Toast

class OrderDetailViewController: UIViewController {
    
    private let order: Order // Injection
    private let cellReuseIdentifier = "menuItem" // Reuse identifier for table view cells
    
    private var tableView: UITableView!
    private var scrollView: UIScrollView!
    /// View to hold the scrollable content
    private var contentView: UIView!
    
    private var billButton: UIButton!
    private var editButton: UIButton!
    
    private lazy var verticalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.layer.cornerRadius = 12
        stackView.layer.masksToBounds = true
        stackView.backgroundColor = .app
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    private lazy var horizontalButtonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private var unorderedItems: [MenuItem] = []
    private var orderedItems: [MenuItem: Int] = [:]
    private var menuItems: [MenuItem] = []
    
    init(order: Order) {
        self.order = order
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .secondarySystemBackground
        title = "Order"
        navigationController?.navigationBar.prefersLargeTitles = true
        setupScrollView()
        populateMenuModelData()
        populateOrderedItems()
        populateMenuItems()
        setupTableView()
        setupVerticalStackView()
        setupButtonStackView()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(cartDidChange(_:)),
            name: .cartDidChangeNotification,
            object: nil
        )
    }
    
    @objc private func cartDidChange(_ sender: Notification) {
        if let userInfo = sender.userInfo,
           let updatedCart = userInfo["MenuItems"] as? [MenuItem: Int] {
            orderedItems.removeAll()
            menuItems.removeAll()
            orderedItems = updatedCart
            populateMenuItems()
            tableView.reloadData()
        }
    }
    
    private func populateOrderedItems() {
        for item in unorderedItems {
            if let count = orderedItems[item] {
                orderedItems[item] = count + 1
            } else {
                orderedItems[item] = 1
            }
        }
    }
    
    private func populateMenuItems() {
        for (item, count) in orderedItems {
            if count > 0 {
                let menuitem = item
                menuitem.count = count
                menuItems.append(menuitem)
            }
        }
    }
    
    private func populateMenuModelData() {
        unorderedItems = order.menuItems
    }
    
    private func setupNavbar() {
        // TODO: Setup edit buttons
    }
    
    private func setupBillButton() {
        billButton = UIButton()
        contentView.addSubview(billButton)
        billButton.setTitle("Bill", for: .normal)
        billButton.setTitleColor(.black, for: .normal)
        billButton.backgroundColor = .app
        billButton.layer.cornerRadius = 12
        billButton.translatesAutoresizingMaskIntoConstraints = false
        billButton.addTarget(self, action: #selector(billButtonAction(_ :)), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            billButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            billButton.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.88),
            billButton.topAnchor.constraint(equalTo: verticalStackView.bottomAnchor, constant: 20),
            billButton.heightAnchor.constraint(equalToConstant: 55)
        ])
    }
    
    private func setupScrollView() {
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        // Set up constraints for the UIScrollView to match the view's size
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Setup content view
        contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Due to referring to tableView and stackView before initializing, the app crashes!
        /*let totalSubviewHeight: CGFloat = tableView.frame.height + cardStackView.frame.height
        var contentViewHeight: CGFloat = view.frame.height
        
        if totalSubviewHeight > contentViewHeight {
            contentViewHeight = view.frame.height + totalSubviewHeight + 100 // 100 is the extra offset ignoring the spacing between the subviews.
        }*/
        
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            
            // Set the width and height constraints for the content view
            // These constraints define the scrollable area
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            contentView.heightAnchor.constraint(equalToConstant: 1000) // Set a height to make the content scrollable
        ])
    }
    
    private func setupTableView() {
        tableView = DynamicTableView()
        tableView.layoutIfNeeded()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.layer.cornerRadius = 12
        tableView.translatesAutoresizingMaskIntoConstraints = false
        //view.addSubview(tableView)
        contentView.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor),
            tableView.centerXAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.centerXAnchor),
            tableView.widthAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.widthAnchor, multiplier: 0.88),
        ])
    }
    
    private func setupVerticalStackView() {
        let tableIDView = TitleAndDescriptionView()
        let orderIDView = TitleAndDescriptionView()
        let statusView = TitleAndDescriptionView()
        let dateView = TitleAndDescriptionView()
        dateView.configureView(title: "Date", description: order.getDate.formatted())
        statusView.configureView(title: "Status", description: order.orderStatusValue.rawValue.uppercased())
        tableIDView.configureView(title: "Table", description: order.tableIDValue.uuidString)
        orderIDView.configureView(title: "Order", description: order.orderIdValue.uuidString)
        //view.addSubview(cardStackView)
        contentView.addSubview(verticalStackView)
        verticalStackView.addArrangedSubview(orderIDView)
        verticalStackView.addArrangedSubview(tableIDView)
        verticalStackView.addArrangedSubview(statusView)
        verticalStackView.addArrangedSubview(dateView)
        
        NSLayoutConstraint.activate([
            verticalStackView.centerXAnchor.constraint(equalTo: contentView/*.safeAreaLayoutGuide*/.centerXAnchor),
            verticalStackView.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 20),
            verticalStackView.widthAnchor.constraint(equalTo: contentView/*.safeAreaLayoutGuide*/.widthAnchor, multiplier: 0.88),
            verticalStackView.heightAnchor.constraint(equalToConstant: 300)
        ])
    }
    
    private func setupButtonStackView() {
        billButton = UIButton()
        billButton.setTitle("Bill", for: .normal)
        billButton.setTitleColor(.systemBackground, for: .normal)
        // billButton.setTitleColor(.lightGray, for: .disabled)
        billButton.backgroundColor = .label
        billButton.layer.cornerRadius = 12
        billButton.translatesAutoresizingMaskIntoConstraints = false
        billButton.addTarget(self, action: #selector(billButtonAction(_ :)), for: .touchUpInside)
        
        editButton = UIButton()
        editButton.setTitle("Edit", for: .normal)
        editButton.setTitleColor(.systemBackground, for: .normal)
        editButton.backgroundColor = .label
        editButton.layer.cornerRadius = 12
        editButton.translatesAutoresizingMaskIntoConstraints = false
        editButton.addTarget(self, action: #selector(editButtonAction(_ :)), for: .touchUpInside)

        contentView.addSubview(horizontalButtonStackView)
        horizontalButtonStackView.addArrangedSubview(editButton)
        horizontalButtonStackView.addArrangedSubview(billButton)
        
        NSLayoutConstraint.activate([
            horizontalButtonStackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            horizontalButtonStackView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.88),
            horizontalButtonStackView.topAnchor.constraint(equalTo: verticalStackView.bottomAnchor, constant: 20),
            horizontalButtonStackView.heightAnchor.constraint(equalToConstant: 55)
        ])
    }
    
    @objc private func billButtonAction(_ sender: UIButton) {
        print(#function)
        guard !menuItems.isEmpty else {
            presentEmptyCartAlert(on: self)
            return
        }
        billOrder()
    }
    
    private func billOrder() {
        do {
            let databaseAccess = try SQLiteDataAccess.openDatabase()
            let orderService = OrderServiceImpl(databaseAccess: databaseAccess)
            let billService = BillServiceImpl(databaseAccess: databaseAccess)
            let billingController = BillingController(billService: billService, orderService: orderService)
            
            try billingController.createBill(for: order, tip: 0.0)
            
            // Notify the observers
            NotificationCenter.default.post(name: .billDidChangeNotification, object: nil)
            NotificationCenter.default.post(name: .orderDidChangeNotification, object: nil)
            NotificationCenter.default.post(name: .metricDataDidChangeNotification, object: nil)
            
            // Disable bill button
            // billButton.isEnabled = false
            
            // Hidden the `horizontalStackView`
            horizontalButtonStackView.isHidden = true
            
            // Pop the detail view
            navigationController?.popViewController(animated: true)
            
            let toast = Toast.default(image: UIImage(systemName: "checkmark.circle.fill")!, title: "New Bill Added")
            toast.show(haptic: .success)
        } catch {
            print("Unable to bill the order - \(error)")
        }
    }
    
    @objc private func editButtonAction(_ sender: UIButton) {
        print(#function)
        
        for item in order.menuItems {
            item.count = orderedItems[item] ?? 0
        }
        
        let editCartViewController = EditCartViewController(cart: orderedItems, order: order)
        self.present(UINavigationController(rootViewController: editCartViewController), animated: true)
    }
    
    func countDuplicates(items: [MenuItem]) -> [MenuItem: Int] {
        var itemCounts: [MenuItem: Int] = [:]
        
        for item in menuItems {
            itemCounts[item, default: 0] += 1
        }
        
        return itemCounts
    }

    // Function to present the alert controller
    // Usage: Assuming 'self' is a UIViewController instance
    // presentEmptyCartAlert(on: self)
    func presentEmptyCartAlert(on viewController: UIViewController) {
        // Create the alert controller
        let alertController = UIAlertController(title: "Empty Cart", message: "Do you want to delete the order?", preferredStyle: .alert)
        
        // Create the 'Delete' action
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self else { return }
            // Handle the delete action
            print("Order deleted")
            self.deleteOrder()
        }
        
        // Create the 'Add Items' action
        let addItemsAction = UIAlertAction(title: "Add Items", style: .default) { [weak self] _ in
            // Handle the add items action
            guard let self else { return }
            print("Adding items to cart")
            for item in order.menuItems {
                item.count = orderedItems[item] ?? 0
            }
            
            let editCartViewController = EditCartViewController(cart: orderedItems, order: order)
            self.present(UINavigationController(rootViewController: editCartViewController), animated: true)
        }
        
        // Add the actions to the alert controller
        alertController.addAction(deleteAction)
        alertController.addAction(addItemsAction)
        
        // Present the alert controller
        viewController.present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - Destructive
    private func deleteOrder() {
        do {
            let orderService = try OrderServiceImpl(databaseAccess: SQLiteDataAccess.openDatabase())
            let tableService = try TableServiceImpl(databaseAccess: SQLiteDataAccess.openDatabase())
            let orderController = OrderController(orderService: orderService, tableService: tableService)
            try orderController.deleteOrder(order)
            
            navigationController?.popViewController(animated: true)
            
            // Notify the changes
            NotificationCenter.default.post(Notification(name: .cartDidChangeNotification))
            
            let toast = Toast.default(image: UIImage(systemName: "checkmark")!, title: "Order Deleted")
            toast.show(haptic: .success)
        } catch {
            fatalError("Failed to perform \(#function) - \(error)!") // Caution
            // print("Failed to perform \(#function) - \(error)!")
        }
    }
}

extension OrderDetailViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        menuItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)
        let menuItem = menuItems[indexPath.row]
        cell.selectionStyle = .none
        cell.backgroundColor = .app
        
        cell.contentConfiguration = UIHostingConfiguration {
            PlainMenuItemView(menuItem: menuItem)
        }
        
        return cell
    }
}

class DynamicTableView: UITableView {
    override func layoutSubviews() {
        super.layoutSubviews()
        if !__CGSizeEqualToSize(bounds.size, self.intrinsicContentSize) {
            self.invalidateIntrinsicContentSize()
        }
    }
    
    override var intrinsicContentSize: CGSize {
        return contentSize
    }
}

#Preview {
    let order = Order(tableId: UUID(), orderStatus: .completed, menuItems: ModelData().menuItems)
    return UINavigationController(rootViewController: OrderDetailViewController(order: order))
}
