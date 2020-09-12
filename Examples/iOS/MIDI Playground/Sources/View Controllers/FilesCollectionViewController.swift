//
//  FilesCollectionViewController.swift
//  MIDI Playground
//
//  Created by Andrew Madsen on 1/9/18.
//  Copyright © 2018 Mixed In Key. All rights reserved.
//

import UIKit
import MIKMIDI

private let reuseIdentifier = "MIDIFileCell"

class FilesCollectionViewController: UICollectionViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
		
		navigationItem.leftBarButtonItems = [editButtonItem]
    }
	
	@IBAction func createNewFile(_ sender: Any) {
		
		let alert = UIAlertController(title: NSLocalizedString("Enter a Name", comment: "Enter a Name"),
									  message: NSLocalizedString("Enter a name for the new MIDI file", comment: "Enter a name for the new MIDI file"),
									  preferredStyle: .alert)
		alert.addTextField { (textField) in
			textField.placeholder = NSLocalizedString("filename.mid", comment: "filename.mid")
		}
		let createAction = UIAlertAction(title: NSLocalizedString("Create", comment: "Create"), style: .default) { (action) in
			guard let textField = alert.textFields?.first else { return }
			let name = textField.text ?? "Default \(Date())"
			self.createAndOpenNewFile(named: name)
		}
		alert.addAction(createAction)
		let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel)
		alert.addAction(cancelAction)
		
		present(alert, animated: true)
	}
	
	// MARK: Editing
	
	override func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
	}
	
	// MARK: Private
	
	private func createAndOpenNewFile(named name: String) {
		do {
			let file = try self.filesController.createNewFile(named: name)
			open(file: file)
		} catch {
			present(error: error)
		}
	}
	
	private func open(fileAt url: URL) {
		open(file: MIDIFile(fileURL: url))
	}
	
	private func open(file: MIDIFile) {
		loadedSequence = file.midiSequence
		performSegue(withIdentifier: "ReturnToMainView", sender: nil)
	}
	
	private func present(error: Error) {
		let nsError = error as NSError
		
		var message = nsError.localizedDescription
		if let recoverySuggestion = nsError.localizedRecoverySuggestion {
			message += "\n\n"
			message += recoverySuggestion
		}
		let alert = UIAlertController(title: NSLocalizedString("Error", comment: "Error"),
									  message: message,
									  preferredStyle: .alert)
		let action = UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .default)
		alert.addAction(action)
		
		present(alert, animated: true)
	}

	
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "ReturnToMainView" {
			guard let mainVC = segue.destination as? MainViewController else { return }
			mainVC.sequence = loadedSequence
		}
    }
	

    // MARK: UICollectionViewDataSource

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filesController.files.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
		guard let fileCell = cell as? MIDIFileCollectionViewCell else { return cell }
		
		fileCell.midiFile = filesController.files[indexPath.row]
    
        return fileCell
    }

    // MARK: UICollectionViewDelegate

	override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		let file = filesController.files[indexPath.row]
		open(file: file)
	}
	
	// MARK: Properties
	
	let filesController = MIDIFilesController()
	private var loadedSequence: MIKMIDISequence?

}
