//
//  EditAvatarVC.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 30.3.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import UIKit

// This view controller is used for editing and creation of new project avatars
class EditAvatarVC: UIViewController
{
	// OUTLETS	------------------
	
	@IBOutlet weak var createAvatarView: CreateAvatarView!
	@IBOutlet weak var errorLabel: UILabel!
	@IBOutlet weak var saveButton: BasicButton!
	@IBOutlet weak var contentView: KeyboardReactiveView!
	@IBOutlet weak var contentTopConstraint: NSLayoutConstraint!
	@IBOutlet weak var contentBottomConstraint: NSLayoutConstraint!
	
	
	// ATTRIBUTES	--------------
	
	static let identifier = "EditAvatar"
	
	private var editedInfo: (Avatar, AvatarInfo)?
	private var completionHandler: ((Avatar, AvatarInfo) -> ())?
	private var presetName: String?
	
	
	// LOAD	----------------------

    override func viewDidLoad()
	{
        super.viewDidLoad()

		errorLabel.text = nil
		
		// If in editing mode, some fields cannot be edited
		if let (avatar, info) = editedInfo
		{
			createAvatarView.avatarImage = info.image
			createAvatarView.avatarName = avatar.name
			createAvatarView.isShared = info.isShared
			
			// Sharing can be enabled / disabled for non-shared accounts only
			// (Shared account avatars have always sharing enabled)
			do
			{
				if let account = try AgricolaAccount.get(avatar.accountId)
				{
					createAvatarView.mustBeShared = account.isShared
				}
			}
			catch
			{
				print("ERROR: Failed to read account data. \(error)")
			}
		}
		// If creating a new avatar, those created for shared accounts must be shared
		else
		{
			if let presetName = presetName
			{
				createAvatarView.avatarName = presetName
			}
			
			do
			{
				guard let accountId = Session.instance.accountId, let account = try AgricolaAccount.get(accountId) else
				{
					print("ERROR: No account selected")
					return
				}
				
				createAvatarView.mustBeShared = account.isShared
			}
			catch
			{
				print("ERROR: Failed to check whether account is shared. \(error)")
			}
		}
		
		createAvatarView.viewController = self
		contentView.configure(mainView: view, elements: [createAvatarView, errorLabel, saveButton], topConstraint: contentTopConstraint, bottomConstraint: contentBottomConstraint, style: .squish)
    }
	
	override func viewDidAppear(_ animated: Bool)
	{
		super.viewDidAppear(animated)
		
		contentView.startKeyboardListening()
	}
	
	override func viewDidDisappear(_ animated: Bool)
	{
		super.viewDidDisappear(animated)
		
		contentView.endKeyboardListening()
	}
	
	
	// ACTIONS	------------------
	
	@IBAction func cancelButtonPressed(_ sender: Any)
	{
		dismiss(animated: true)
	}
	
	@IBAction func backgroundTapped(_ sender: Any)
	{
		dismiss(animated: true)
	}
	
	@IBAction func saveButtonPressed(_ sender: Any)
	{
		// Checks that all necessary fields are filled
		guard createAvatarView.allFieldsFilled else
		{
			errorLabel.text = NSLocalizedString("Please fill in the required fields", comment: "An error message displayed when trying to create new avatar without first filling all required fields")
			return
		}
		
		// Makes sure the passwords match
		guard createAvatarView.passwordsMatch else
		{
			errorLabel.text = NSLocalizedString("The passwords don't match!", comment: "An error message displayed when new avatar password is not repeated correctly")
			return
		}
		
		do
		{
			// Makes the necessary modifications to the avatar
			if let (avatar, info) = editedInfo
			{
				if let newImage = createAvatarView.avatarImage?.scaledToFit(CGSize(width: 320, height: 320)), info.image != newImage
				{
					try info.setImage(newImage)
				}
				
				if let newPassword = createAvatarView.offlinePassword
				{
					info.setPassword(newPassword)
				}
				
				avatar.name = createAvatarView.avatarName
				
				try DATABASE.tryTransaction
				{
					try avatar.push()
					try info.push()
				}
				
				dismiss(animated: true, completion: { self.completionHandler?(avatar, info) })
			}
			// Or creates a new avatar entirely
			else
			{
				guard let accountId = Session.instance.accountId else
				{
					print("ERROR: No account selected")
					return
				}
				
				guard let projectId = Session.instance.projectId, let project = try Project.get(projectId) else
				{
					print("ERROR: No project selected")
					return
				}
				
				let avatarName = createAvatarView.avatarName
				
				// Makes sure there is no avatar with the same name yet
				/*
				guard try Avatar.get(projectId: projectId, avatarName: avatarName) == nil else
				{
					errorLabel.text = "Avatar with the provided name already exists!"
					return
				}*/
				
				// Checks whether admin rights should be given to the new avatar
				// (must be the owner of the project, and the first avatar if account is shared)
				var makeAdmin = false
				if project.ownerId == accountId, let account = try AgricolaAccount.get(accountId)
				{
					if try (!account.isShared || AvatarView.instance.avatarQuery(projectId: projectId, accountId: accountId).firstResultRow() == nil)
					{
						makeAdmin = true
					}
				}
				
				// Creates the new information
				let avatar = Avatar(name: avatarName, projectId: projectId, accountId: accountId, isAdmin: makeAdmin)
				let info = AvatarInfo(avatarId: avatar.idString, password: createAvatarView.offlinePassword, isShared: createAvatarView.isShared)
				
				// Saves the changes to the database (inlcuding image attachment)
				try DATABASE.tryTransaction
				{
					try avatar.push()
					try info.push()
					
					if let image = self.createAvatarView.avatarImage
					{
						try info.setImage(image)
					}
				}
				
				dismiss(animated: true, completion: { self.completionHandler?(avatar, info) })
			}
		}
		catch
		{
			print("ERROR: Failed to perform the required database operations. \(error)")
		}
	}
	
	
	// OTHER METHODS	--------------
	
	func configureForEdit(avatar: Avatar, avatarInfo: AvatarInfo, successHandler: ((Avatar, AvatarInfo) -> ())? = nil)
	{
		self.editedInfo = (avatar, avatarInfo)
		self.completionHandler = successHandler
	}
	
	func configureForCreate(avatarName: String? = nil, successHandler: ((Avatar, AvatarInfo) -> ())? = nil)
	{
		self.presetName = avatarName
		self.completionHandler = successHandler
	}
}
