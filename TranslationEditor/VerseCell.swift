//
//  VerseCell.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 14.2.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit

// Verse cells display translation data targeted by notes threads
class VerseCell: UITableViewCell
{
	// OUTLETS	----------------
	
	@IBOutlet weak var languageNameLabel: UILabel!
	@IBOutlet weak var verseContentTextView: UITextView!
	
	
	// ATTRIBUTES	------------
	
	static let identifier = "VerseCell"
	
	
	// OTHER METHODS	--------

	// Sets up the cell contents
	func configure(languageName: String, textContent: String)
	{
		languageNameLabel.text = languageName
		verseContentTextView.text = textContent
	}
}
