//
//  CharData.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 29.9.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// Chardata is used for storing text within a verse or another container. Character data may have specific styling associated with it (quotation, special meaning, etc.)
struct CharData: AttributedStringConvertible
{
	// ATTRIBUTES	----
	
	var style: CharStyle?
	var text: String
	
	
	// INIT	----
	
	init(text: String, style: CharStyle? = nil)
	{
		self.text = text
		self.style = style
	}
	
	
	// CONFORMED	---
	
	func toAttributedString(options: [String : Any] = [:]) -> NSAttributedString
	{
		// TODO: At some point one may wish to add other types of attributes based on the style
		let attributes = [CharStyleAttributeName : style]
		return NSAttributedString(string: text, attributes: attributes)
	}
	
	
	// OTHER	------
	
	func appended(_ text: String) -> CharData
	{
		return CharData(text: self.text + text, style: self.style)
	}
	
	static func text(of data: [CharData]) -> String
	{
		var text = ""
		
		for charData in data
		{
			text.append(charData.text)
		}
		
		return text
	}
}
