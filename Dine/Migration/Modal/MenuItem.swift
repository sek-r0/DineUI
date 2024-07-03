//
//  MenuItem.swift
//  Dine
//
//  Created by doss-zstch1212 on 04/01/24.
//

import Foundation
import SQLite3

class MenuItem {
    let itemId: UUID
    var name: String
    var price: Double
    var count: Int = 0
    let category: MenuCategory
    let description: String
    
    init(itemId: UUID, name: String, price: Double, category: MenuCategory, description: String) {
        self.itemId = itemId
        self.name = name
        self.price = price
        self.category = category
        self.description = description
    }
    
    convenience init(name: String, price: Double, category: MenuCategory, description: String) {
        self.init(itemId: UUID(), name: name, price: price, category: category, description: description)
    }
}

extension MenuItem: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(itemId)
    }
    
    static func == (lhs: MenuItem, rhs: MenuItem) -> Bool {
        return lhs.itemId == rhs.itemId
    }
}

extension MenuItem: Parsable {}

extension MenuItem: SQLTable {
    static var tableName: String {
        DatabaseTables.menuItem.rawValue
    }
    
    static var createStatement: String {
        """
        CREATE TABLE \(DatabaseTables.menuItem.rawValue) (
            MenuItemID TEXT PRIMARY KEY,
            MenuItemName TEXT NOT NULL,
            Price REAL NOT NULL,
            category_id VARCHAR(32),
            description VARCHAR(255),
            FOREIGN KEY (category_id) REFERENCES \(DatabaseTables.category.rawValue)(id)
        );
        """
    }
}

extension MenuItem: SQLUpdatable {
    var createUpdateStatement: String {
        """
        UPDATE \(DatabaseTables.menuItem.rawValue)
        SET MenuItemID = '\(itemId)', MenuItemName = '\(name)', Price = \(price), category_id = '\(category.id)', description = '\(description)'
        WHERE MenuItemID = '\(itemId)';
        """
    }
}

extension MenuItem: SQLDeletable {
    var createDeleteStatement: String {
        "DELETE FROM \(DatabaseTables.menuItem.rawValue) WHERE MenuItemID = '\(itemId)'"
    }
}

extension MenuItem: SQLInsertable {
    var createInsertStatement: String {
        """
        INSERT INTO \(DatabaseTables.menuItem.rawValue) (MenuItemID, MenuItemName, Price, category_id, description)
        VALUES ('\(itemId)', '\(name)', \(price), '\(category.id)', '\(description)');
        """
    }
}

extension MenuItem: DatabaseParsable {
    static func parseRow(statement: OpaquePointer?) throws -> MenuItem? {
        guard let statement = statement else { return nil }
        guard let itemIdCString = sqlite3_column_text(statement, 0),
              let nameCString = sqlite3_column_text(statement, 1),
              let descriptionCString = sqlite3_column_text(statement, 3),
              let categoryIdCString = sqlite3_column_text(statement, 4),
              let categoryNameCString = sqlite3_column_text(statement, 5) else {
            throw DatabaseError.missingRequiredValue
        }
        
        let name = String(cString: nameCString)
        let price = sqlite3_column_double(statement, 2)
        let categoryName = String(cString: categoryNameCString)
        let description = String(cString: descriptionCString)
        
        guard let itemId = UUID(uuidString: String(cString: itemIdCString)),
              let categoryId = UUID(uuidString: String(cString: categoryIdCString)) else {
            throw DatabaseError.conversionFailed
        }
        
        let category = MenuCategory(
            id: categoryId,
            categoryName: categoryName
        )
        
        let menuItem = MenuItem(itemId: itemId, name: name, price: price, category: category, description: description)
        return menuItem
    }
}



