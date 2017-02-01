//
//  Book.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 28.11.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// Books contain multiple chapters and paragraphs. A book is limited to a certain 
// Language and project context
final class Book: Storable
{
	// ATTRIBUTES	--------
	
	// The type attribute value for all book instances
	static let type = "book"
	static let PROPERTY_PROJECT = "project"
	static let PROPERTY_CODE = "code"
	
	static let idIndexMap: IdIndexMap = [PROPERTY_PROJECT, PROPERTY_CODE, "book_uid"]
	
	let uid: String
	let code: String
	let projectId: String
	
	var identifier: String
	var languageId: String
	
	
	// COMP. PROPERTIES	----
	
	var idProperties: [Any] {return [projectId, code, uid]}
	
	var properties: [String : PropertyValue]
	{
		return ["identifier" : identifier.value, "language" : languageId.value]
	}
	
	
	// INIT	----------------
	
	init(projectId: String, code: String, identifier: String, languageId: String, uid: String = UUID().uuidString.lowercased())
	{
		self.projectId = projectId
		self.code = code.lowercased()
		self.identifier = identifier
		self.languageId = languageId
		self.uid = uid
		
		// TODO: It would be possible to throw an error for invalid parameters
	}
	
	static func create(from properties: PropertySet, withId id: Id) -> Book
	{
		return Book(projectId: id[PROPERTY_PROJECT].string(), code: id[PROPERTY_CODE].string(), identifier: properties["identifier"].string(), languageId: properties["language"].string(), uid: id["book_uid"].string())
	}
	
	
	// IMPLEMENTED METHODS	----
	
	func update(with properties: PropertySet)
	{
		if let identifier = properties["identifier"].string
		{
			self.identifier = identifier
		}
		if let language = properties["language"].string
		{
			self.languageId = language
		}
	}
	
	
	// OTHER METHODS	--------
	
	// Creates a copy of this book that contains the same paragraph formatting but none of the original content
	// The resulting book data is saved into database as part of this operation
	func makeEmptyCopy(projectId: String, identifier: String, languageId: String, userId: String) throws -> Book
	{
		// Creates the new book instance
		let newBook = Book(projectId: projectId, code: self.code, identifier: identifier, languageId: languageId)
		
		// Finds the existing paragraphs
		let existingParagraphs = try ParagraphView.instance.latestParagraphQuery(bookId: idString).resultObjects()
		
		// Creates a copy of each paragraph with no existing content
		let newParagraphs = existingParagraphs.map { $0.emptyCopy(forBook: newBook.idString, creatorId: userId) }
		
		// Saves the newly generated data into the database
		try DATABASE.tryTransaction
		{
			try newBook.push()
			try newParagraphs.forEach { try $0.push() }
		}
		
		// Creates a binding too
		var bindings = [(String, String)]()
		for i in 0 ..< existingParagraphs.count
		{
			bindings.append((existingParagraphs[i].idString, newParagraphs[i].idString))
		}
		
		let binding = ParagraphBinding(sourceBookId: idString, targetBookId: newBook.idString, bindings: bindings, creatorId: userId)
		// Saves the binding to the database
		try binding.push()
		
		return newBook
	}
	
	// Parses the book code out of a book id string
	static func code(fromId bookIdString: String) -> String
	{
		return createId(from: bookIdString)[PROPERTY_CODE].string()
	}
}
