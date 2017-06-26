//
//  USXImportAlertVC.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 22.6.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit

final class USXImport
{
	// ATTRIBUTES	-----------------
	
	static let instance = USXImport()
	
	fileprivate var parseSuccesses = [BookData]()
	fileprivate var parseFailures = [(fileName: String, message: String)]()
	fileprivate var parsedFileAmount = 0
	
	private var pendingURLs = [URL]()
	
	private weak var viewController: USXImportAlertVC?
	
	
	// INIT	-------------------------
	
	private init() {  } // Singular instance
	
	
	// OTHER METHODS	-------------
	
	func open(url: URL)
	{
		pendingURLs.add(url)
		processPendingURLs()
	}
	
	func processPendingURLs()
	{
		guard !pendingURLs.isEmpty, let projectId = Session.instance.projectId, let avatarId = Session.instance.avatarId else
		{
			return
		}
		
		for url in pendingURLs
		{
			parsedFileAmount += 1
			
			do
			{
				if let parser = XMLParser(contentsOf: url)
				{
					let parsedBooks = try parseUSX(parser: parser, projectId: projectId, avatarId: avatarId).filter { !$0.paragraphs.isEmpty }
					
					if parsedBooks.isEmpty
					{
						parseFailures.add((fileName: url.lastPathComponent, message: "No paragraph data found!"))
					}
					else
					{
						parseSuccesses.append(contentsOf: parsedBooks)
					}
				}
				else
				{
					parseFailures.add((fileName: url.lastPathComponent, message: "Couldn't create xml parser for file"))
				}
			}
			catch
			{
				var message = "Internal Error"
				
				if let error = error as? USXParseError
				{
					switch error
					{
					case .verseIndexNotFound: message = "A verse number is missing"
					case .verseIndexParsingFailed: message = "Verse number parsing failed"
					case .verseRangeParsingFailed: message = "Verse range parsing failed"
					case .chapterIndexNotFound: message = "No chapter marker found"
					case .bookNameNotSpecified: message = "No book name found"
					case .bookCodeNotFound: message = "Book code is missing"
					case .attributeMissing: message = "Required usx-attribute is missing"
					case .unknownNoteStyle: message = "Unrecognized note style"
					}
				}
				
				parseFailures.add((fileName: url.lastPathComponent, message: message))
			}
		}
		
		// Either displays or updates the view controller to show the new data
		if let viewController = viewController, viewController.isBeingPresented
		{
			viewController.update()
		}
		else if let topVC = getTopmostVC()
		{
			topVC.displayAlert(withIdentifier: USXImportAlertVC.identifier, storyBoardId: "Common")
			{
				self.viewController = $0 as? USXImportAlertVC
			}
		}
	}
	
	fileprivate func discardData()
	{
		pendingURLs = []
		parseSuccesses = []
		parseFailures = []
		parsedFileAmount = 0
	}
	
	fileprivate func close()
	{
		discardData()
		viewController?.dismiss(animated: true, completion: nil)
	}
	
	private func parseUSX(parser: XMLParser, projectId: String, avatarId: String) throws -> [BookData]
	{
		// Language is set afterwards
		let usxParserDelegate = USXParser(projectId: projectId, userId: avatarId, languageId: "")
		parser.delegate = usxParserDelegate
		parser.parse()
		
		guard usxParserDelegate.success else
		{
			throw usxParserDelegate.error!
		}
		
		return usxParserDelegate.parsedBooks
	}
	
	private func getTopmostVC() -> UIViewController?
	{
		guard let app = UIApplication.shared.delegate, let rootViewController = app.window??.rootViewController else
		{
			return nil
		}
		
		var currentController = rootViewController
		while let presentedController = currentController.presentedViewController
		{
			currentController = presentedController
		}
		
		return currentController
	}
}

// This view controller is used for parsing and presenting an overview of incoming usx file data
class USXImportAlertVC: UIViewController, UITableViewDataSource, LanguageSelectionHandlerDelegate, FilteredSelectionDataSource, SimpleSingleSelectionViewDelegate
{
	// OUTLETS	---------------------
	
	@IBOutlet weak var fileAmountLabel: UILabel!
	@IBOutlet weak var dataTableView: UITableView!
	@IBOutlet weak var selectLanguageView: SimpleSingleSelectionView!
	@IBOutlet weak var selectNicknameField: SimpleSingleSelectionView!
	@IBOutlet weak var overwriteInfoLabel: UILabel!
	@IBOutlet weak var inputStackView: UIStackView!
	@IBOutlet weak var previewSwitch: UISwitch!
	@IBOutlet weak var okButton: BasicButton!
	@IBOutlet weak var contentView: KeyboardReactiveView!
	@IBOutlet weak var previewSwitchStackView: UIStackView!
	@IBOutlet weak var selectionStackView: UIStackView!
	@IBOutlet weak var contentBottomConstraint: NSLayoutConstraint!
	@IBOutlet weak var contentTopConstraint: NSLayoutConstraint!
	
	
	// ATTRIBUTES	-----------------
	
	static let identifier = "USXImportAlert"
	
	private var existingBooks = [Book]()
	private var existingResources = [ResourceCollection]()
	private var existingNicknames = [String]()
	
	private var languageHandler = LanguageSelectionHandler()
	
	private var selectedNickName: String?
	private var newNickname = ""
	
	
	// COMPUTED PROPERTIES	---------
	
	var numberOfOptions: Int { return existingNicknames.count }
	
	private var containsSuccesses: Bool { return !USXImport.instance.parseSuccesses.isEmpty }
	
	private var containsFailures: Bool { return !USXImport.instance.parseFailures.isEmpty }
	
	private var sectionForSuccess: Int?
	{
		if containsSuccesses
		{
			return containsFailures ? 1 : 0
		}
		else
		{
			return nil
		}
	}
	
	private var sectionForFailure: Int? { return containsFailures ? 0 : nil }
	
	
	// LOAD	-------------------------
	
    override func viewDidLoad()
	{
        super.viewDidLoad()
		
		contentView.configure(mainView: view, elements: [fileAmountLabel, dataTableView, selectLanguageView, selectNicknameField, previewSwitch, okButton], topConstraint: contentTopConstraint, bottomConstraint: contentBottomConstraint, style: .squish, switchedStackViews: [inputStackView])
		
		dataTableView.dataSource = self
		selectLanguageView.datasource = languageHandler
		selectLanguageView.delegate = languageHandler
		selectNicknameField.datasource = self
		selectNicknameField.delegate = self
		
		update()
    }
	
	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)
		
		do
		{
			try languageHandler.updateLanguageOptions()
			selectLanguageView.reloadData()
			
			if let projectId = Session.instance.projectId
			{
				existingBooks = try ProjectBooksView.instance.booksQuery(projectId: projectId).resultObjects()
				existingResources = try ResourceCollectionView.instance.collectionQuery(projectId: projectId).resultObjects()
				updateNickNames()
				
				selectNicknameField.reloadData()
			}
		}
		catch
		{
			print("ERROR: USX Import setup failed. \(error)")
		}
	}
	
	
	// ACTIONS	---------------------
	
	@IBAction func backgroundTapped(_ sender: Any)
	{
		USXImport.instance.close()
	}
	
	@IBAction func cancelButtonPressed(_ sender: Any)
	{
		USXImport.instance.close()
	}
	
	@IBAction func okButtonPressed(_ sender: Any)
	{
		// TODO: Either insert books or go though preview for each
	}
	
	
	// IMPLEMENTED METHODS	---------
	
	func numberOfSections(in tableView: UITableView) -> Int
	{
		if containsFailures
		{
			return containsSuccesses ? 2 : 1
		}
		else
		{
			return containsSuccesses ? 1 : 0
		}
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		if section == sectionForFailure
		{
			return USXImport.instance.parseFailures.count
		}
		else
		{
			return USXImport.instance.parseSuccesses.count
		}
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		if indexPath.section == sectionForFailure
		{
			let cell = tableView.dequeueReusableCell(withIdentifier: ParseFailCell.identifier, for: indexPath) as! ParseFailCell
			let failureData = USXImport.instance.parseFailures[indexPath.row]
			cell.configure(fileName: failureData.fileName, errorDescription: failureData.message)
			return cell
		}
		else
		{
			let cell = tableView.dequeueReusableCell(withIdentifier: ParseSuccessCell.identifier, for: indexPath) as! ParseSuccessCell
			let book = USXImport.instance.parseSuccesses[indexPath.row].book
			cell.configure(code: book.code, identifier: book.identifier, didFindOlderVersion: oldVersion(for: book) != nil)
			return cell
		}
	}
	
	func languageSelectionHandler(_ selectionHandler: LanguageSelectionHandler, newLanguageNameInserted languageName: String)
	{
		updateNickNames()
		updateOKButtonStatus()
	}
	
	func languageSelectionHandler(_ selectionHandler: LanguageSelectionHandler, languageSelected: Language)
	{
		updateNickNames()
		updateOKButtonStatus()
	}
	
	func labelForOption(atIndex index: Int) -> String
	{
		return existingNicknames[index]
	}
	
	func onValueChanged(_ newValue: String, selectedAt index: Int?)
	{
		newNickname = newValue
		selectedNickName = index.map { existingNicknames[$0] }
		updateOKButtonStatus()
		
		overwriteInfoLabel.isHidden = selectedNickName == nil
	}
	
	
	// OTHER METHODS	-------------
	
	fileprivate func update()
	{
		dataTableView.reloadData()
		
		// Sets some elements hidden / visible if successful parsing was done
		let hasSuccesses = !USXImport.instance.parseSuccesses.isEmpty
		selectionStackView.isHidden = !hasSuccesses
		previewSwitchStackView.isHidden = !hasSuccesses
		
		fileAmountLabel.text = "\(USXImport.instance.parsedFileAmount) \(NSLocalizedString("File(s)", comment: "A label presented next to the amount of parsed files in usx import view"))"
		
		updateOKButtonStatus()
	}
	
	private func oldVersion(for book: Book) -> Book?
	{
		return existingBooks.first(where: { $0.code == book.code && $0.identifier == book.identifier })
	}
	
	private func updateNickNames()
	{
		if let selectedLanguageId = languageHandler.selectedLanguage?.idString
		{
			existingNicknames = existingResources.filter { $0.languageId == selectedLanguageId }.map { $0.name }.withoutDuplicates
		}
		else
		{
			existingNicknames = []
		}
		
		selectNicknameField.reloadData()
	}
	
	private func updateOKButtonStatus()
	{
		// For OK-button to be enabled, one must have at least a single successful parse
		// Language and nickname must both be set (non-empty) as well
		okButton.isEnabled = !USXImport.instance.parseSuccesses.isEmpty && !languageHandler.isEmpty && !newNickname.isEmpty
	}
}

/*
fileprivate protocol LanguageSelectionDelegate: class
{
	func existingLanguageSelected(language: Language)
	
	func newLanguageSelected(languageName: String)
}*/