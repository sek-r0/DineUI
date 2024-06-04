//
//  OrderViewController.swift
//  Dine
//
//  Created by doss-zstch1212 on 07/05/24.
//

import UIKit
import Toast

class OrderViewController: UIViewController {
    private let orderService: OrderService
    private let menuService: MenuService
    
    private var tableView: UITableView!
    
    // BarButtons
    private var addBarButton: UIBarButtonItem!
    private var quickMenuBarButton: UIBarButtonItem!
    private var doneBarButton: UIBarButtonItem!
    
    private var billButton: UIBarButtonItem!
    private var deleteButton: UIBarButtonItem!
    
    private var orderData: [Order] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    private var selectedOrders: [Order] = [] {
        didSet {
            if !selectedOrders.isEmpty {
                billButton.isEnabled = true
                deleteButton.isEnabled = true
            } else {
                billButton.isEnabled = false
                deleteButton.isEnabled = false
            }
        }
    }
    
    init(orderService: OrderService, menuService: MenuService) {
        self.orderService = orderService
        self.menuService = menuService
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAppearance()
        setupNavigationBar()
        setupTableView()
        view = tableView
        setupToolbar()
        loadOrderData()
        NotificationCenter.default.addObserver(self, selector: #selector(didAddOrder(_:)), name: .didAddNewOrderNotification, object: nil)
    }
    
    private func setSelection(_ editing: Bool, animated: Bool) {
        self.tableView.setEditing(editing, animated: animated)
        
        if tableView.isEditing {
            setRightBarButtons(doneBarButton)
            // Show toolbar in editing state
            setToolbarActive(true)
        } else {
            // Set the default bar buttons
            setRightBarButtons(addBarButton, quickMenuBarButton)
            // Hide the toolbar in non editing state
            setToolbarActive(false)
        }
    }
    
    private func setupToolbar() {
        // Create toolbar items
        billButton = UIBarButtonItem(title: "Bill", style: .plain, target: self, action: #selector(billButtonAction(_:)))
        deleteButton = UIBarButtonItem(title: "Delete", style: .plain, target: self, action: #selector(deleteButtonAction(_:)))
        
        billButton.isEnabled = false
        deleteButton.isEnabled = false

        toolbarItems = [
            billButton,
            UIBarButtonItem(systemItem: .flexibleSpace),
            deleteButton
        ]
    }
    
    private func setToolbarActive(_ isActive: Bool) {
        if isActive {
            navigationController?.setToolbarHidden(false, animated: true)
        } else {
            navigationController?.setToolbarHidden(true, animated: true)
        }
    }
    
    @objc private func billButtonAction(_ sender: UIBarButtonItem) {
        print("Bill orders")
        // Bill the selected orders
        do {
            let databaseAccess = try SQLiteDataAccess.openDatabase()
            let orderService = OrderServiceImpl(databaseAccess: databaseAccess)
            let billService = BillServiceImpl(databaseAccess: databaseAccess)
            let billingController = BillingController(billService: billService, orderService: orderService)
            for order in selectedOrders {
                try billingController.createBill(for: order, tip: nil)
            }
            // Notify BillViewController about changes
            NotificationCenter.default.post(name: .billDidAddNotification, object: nil)
            // Come out of editing mode
            setSelection(false, animated: true)
            // Show toast view
            let toast = Toast.text("Bill Added")
            toast.show(haptic: .success)
        } catch {
            print("Unable to bill the order - \(error)")
        }
        
    }
    
    @objc private func deleteButtonAction(_ sender: UIBarButtonItem) {
        print("Delete orders")
    }
    
    private func setupTableView() {
        tableView = UITableView(frame: .zero)
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(OrderCell.self, forCellReuseIdentifier: OrderCell.reuseIdentifier)
    }
    
    @objc private func didAddOrder(_ sender: NotificationCenter) {
        // Load order and reload table
        loadOrderData()
    }
    
    @objc private func addOrder() {
        let menuListVC = AddToCartViewController()
        let navController = UINavigationController(rootViewController: menuListVC)
        present(navController, animated: true)
    }
    
    private func setupNavigationBar() {
        addBarButton = UIBarButtonItem(image: UIImage(systemName: "plus"), style: .done, target: self, action: #selector(addOrder))
        doneBarButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneBarButtonAction(_:)))
        createMenuBarButton()
        navigationItem.rightBarButtonItems = [addBarButton, quickMenuBarButton]
    }
    
    private func setRightBarButtons(_ barButtons: UIBarButtonItem...) {
        // Remove existing barButton
        navigationItem.rightBarButtonItems?.removeAll()
        for barButton in barButtons {
            navigationItem.rightBarButtonItems?.append(barButton)
        }
    }
    
    private func createMenuBarButton() {
        // Define actions
        let selectAction = UIAction(title: "Select Orders", image: UIImage(systemName: "checkmark.circle")) { [weak self] action in
            guard let self else { return }
            print("Select Order action")
            // Set tableView selection mode
            self.setSelection(true, animated: true)
        }
        // Create menu
        let menu = UIMenu(children: [selectAction])
        quickMenuBarButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), menu: menu)
        
        quickMenuBarButton.menu = menu
    }
    
    @objc private func doneBarButtonAction(_ sender: UIBarButtonItem) {
        // TODO: Bill the selected orders...
        print("Billing orders...")
        selectedOrders.removeAll()
        setSelection(false, animated: true)
    }
    
    @objc private func quickMenuAction(_ sender: UIBarButtonItem) {
        print(#function)
    }
    
    private func loadOrderData() {
        do {
            let dataAccess = try SQLiteDataAccess.openDatabase()
            let orderService = OrderServiceImpl(databaseAccess: dataAccess)
            let results = try orderService.fetch()
            if let results {
                orderData = results
            }
        } catch {
            print("Unable to load orders - \(error)")
        }
    }
    
    private func setupAppearance() {
        self.title = "Orders"
        view.backgroundColor = /*UIColor(named: "primaryBgColor")*/.systemBackground
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
}

extension OrderViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let order = orderData[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(withIdentifier: OrderCell.reuseIdentifier, for: indexPath) as? OrderCell else { return UITableViewCell() }
        cell.configureCell(with: order)
        cell.backgroundColor = /*UIColor(named: "primaryBgColor")*/.systemBackground
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        orderData.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        75
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            let selectedOrder = orderData[indexPath.row]
            selectedOrders.append(selectedOrder)
            
            for order in selectedOrders {
                print(order.orderIdValue)
            }
            print("-----------------------------------")
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            let selectedOrder = orderData[indexPath.row]
            if let selectedOrderIndex = selectedOrders.firstIndex(where: { $0.orderIdValue == selectedOrder.orderIdValue}) {
                selectedOrders.remove(at: selectedOrderIndex)
            }
            
            for order in selectedOrders {
                print(order.orderIdValue)
            }
            
            print("---------------")
        }
     }
}