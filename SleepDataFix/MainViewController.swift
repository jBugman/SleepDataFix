//
//  ViewController.swift
//  SleepDataFix
//
//  Created by Sergey Parshukov on 05.03.16.
//  Copyright © 2016 Sergey Parshukov.
//

import UIKit
import HealthKit

class MainViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet var table: UITableView!
    @IBOutlet var fixButton: UIBarButtonItem!
    @IBOutlet var okView: UIView!

    let sleepType = HKObjectType.categoryTypeForIdentifier(HKCategoryTypeIdentifierSleepAnalysis)!
    let dateFormatter = nsDateFormatter("dd.MM.yyyy")
    let timeFormatter = nsDateFormatter("HH:mm")

    var healthKitStore: HKHealthStore!
    var entries = [Entry]()
    var selectedEntry: Entry!

    override func viewDidLoad() {
        if !HKHealthStore.isHealthDataAvailable() {
            self.handleHealthKitError()
            return
        }
        self.healthKitStore = HKHealthStore()

        let types = Set(arrayLiteral: sleepType)
        self.healthKitStore.requestAuthorizationToShareTypes(types, readTypes: types) { (ok, error) -> Void in
            if error != nil {
                self.handleHealthKitError()
            }
        }
        self.updatePressed()
    }

    @IBAction func updatePressed() {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: sleepType,
            predicate: nil,
            limit: Int(HKObjectQueryNoLimit),
            sortDescriptors: [sortDescriptor]) { (_, results, error) -> Void in
                if error != nil {
                    self.handleHealthKitError()
                    return
                }

                self.resetTable()
                for item in results! {
                    let sample = item as! HKCategorySample
                    if sample.value != HKCategoryValueSleepAnalysis.InBed.rawValue {
                        continue
                    }
                    // Filtering out entries with corresponding 'Asleep'
                    if !results!.contains({
                        $0 != item &&
                        (($0 as! HKCategorySample).value == HKCategoryValueSleepAnalysis.Asleep.rawValue) &&
                        $0.startDate == sample.startDate &&
                        $0.endDate == sample.endDate
                    }) {
                        let entry = Entry(sample: sample)
                        self.entries.append(entry)
                    }
                }
                self.updateTable()
            }

        self.healthKitStore?.executeQuery(query)
    }

    @IBAction func fixPressed() {
        if self.selectedEntry == nil { // Just in case
            print("No selectedEntry")
            return
        }
        self.fix(self.selectedEntry, shouldCallUpdate: true)
    }

    func resetTable() {
        self.selectedEntry = nil
        self.entries.removeAll()
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.fixButton?.enabled = false
        })
    }

    func updateTable() {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.table.reloadData()
            self.okView.hidden = self.entries.count > 0
        })
    }

    func handleHealthKitError() {
        // Show error screen for now
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.performSegueWithIdentifier("errorSegue", sender: self)
        })
    }

    func showAlert(title: String, message: String) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alertController, animated: true, completion: nil)
        })
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.entries.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("TimeCell")! as UITableViewCell
        let entry = self.entries[indexPath.row]

        let startText = self.timeFormatter.stringFromDate(entry.start)
        let endText = self.timeFormatter.stringFromDate(entry.end)
        cell.textLabel?.text = "\(startText) – \(endText)"
        cell.detailTextLabel?.text = self.dateFormatter.stringFromDate(entry.end)
        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.selectedEntry = self.entries[indexPath.row]
        self.fixButton?.enabled = true
    }

    func fix(entry: Entry, shouldCallUpdate: Bool) {
        let sample = HKCategorySample(
            type: sleepType,
            value: HKCategoryValueSleepAnalysis.Asleep.rawValue,
            startDate: self.selectedEntry.start,
            endDate: self.selectedEntry.end)
        self.selectedEntry = nil
        self.healthKitStore.saveObject(sample) { (ok, error) -> Void in
            if error != nil {
                self.showAlert("Can not save data", message: "Please enable write access in the Health app")
            }
            if shouldCallUpdate {
                self.updatePressed()
            }
        }
    }
}

struct Entry {
    let start: NSDate
    let end: NSDate

    init(sample: HKCategorySample) {
        self.start = sample.startDate
        self.end = sample.endDate
    }
}

func nsDateFormatter(format: String) -> NSDateFormatter {
    let formatter = NSDateFormatter()
    formatter.dateFormat = format
    return formatter
}
