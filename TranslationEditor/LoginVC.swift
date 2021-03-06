//
//  LoginVC.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 1.3.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import UIKit
import SwitchLanguage
// Login VC handles user authorization and login (duh)
// The process may be skipped / sped up after the first success
// (user data is stored in the keychain)
class LoginVC: UIViewController
{
    // OUTLETS    --------------------
    
    @IBOutlet weak var langselectionseg: UISegmentedControl!
    @IBOutlet weak var userNameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var loginButton: BasicButton!
    @IBOutlet weak var topBar: TopBarUIView!
    @IBOutlet weak var continueButton: BasicButton!
    
    @IBOutlet weak var centeringConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentView: KeyboardReactiveView!
    
    @IBOutlet weak var loginView: UIView!
    @IBOutlet weak var noDataView: UIView!
    @IBOutlet weak var noDataConnectPromptView: ConnectPromptView!
    
    var selectedLang = "en"
    let defaults = UserDefaults.standard
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
//        defaults.set(selectedLang, forKey: "SelectedLang")
//        let value = UIInterfaceOrientation.landscapeLeft.rawValue
//        UIDevice.current.setValue(value, forKey: "orientation")
        selectedLang = Language.getCurrentLanguage()
        print(selectedLang)
        topBar.configure(hostVC: self, title: "Login".localized() )
        topBar.connectionCompletionHandler = handleConnectionChange
        errorLabel.text = nil
        // errorLabel.isHidden = true
        //        loginView.isHidden = true
        //        noDataView.isHidden = true
        
//        contentView.configure(mainView: view, elements: [userNameField, passwordField, errorLabel, loginButton, continueButton])
        
        // If there is data present on this device, presents login, otherwise presents connection prompt
        do
        {
            if try AccountView.instance.createQuery(ofType: .noObjects).firstResultRow() == nil
            {
                noDataConnectPromptView.connectButtonAction = { [weak self] in self?.topBar.performConnect(using: self!) }
                noDataView.isHidden = false
                
                // Keychain is emptied too
                Session.instance.bookId = nil
                Session.instance.avatarId = nil
                Session.instance.projectId = nil
                Session.instance.logout()
            }
            else
            {
                loginView.isHidden = false
            }
        }
        catch
        {
            print("ERROR: Couldn't check if there was any data available or not")
            // TODO: Present error view or something
        }
       
    }
//    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
//        return .landscapeLeft
//    }
//
//    override var shouldAutorotate: Bool {
//        return true
//    }

    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        // If the user is already logged in, just starts the background updates and moves on
        if Session.instance.isAuthorized
        {
            print("STATUS: Already authorized")
            proceed(animated: false)
        }
        else
        {
            print("STATUS: No login information present")
            // ConnectionManager.instance.registerListener(self)
        }
        
        // viewManager.startKeyboardListening()
//        contentView.startKeyboardListening()
        
        topBar.updateUserView()
        setLangSegment(lang: selectedLang)
    }
    
    override func viewDidDisappear(_ animated: Bool)
    {
        // viewManager.endKeyboardListening()
//        contentView.endKeyboardListening()
    }
    
    
    // ACTIONS    -------------------
    
    @IBAction func loginButtonPressed(_ sender: Any)
    {
        // Makes sure the username and password have been provided first
        guard let userName = userNameField.text, !userName.isEmpty else
        {
            errorLabel.text = "Please provide an account name".localized()
            return
        }
        guard let password = passwordField.text, !password.isEmpty else
        {
            errorLabel.text = "Please provide a password".localized()
            return
        }
        
        do
        {
            // Finds the correct target account
            // TODO: Handle cases where there are multiple accounts with the same name
            guard let account = try AccountView.instance.accountQuery(name: userName).firstResultObject() else
            {
                errorLabel.text = "Invalid account name".localized()
                return
            }
            
            // Checks that the passwords match
            guard account.authorize(password: password) else
            {
                errorLabel.text = "Invalid password".localized()
                return
            }
            
            // Registers all devices the user has logged in with
            if let device = UIDevice.current.identifierForVendor?.uuidString
            {
                if !account.devices.contains(device)
                {
                    // TODO: Some kind of security check could be made here
                    account.devices.add(device)
                    try account.push()
                }
            }
            
            Session.instance.logIn(accountId: account.idString, userName: userName, password: password)
            
            // If there is a P2P session active, provides access to the host project
            checkP2PProjectAccess(for: account)
            proceed()
        }
        catch
        {
            print("ERROR: Login failed. \(error)")
//            errorLabel.text = "Internal error occurred!".localized()
        }
        
        /*
         loginButton.isEnabled = false
         onlineStatusView.isHidden = false
         
         loginUsername = userName
         loginPassword = password
         
         // Tries logging in
         // TODO: Use real authorization when it is only available
         ConnectionManager.instance.connect(serverURL: SERVER_ADDRESS, continuous: false)
         */
    }
    
    @IBAction func continueButtonPressed(_ sender: Any)
    {
        createAccount()
    }
    
    @IBAction func startNewButtonPressed(_ sender: Any)
    {
        createAccount()
    }
    
    
    // IMPLEMENTED METHODS    -------
    
    /*
     func onConnectionStatusChange(newStatus status: ConnectionStatus)
     {
     // Updates online status
     onlineStatusView.status = status
     
     if status.isFinal
     {
     // Re-enables the login button once done
     loginButton.isEnabled = true
     
     // Also, if the login was successful, proceeds to next view
     if status == .unauthorized
     {
     errorLabel.text = "Invalid username and/or password"
     passwordField.text = nil
     }
     else if status != .offline
     {
     errorLabel.text = nil
     onlineStatusView.isHidden = true
     
     if !status.isError
     {
     // Saves the login status to the session
     do
     {
     guard let result = try AccountView.instance.accountQuery(displayName: loginUsername!).firstResultRow() else
     {
     print("ERROR: No account for username: \(loginUsername!)")
     errorLabel.text = "Internal Error: No user data available"
     return
     }
     
     try Session.instance.logIn(accountId: result.id!, userName: loginUsername!.toKey, password: loginPassword!)
     proceed()
     }
     catch
     {
     print("ERROR: Login failed. \(error)")
     errorLabel.text = "Internal Error: Database operation failed"
     }
     }
     }
     }
     }
     
     func onConnectionProgressUpdate(transferred: Int, of total: Int, progress: Double)
     {
     onlineStatusView.updateProgress(completed: transferred, of: total, progress: progress)
     }
     */
    
    
    // OTHER METHODS    -----------
    
    private func createAccount()
    {
        // Moves to the create account view
        // ConnectionManager.instance.removeListener(self)
        // performSegue(withIdentifier: "CreateUser", sender: nil)
        displayAlert(withIdentifier: "CreateAccount", storyBoardId: "Login")
        {
            accountVC in
            
            if let accountVC = accountVC as? CreateAccountVC
            {
                accountVC.configure
                    {
                        self.checkP2PProjectAccess(for: $0)
                        self.proceed()
                }
            }
        }
    }
    
    private func checkP2PProjectAccess(for account: AgricolaAccount)
    {
        // If there is a P2P session active, provides access to the host project
        if P2PClientSession.isConnected
        {
            do
            {
                if let projectId = P2PClientSession.instance!.projectId, let project = try Project.get(projectId)
                {
                    if !project.contributorIds.contains(account.idString)
                    {
                        project.contributorIds.add(account.idString)
                        try project.push()
                    }
                    
                    // Session.instance.projectId = projectId
                }
            }
            catch
            {
                print("ERROR: Failed to provide project access. \(error)")
            }
        }
    }
    
    private func handleConnectionChange()
    {
        // If joined on a P2P connection that has a hosting project and shared account, checks if the user would like to auto-login with said account
        if P2PClientSession.isConnected, let projectId = P2PClientSession.instance?.projectId
        {
            do
            {
                if let project = try Project.get(projectId), let sharedAccountId = project.sharedAccountId
                {
                    displayAlert(withIdentifier: AutoLoginAlertVC.identifier, storyBoardId: "Login")
                    {
                        vc in (vc as! AutoLoginAlertVC).configure
                            {
                                if $0
                                {
                                    Session.instance.accountId = sharedAccountId
                                    self.proceed()
                                }
                        }
                    }
                }
            }
            catch
            {
                print("ERROR: Failed to read project / account data and enable auto-login")
            }
        }
    }
    
    /*
     private func connectionDialogClosed()
     {
     // If the user has joined a P2P session with a project, offers to auto-login with the project's shared account
     if P2PClientSession.isConnected
     {
     guard let projectId = P2PClientSession.instance?.projectId else
     {
     return
     }
     
     displayAlert(withIdentifier: AutoLoginAlertVC.identifier, storyBoardId: "Login")
     {
     alertVC in
     
     (alertVC as! AutoLoginAlertVC).configure()
     {
     result in
     
     if result
     {
     do
     {
     
     }
     // Session.instance.accountId =
     }
     }
     }
     }
     }*/
    
    private func proceed(animated: Bool = true)
    {
        //ConnectionManager.instance.removeListener(self)
        
        passwordField.text = nil
        errorLabel.text = nil
        
        // Starts the updates in the background
        // TODO: Add authorization when backed supports it
        // ConnectionManager.instance.connect(serverURL: SERVER_ADDRESS)
        
        print("STATUS: Moving to select project view")
        performSegue(withIdentifier: "SelectProject", sender: nil)
    }
    
    @IBAction func selectLangChanged(_ sender: Any) {
        switch langselectionseg.selectedSegmentIndex
        {
        case 0:
            selectedLang = "en"
//            defaults.set(selectedLang, forKey: "AppleLanguages")
            Language.setCurrentLanguage(selectedLang)
            languageButtonAction()
//            setLangSegment(lang: selectedLang)
            print(selectedLang)
        case 1:
            selectedLang = "id"
//            defaults.set(selectedLang, forKey: "AppleLanguages")
            Language.setCurrentLanguage(selectedLang)
            languageButtonAction()
//            setLangSegment(lang: selectedLang)
            print(selectedLang)
        default:
            break
        }
    }
    
    func languageButtonAction() {
        // This is done so that network calls now have the Accept-Language as Language.getCurrentLanguage() (Using Alamofire) Check if you can remove these
        UserDefaults.standard.set([Language.getCurrentLanguage()], forKey: "AppleLanguages")
//        UserDefaults.standard.set(selectedLang, forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        
        // Update the language by swaping bundle
        Bundle.setLanguage(Language.getCurrentLanguage())
//        Bundle.setLanguage(selectedLang)
        // Done to reintantiate the storyboards instantly
        let storyboard = UIStoryboard.init(name: "Login", bundle: nil)
//        UIApplication.shared.keyWindow?.rootViewController = storyboard.instantiateInitialViewController()
                 UIApplication.shared.windows.filter { $0.isKeyWindow }.first?.rootViewController = storyboard.instantiateInitialViewController()

    }
    func setLangSegment(lang: String){
        if lang == "en"{
                  langselectionseg.selectedSegmentIndex = 0
              }
              else{
                   langselectionseg.selectedSegmentIndex = 1
              }
//        languageButtonAction()
    }
    
}
