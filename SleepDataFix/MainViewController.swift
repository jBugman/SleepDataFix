//
//  ViewController.swift
//  SleepDataFix
//
//  Created by Sergey Parshukov on 05.03.16.
//  Copyright © 2016 Sergey Parshukov.
//

import UIKit
import HealthKit

class MainViewController: UIViewController, UITableViewDataSource {

    @IBOutlet var table: UITableView!

    let sleepType = HKObjectType.categoryTypeForIdentifier(HKCategoryTypeIdentifierSleepAnalysis)!
    let dateFormatter = nsDateFormatter("dd.MM.yyyy")
    let timeFormatter = nsDateFormatter("HH:mm")

    var healthKitStore: HKHealthStore!
    var entries = [Entry]()

    override func viewDidLoad() {
        if !HKHealthStore.isHealthDataAvailable() {
            // TODO: handle this
            return
        }
        healthKitStore = HKHealthStore()

        let types = Set(arrayLiteral: sleepType)
        healthKitStore.requestAuthorizationToShareTypes(types, readTypes: types) { (ok, error) -> Void in
            print(ok)
        }
    }

    @IBAction func updatePressed() {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: sleepType,
            predicate: nil,
            limit: Int(HKObjectQueryNoLimit),
            sortDescriptors: [sortDescriptor]) { (query, results, error) -> Void in
                if error != nil {
                    // TODO: handle this
                    return
                }

                self.entries.removeAll()
                results?.forEach({ (item) -> () in
                    let sample = item as! HKCategorySample
                    if sample.value == HKCategoryValueSleepAnalysis.InBed.rawValue {
                        let entry = Entry(sample: sample)
                        self.entries.append(entry)
                    }
                })
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.table.reloadData()
                })
            }
        healthKitStore?.executeQuery(query)
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
