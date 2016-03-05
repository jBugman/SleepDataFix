//
//  ViewController.swift
//  SleepDataFix
//
//  Created by Sergey Parshukov on 05.03.16.
//  Copyright © 2016 Sergey Parshukov.
//

import UIKit

class MainViewController: UIViewController, UITableViewDataSource {

    @IBOutlet var table: UITableView!

    var things = [String]()

    @IBAction func updatePressed() {
        print("Update")

        let formatter = NSDateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm:ss"

        let now = NSDate()
        let item = formatter.stringFromDate(now)
        self.things.insert(item, atIndex: 0)

        self.table.reloadData()
    }


    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.things.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("TimeCell")!
        let textForRow = self.things[indexPath.row]
        cell.textLabel?.text = textForRow
        return cell
    }
}
