//
//  Views.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 29.11.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// A book view can be used for querying book data from the database
final class BookView: View
{
	// TYPES	------------
	
	typealias Queried = Book
	
	
	// ATTRIBUTES	--------
	
	static let KEY_LANGUAGE = "languageid"
	static let KEY_BOOK_CODE = "code"
	static let KEY_BOOK_IDENTIFIER = "identifier"
	static let keyNames = [KEY_LANGUAGE, KEY_BOOK_CODE, KEY_BOOK_IDENTIFIER]
	
	static let instance = BookView()
	
	let view: CBLView
	
	
	// INIT	----------------
	
	private init()
	{
		view = DATABASE.viewNamed("books")
		view.setMapBlock(createMapBlock
		{
			(book, emit) in
			
			// Key = language id + code + iddentifier
			let key = [book.languageId, book.code, book.identifier]
			emit(key, nil)
			
		}, version: "1")
	}
	
	
	// OTHER METHODS	-----
	
	// Creates a new query for book data. The identifiers should be specified from left to right. If code is specified but language is not, that is considered a programming error.
	func createQuery(languageId: String?, code: String?, identifier: String?) -> CBLQuery
	{
		let keys = [
			BookView.KEY_LANGUAGE : Key(languageId),
			BookView.KEY_BOOK_CODE : Key(code),
			BookView.KEY_BOOK_IDENTIFIER : Key(identifier)
		]
		return createQuery(forKeys: keys)
	}
}
