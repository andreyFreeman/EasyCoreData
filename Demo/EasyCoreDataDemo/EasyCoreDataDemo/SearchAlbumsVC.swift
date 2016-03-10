//
//  SearchAlbumsVC.swift
//  EasyCoreDataDemo
//
//  Created by Andrey Kladov on 01/05/15.
//  Copyright (c) 2015 Andrey Kladov. All rights reserved.
//

import UIKit

class SearchAlbumsVC: UITableViewController {
	
	private struct Consts {
		static let tableViewCell = "albumCell"
	}
	
	var searchTerm = ""
	var items: [Album]?
	
	private let dateFormatter: NSDateFormatter = {
		let formatter = NSDateFormatter()
		formatter.dateFormat = "dd MMMM yyyy"
		return formatter
	}()
	
	// MARK: - Table view data source
	
	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch items?.count {
		case .Some(let count): return count
		default: return 0
		}
	}
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier(Consts.tableViewCell, forIndexPath: indexPath)
		let item = items?[indexPath.row]
		(cell.contentView.viewWithTag(101) as? UILabel)?.text = item?.artist
		(cell.contentView.viewWithTag(102) as? UILabel)?.text = item?.title
		(cell.contentView.viewWithTag(103) as? UILabel)?.text = item?.genre
		(cell.contentView.viewWithTag(106) as? UILabel)?.text = NSLocalizedString("Tracks:", comment: "")+" "+{
			if let count = item?.trackCount {
				return "\(count)"
			}
			return "-"
		}()
		(cell.contentView.viewWithTag(104) as? UILabel)?.text = {
			let value = NSLocalizedString("Released:", comment: "")
			if let date = item?.releaseDate {
				return value+" "+self.dateFormatter.stringFromDate(date)
			}
			return value+" -"
		}()
		if let imageView = cell.contentView.viewWithTag(105) as? UIImageView {
			if let url = item?.artworkUrl100 {
				imageView.sd_setImageWithURL(NSURL(string: url)) { [weak imageView] _ in
                    imageView?.runFade(0.2)
                }
			} else {
				imageView.image = nil
			}
		}
		return cell
	}
	
	// MARK: - Navigation
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		switch segue.identifier {
		case .Some("GoAlbumDetails"):
			if let row = tableView?.indexPathForSelectedRow?.row {
				(segue.destinationViewController as? AlbumDetailsVC)?.album = items?[row]
			}
		default: break
		}
	}
	
}

extension SearchAlbumsVC: UISearchBarDelegate {
	func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
		searchTerm = searchText
        if searchText.characters.count == 0 {
            items = []
            tableView?.reloadData()
            Album.deleteAll()
        }
	}
	func searchBarSearchButtonClicked(searchBar: UISearchBar) {
		searchBar.resignFirstResponder()
		if searchTerm.characters.count > 0 {
			SVProgressHUD.showWithStatus(NSLocalizedString("Searching...", comment: ""), maskType: .Gradient)
			APIController.sharedController.searchAlbumByTrackName(searchTerm, returnObjectOnCompletion: true) { albums, error in
				SVProgressHUD.dismiss()
				if let err = error {
					UIAlertView(title: NSLocalizedString("Oops", comment: ""), message: err.localizedDescription, delegate: nil, cancelButtonTitle: NSLocalizedString("OK", comment: "")).show()
				} else {
					self.items = albums
					self.tableView?.reloadData()
				}
			}
		}
	}
	func searchBarCancelButtonClicked(searchBar: UISearchBar) {
		searchBar.resignFirstResponder()
	}
	func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
		searchBar.setShowsCancelButton(true, animated: true)
	}
	func searchBarTextDidEndEditing(searchBar: UISearchBar) {
		searchBar.setShowsCancelButton(false, animated: true)
	}
}
