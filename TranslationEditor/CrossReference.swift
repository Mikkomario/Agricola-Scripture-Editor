//
//  CrossReference.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 8.5.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import Foundation

// Cross references are used for storing cross reference data read from USX documents
struct CrossReference: USXConvertible, JSONConvertible, Equatable
{
	// ATTRIBUTES	-----------------
	
	var caller: String
	var style: CrossReferenceStyle
	var charData: [CharData]
	var originVerseIndex: VerseIndex?
	
	
	// COMPUTED PROPERTIES	---------
	
	// A simple text representation of this cross reference
	var text: String { return "*(\(charData.reduce("", { $0 + $1.text })))" }
	
	var toUSX: String { return "<note caller=\"\(caller)\" style=\"\(style.code)\">\(charData.reduce("", { $0 + $1.toUSX }))</note>" }
	
	var properties: [String : PropertyValue] { return ["style": style.code.value, "caller": caller.value, "content": charData.value, "origin_index": originVerseIndex.value] }
	
	
	// INIT	-------------------------
	
	// Parses a cross reference from a JSON representation
	static func parse(from properties: PropertySet) -> CrossReference
	{
		var verseIndex: VerseIndex?
		if let indexProperties = properties["origin_index"].object
		{
			verseIndex = try? VerseIndex.parse(from: indexProperties)
		}
		
		return CrossReference(caller: properties["caller"].string(), style: CrossReferenceStyle(rawValue: properties["style"].string()) ?? .crossReference, charData: CharData.parseArray(from: properties["content"].array(), using: CharData.parse), originVerseIndex: verseIndex)
	}
	
	
	// OPERATORS	-----------------
	
	static func ==(_ left: CrossReference, _ right: CrossReference) -> Bool
	{
		return left.caller == right.caller && left.style == right.style && left.charData == right.charData && left.originVerseIndex == right.originVerseIndex
	}
}
