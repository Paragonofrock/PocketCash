//
//  DataBaseService.swift
//  PocketCash
//
//  Created by User on 11.12.17.
//  Copyright © 2017 Bimbetov Farabi. All rights reserved.
//

import UIKit
import GRDB

class DataBaseService: NSObject {
   
    static let sharedInstance = DataBaseService()
    var dbQueue: DatabaseQueue?
    
    override init() {
        do {
            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let pathToDatabaseFile = "\(documentsPath)/database.sqlite"
            self.dbQueue = try DatabaseQueue(path: pathToDatabaseFile)
            try self.dbQueue?.inDatabase { db in
                try db.execute(
                    "CREATE TABLE IF NOT EXISTS pocketCash (" +
                        "id INTEGER PRIMARY KEY, " +
                        "cash INTEGER NOT NULL, " +
                        "date DATETIME NOT NULL, " +
                        "comment TEXT NOT NULL, " +
                        "income BOOLEAN NOT NULL, " +
                        "category TEXT NOT NULL)")
            }
        } catch {
            NSLog("Failed to create database")
        }
    }
    
    func getCashOperation(fromRow row: Row) -> CashOperation {
        let id: Int = row["id"]
        let cash: Int = row["cash"]
        let date: Date = row["date"]
        let comment: String = row["comment"]
        let income: Bool = row["income"]
        let category: String = row["category"]
        
        return CashOperation(id: id, cash: cash, date: date, comment: comment, income: income, category: category)
    }
    
    func checkExistingDB() -> Bool {
        var isUsed = false
        do {
            try self.dbQueue?.inDatabase { db in
                let exist = try Int.fetchOne(db, "SELECT COUNT(*) FROM cash")!
                isUsed = exist != 0
            }
        } catch {
            NSLog("Failed to insert new ticket to datebase.")
            NSLog("Error: unknown error")
        }
        return isUsed
    }
    
    func insertCashOperation(cashOperation: CashOperation) {
        var newCashOperation = cashOperation
        do {
            try self.dbQueue?.inDatabase { db in
                try db.execute(
                        "INSERT INTO pocketCash (cash, date, comment, income, category) " +
                        "VALUES (?, ?, ?, ?, ?, ?)",
                        arguments: [cashOperation.cash, cashOperation.date, cashOperation.comment, cashOperation.income, cashOperation.category])
                    NSLog("CashOperation with id \(cashOperation.id) was inserted")
            }
        } catch let error as DatabaseError {
            NSLog("Failed to insert new cashOperation to datebase.")
            NSLog("Error: \(String(describing: error.message))")
            NSLog("Request: \(String(describing: error.sql))")
        } catch {
            NSLog("Failed to insert new cashOperation to datebase.")
            NSLog("Error: unknown error")
        }
    }
    
    func deleteAllCashOperation() {
        do {
            try self.dbQueue?.inDatabase { db in
                let deleteAllCashOperation = try String.fetchAll(db, "DELETE FROM pocketCash")
                print("DeleteCashOperation = \(deleteAllCashOperation)")
            }
        } catch let error as DatabaseError {
            NSLog("Failed to delete all elements from datebase")
            NSLog("Error: \(String(describing: error.message))")
            NSLog("Request: \(String(describing: error.sql))")
        } catch {
            NSLog("Failed to delete all elements from datebase")
            NSLog("Error: unknown error")
        }
    }
    
    func readCashOperation() -> [CashOperation] {
        var cashOperations: [CashOperation] = []
        do {
            try self.dbQueue?.inDatabase { db in
                let rows = try Row.fetchCursor(db, "SELECT * FROM pocketCash")
                while let row = try rows.next() {
                    let cashOperation = self.getCashOperation(fromRow: row)
                    cashOperations.append(cashOperation)
                }
            }
        } catch {
            NSLog("Failed to read from database")
        }
        return cashOperations
    }
}