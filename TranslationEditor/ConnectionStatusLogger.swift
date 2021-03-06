//
//  ConnectionStatusLogger.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 10.2.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import Foundation

// This class prints the connection status whenever it changes
class ConnectionStatusLogger: ConnectionListener
{
	func onConnectionStatusChange(newStatus status: ConnectionStatus)
	{
		print("STATUS: Connection status: \(status)")
	}
	
	func onConnectionProgressUpdate(transferred: Int, of total: Int, progress: Double)
	{
		print("STATUS: Transferring \(transferred) / \(total) (\(Int(progress * 100)) %)")
	}
}
