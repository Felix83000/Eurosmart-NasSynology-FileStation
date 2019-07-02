//
//  ViewController.swift
//  fido-eurosmart
//
//  Created by FelixMac on 11/06/2019.
//  Copyright © 2019 Eurosmart. All rights reserved.
//

import UIKit
import CoreData
import Network

class ViewController: UIViewController, UITextFieldDelegate, NetworkCheckObserver {

    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var submit_button: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    fileprivate var network: Network? = nil
    fileprivate var first = true
    fileprivate var networkCheck: Any?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.network = Network()
        username.becomeFirstResponder()
        username.delegate = self
        
        let preferences = UserDefaults.standard
        
        if(preferences.object(forKey: "sid") != nil)
        {
            loginDone()
        }
        if #available(iOS 12.0, *) {
            self.networkCheck = NetworkCheck.sharedInstance()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if #available(iOS 12.0, *) {
            if ((networkCheck as! NetworkCheck).currentStatus == .unsatisfied){
                // create the alert
                let alert = UIAlertController(title: "Network problem", message: "Check your network connection.", preferredStyle: .alert)
                // add an action (button)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                // show the alert
                self.present(alert, animated: true, completion: nil)
            }
            (networkCheck as! NetworkCheck).addObserver(observer: self)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if #available(iOS 12.0, *) {
            (networkCheck as! NetworkCheck).removeObserver(observer: self)
        }
        super.viewWillDisappear(animated)
    }
    
    @available(iOS 12.0, *)
    func statusDidChange(status: NWPath.Status) {
        if ((networkCheck as! NetworkCheck).currentStatus == .unsatisfied){
            // create the alert
            let alert = UIAlertController(title: "Network problem", message: "Check your network connection.", preferredStyle: .alert)
            // add an action (button)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            // show the alert
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .portrait
        } else {
            return .all
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if (first){
            username.resignFirstResponder()
            password.becomeFirstResponder()
            password.delegate = self
            first = false
        }else{
            password.resignFirstResponder()
            first = true
            submit(self)
        }
        // On retourne false pour dire qu'on ne veut pas que le boutton retour fasse un retour de base
        return false
    }

    @IBAction func submit(_ sender: Any) {
        let username = self.username.text
        let password = self.password.text
        
        if(username == "" || password == ""){
            return
        }
        
        self.network?.doLogin(self,username!,password!)
    }
    
    func loginDone()
    {
        print("Connection successful : \(username.text!)")
        let preferences = UserDefaults.standard
        preferences.set(username.text, forKey: "username")
        
        preferences.set(String(isFidoInBdd()), forKey: "isFidoRegistered")
        //performSegue(withIdentifier: "addFidoSegue", sender: self)
        performSegue(withIdentifier: "directToFiles", sender: self)
    }
    
    // L'utilisateur à un token fido dans la BDD -> true
    // L'utilisateur n'a pas de token fido dans la BDD -> false
    //
    // Si l'utilisateur n'existe pas dans la BDD local on l'ajoute 
    func isFidoInBdd() -> Bool
    {
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return false
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "User")
        request.returnsObjectsAsFaults = false
        do {
            let result = try managedContext.fetch(request)
            for data in result as! [NSManagedObject] {
                // Vérification si l'utilisateur est dans la BDD
                if (data.value(forKey: "name") as? String ?? "Nothing" == username.text){
                    // Is fido registered?
                    return data.value(forKey: "fidotoken") as? Bool ?? false
                }
            }
        } catch {
            print("Failed")
        }
        
        // Stockage de l'utilisateur en BDD local
        let entity = NSEntityDescription.entity(forEntityName: "User", in: managedContext)!
        let person = NSManagedObject(entity: entity, insertInto: managedContext)
        
        person.setValue(username.text, forKey: "name")
        
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
        // On retourne false car l'utilisateur n'est pas dans la base et ne possède pas de token
        return false
    }
}

