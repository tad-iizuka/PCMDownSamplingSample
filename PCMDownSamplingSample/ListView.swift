//
//  ListView.swift
//  vTXT
//
//  Created by Tadashi on 2017/02/23.
//  Copyright © 2017 T@d. All rights reserved.
//

import UIKit

class ListView: UIViewController, UITableViewDelegate, UITableViewDataSource {

	var fileList : [String] = []
	var delegate : ViewController!

	@IBOutlet var tableView: UITableView!

	@IBAction func shareItem(_ sender: Any) {
		let button = sender as! UIButton
	
		let cell = button.superview?.superview
		let indexPath = self.tableView.indexPath(for: cell as! UITableViewCell)
		let file = self.fileList[(indexPath?.row)!]
		let dir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! as String
		let items = [URL(fileURLWithPath: dir.appending("/" + file)), nil]
		print(items)
		DispatchQueue.main.async {
			let activityView = UIActivityViewController.init(activityItems: items, applicationActivities: nil)
			activityView.excludedActivityTypes = [
										UIActivityType.postToTwitter,
										UIActivityType.postToWeibo,
										UIActivityType.saveToCameraRoll,
										UIActivityType.addToReadingList,
										UIActivityType.postToFlickr,
										UIActivityType.postToVimeo,
										UIActivityType.postToTencentWeibo,
										UIActivityType.airDrop]
			self.present(activityView, animated: true, completion: nil)
		}
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		self.tableView.tableFooterView = UIView.init()
		self.navigationItem.rightBarButtonItem = editButtonItem
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.createLists()
	}
    
	func numberOfSections(in tableView: UITableView) -> Int {
		return	1
	}

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return	self.fileList.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ListCell
		let file = self.fileList[indexPath.row]
		cell.label.text = file
		return cell
	}

	func tableView(_ tableView: UITableView,didSelectRowAt indexPath: IndexPath) {
		self.tableView.deselectRow(at: indexPath, animated: true)
		let file = self.fileList[indexPath.row]
		let dir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! as String
		let path = dir.appending("/" + file)
		DispatchQueue.main.async {
			self.delegate.filePath = path
			self.delegate.playerPlay()
		}
		_ = self.navigationController?.popViewController(animated: true)
	}

	override func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
		self.tableView.setEditing(editing, animated: animated)
	}

	func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {

		let file = self.fileList[indexPath.row]
		let dir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! as String
		DispatchQueue.main.async {
			let path = dir.appending("/" + file)
			let manager = FileManager.default
			if manager.fileExists(atPath: path) {
				try! manager.removeItem(atPath: path)
				self.createLists()
				self.tableView.reloadData()
			}
		}
	}

	func createLists() {

		self.fileList = []
		let dir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! as String
		let files : [String] = try! FileManager.default.contentsOfDirectory(atPath: dir)
		self.fileList = files.sorted { $0 > $1 }
		DispatchQueue.main.async {
			self.tableView.reloadData()
		}
	}
}
