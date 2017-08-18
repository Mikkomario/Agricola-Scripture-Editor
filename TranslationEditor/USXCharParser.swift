//
//  USXCharParser.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 7.10.2016.
//  Copyright © 2017 SIL. All rights reserved.
//

import Foundation

// This parser collects character data. Functions properly only within para elements.
// Should be called on the start of a verse element or after the start of a para element
// Returns either to the start of a new verse element or at the end of a para element
class USXCharParser: NSObject, XMLParserDelegate
{
	// ATTRIBUTES	---------
	
	private let returner: XMLParsingReturner
	
	private let charDataPointer: UnsafeMutablePointer<[CharData]>
	
	private var currentText = ""
	private var currentStyle: CharStyle?
	
	
	// INIT	----------
	
	init(caller: XMLParserDelegate, targetData: UnsafeMutablePointer<[CharData]>)
	{
		self.charDataPointer = targetData
		self.returner = XMLParsingReturner(originalDelegate: caller)
	}
	
	
	// XML DELEGATE	-----
	
	func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:])
	{
		switch elementName
		{
			// When a note element is found, returns the parsing to the upper element
		case "verse", "note":
			// When a new verse starts, ends parsing
			closeCurrentChar()
			returner.endParsingOnStartElement(parser: parser, elementName: elementName, namespaceURI: namespaceURI, qualifiedName: qName, attributes: attributeDict)
		case "char":
			// When a new char element starts, closes the previous one and starts a new one
			closeCurrentChar()
			if let newStyleAttribute = attributeDict["style"]
			{
				currentStyle = CharStyle.of(newStyleAttribute)
			}
		default: break
		}
	}
	
	func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?)
	{
		switch elementName
		{
		case "char":
			// When a char element ends it is recorded
			closeCurrentChar()
		case "para", "note":
			// When a containing para or note element ends, quits parsing
			closeCurrentChar()
			returner.endParsingOnEndElement(parser: parser, elementName: elementName, namespaceURI: namespaceURI, qualifiedName: qName)
		default: break
		}
	}
	
	func parser(_ parser: XMLParser, foundCharacters string: String)
	{
		// Whenever text data is found, it is appended to the character data
		currentText.append(string)
	}
	
	
	// OTHER	--------
	
	private func closeCurrentChar()
	{
		if !currentText.isEmpty
		{
			if let lastData = charDataPointer[0].last, lastData.style == currentStyle
			{
				charDataPointer[0][charDataPointer[0].count - 1] = lastData.appended(currentText)
			}
			else
			{
				charDataPointer[0].append(CharData(text: currentText, style: currentStyle))
			}
			
			currentText = ""
			currentStyle = nil
		}
	}
}
