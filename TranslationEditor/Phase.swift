//
//  Phase.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 30.1.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

enum PhaseType: Int
{
	case translation = 1
	case review = 2
	case unsPrep = 3
	case uns = 4
}

// Phases represent different tasks / phases in translation project workflow
final class Phase: Storable
{
	// ATTRIBUTES	----------------
	
	static let PROPERTY_PROJECT = "project"
	
	static let type = "phase"
	
	let projectId: String
	let uid: String
	
	var name: String
	var phaseType: PhaseType
	var templateCarouselId: String
	
	
	// COMPUTED PROPERTIES	--------
	
	static var idIndexMap: [String : IdIndex]
	{
		let projectIndexMap = Project.idIndexMap
		let projectIndex = IdIndex.of(indexMap: projectIndexMap)
		
		return projectIndexMap + [PROPERTY_PROJECT: projectIndex, "phase_uid": projectIndex + 2]
	}
	
	var idProperties: [Any] { return [projectId, "phase", uid] }
	
	var properties: [String : PropertyValue]
	{
		return ["name": PropertyValue(name), "phase_type": PropertyValue(phaseType.rawValue), "template_carousel": PropertyValue(templateCarouselId)]
	}
	
	
	// INIT	------------------------
	
	init(projectId: String, name: String, phaseType: PhaseType, templateCarouselId: String, uid: String = UUID().uuidString.lowercased())
	{
		self.projectId = projectId
		self.name = name
		self.phaseType = phaseType
		self.templateCarouselId = templateCarouselId
		self.uid = uid
	}
	
	static func create(from properties: PropertySet, withId id: Id) -> Phase
	{
		return Phase(projectId: id[PROPERTY_PROJECT].string(), name: properties["name"].string(), phaseType: PhaseType(rawValue: properties["phase_type"].int()).or(.translation), templateCarouselId: properties["template_carousel"].string(), uid: id["phase_uid"].string())
	}
	
	
	// IMPLEMENTED METHODS	-------
	
	func update(with properties: PropertySet)
	{
		if let name = properties["name"].string
		{
			self.name = name
		}
		if let rawType = properties["phase_type"].int, let phaseType = PhaseType(rawValue: rawType)
		{
			self.phaseType = phaseType
		}
		if let templateCarouselId = properties["template_carousel"].string
		{
			self.templateCarouselId = templateCarouselId
		}
	}
}
