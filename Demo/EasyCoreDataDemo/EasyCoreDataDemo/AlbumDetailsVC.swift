//
//  AlbumDetailsVC.swift
//  EasyCoreDataDemo
//
//  Created by Andrey Kladov on 02/05/15.
//  Copyright (c) 2015 Andrey Kladov. All rights reserved.
//

import UIKit
import CoreData
import EasyCoreData

class AlbumDetailsVC: UITableViewController {
	
	@IBOutlet weak var coverImageView: UIImageView!
	@IBOutlet weak var artistLabel: UILabel!
	@IBOutlet weak var albumTitleLabel: UILabel!
	@IBOutlet weak var genreLabel: UILabel!
	
	private struct Consts {
		static let tableViewCell = "trackCell"
	}
	
	var album: Album?
	var items: [Track] = []

    override func viewDidLoad() {
        super.viewDidLoad()
		switch (album?.tracks?.count, album?.trackCount, album) {
		case (.Some(let actual), .Some(let expected), .Some(let album)) where actual == Int(expected):
			items = NSManagedObjectContext.mainThreadContext.fetchObjects(Track.self, predicate: NSPredicate(format: "album == %@", album), sortDescriptors: [NSSortDescriptor(key: "sortingOrder", ascending: true)])
		case (_, _, .Some(let album)):
			SVProgressHUD.showWithStatus(NSLocalizedString("Loading songs...", comment: ""), maskType: .Gradient)
			APIController.sharedController.loadSongsForAlbum(album) { [weak self] objects, error in
				SVProgressHUD.dismiss()
				if let err = error {
					UIAlertView(title: NSLocalizedString("Oops", comment: ""), message: err.localizedDescription, delegate: nil, cancelButtonTitle: NSLocalizedString("OK", comment: "")).show()
				} else if let tracks = objects {
					self?.items = tracks
				}
				self?.tableView?.reloadData()
			}
		default: break
		}
    }
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		reloadData()
	}
	
	func reloadData() {
		artistLabel?.text = album?.artist
		albumTitleLabel?.text = album?.title
		genreLabel?.text = album?.genre
		if let url = album?.artworkUrl100 {
			coverImageView?.sd_setImageWithURL(NSURL(string: url)) { [weak self] _ in self?.coverImageView?.runFade(duration: 0.2) }
		} else {
			coverImageView?.image = nil
		}
		tableView?.reloadData()
	}
	
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Consts.tableViewCell, forIndexPath: indexPath) as! UITableViewCell
		let track = items[indexPath.row]
		(cell.contentView.viewWithTag(101) as? UILabel)?.text = "\(track.sortingOrder+1)."
		(cell.contentView.viewWithTag(102) as? UILabel)?.text = track.title
		var secs = Int(track.trackTimeMillis)/1000
		var mins = secs/60
		secs%=60
		let hours = mins/60
		mins%=60
		let twoDigitsFormatted = { (time: Int) -> String in
			return String(format: "%02d", time)
		}
		(cell.contentView.viewWithTag(103) as? UILabel)?.text = {
			if hours > 0 { return "\(hours):" }
			return ""
			}()+"\(twoDigitsFormatted(mins)):\(twoDigitsFormatted(secs))"
        return cell
    }

}
