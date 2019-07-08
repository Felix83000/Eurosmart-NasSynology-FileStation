//
//  Network.swift
//  fido-eurosmart
//
//  Created by FelixMac on 25/06/2019.
//  Copyright © 2019 Eurosmart. All rights reserved.
//

import UIKit

/// The purpose of the `Network` class is to gather all **Synology FileStation API** Requests.
final class Network {
    /// The `ip` variable is use to reach a Synology NAS, please fill it with your NAS `ip`.
    fileprivate(set) var ip = "172.16.103.116"
    /// The `port` variable is use to reach a Synology NAS, please fill it with your NAS `port`.
    fileprivate(set) var port = "1987" // 1988 : https, 1987: http
    /// If you want to configure **API Requests** in **http** or **https** change this `httpType` variable.
    fileprivate(set) var httpType = "http"
    var sid = "none"
    
    init() {
        let preferences = UserDefaults.standard
        if(preferences.object(forKey: "sid") != nil){
            self.sid = preferences.object(forKey: "sid") as? String ?? "none"
        }else{
            self.sid = "none"
        }
    }
    
    // MARK: API Requests
    /**
     Login Request to **Synology FileStation API**. Connect the user if the request is successful. Set the **session key** in the **preferences** and **class attribute**. Also handle errors.
     
     - Parameter viewController: Permit access to local Controller attributes.
     - Parameter user: Username who have to correspond to the NAS LDAP user.
     - Parameter pwd: Password who have also to correspond to the NAS LDAP user.
     
     - Warning: This function is needed as **first API Request**. The answered **sid** will be used by **all** the other API requests.
     */
    func doLogin(_ viewController: ViewController,_ user:String,_ pwd:String)
    {
        viewController.activityIndicator.startAnimating()
        
        let urlOriginal = "\(httpType)://\(ip):\(port)/webapi/auth.cgi?api=SYNO.API.Auth&version=3&method=login&account=\(user)&passwd=\(pwd)&session=FileStation&format=sid"// À passer en https, avec cert let's encrypt
        let url = URL(string: urlOriginal.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) ?? "")
        
        let session = URLSession.shared
        
        let request = NSMutableURLRequest(url: url!)
        request.httpMethod = "GET"
        
        let task = session.dataTask(with: request as URLRequest, completionHandler: {
            (data, response, error) in
            guard let _:Data = data else
            {
                viewController.activityIndicator.stopAnimating()
                return
            }
            
            let json:Any?
            
            do
            {
                json = try JSONSerialization.jsonObject(with: data!, options: [])
            }
            catch
            {
                return
            }
            
            guard let server_response = json as? NSDictionary else
            {
                return
            }
            
            if let error = server_response["error"] as? NSDictionary
            {
                if let code = error["code"] as? Int
                {
                    if (code == 400){
                        DispatchQueue.main.async {
                            viewController.activityIndicator.stopAnimating()
                            // create the alert
                            let alert = UIAlertController(title: "Identification problem", message: "The account or password is not valid. Please try again.", preferredStyle: .alert)
                            // add an action (button)
                            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                            // show the alert
                            viewController.present(alert, animated: true, completion: nil)
                            viewController.password.text = ""
                        }
                    }
                }
            }
            
            if let data_block = server_response["data"] as? NSDictionary
            {
                if let session_data = data_block["sid"] as? String
                {
                    let preferences = UserDefaults.standard
                    preferences.set(session_data, forKey: "sid")
                    //Setting the session key attribute
                    self.sid = session_data
                    DispatchQueue.main.async {
                        viewController.activityIndicator.stopAnimating()
                    }
                    DispatchQueue.main.async(
                        execute:viewController.loginDone
                    )
                }
            }
        })
        task.resume()
    }
    
    /**
     Create Request to **Synology FileStation API**. Create the folder if the request is successful. Also handle errors.
     
     - Parameter fileViewController: Permit access to local Controller attributes.
     - Parameter folderName: FolderName that the user wants to create.
     */
    func createFolder(_ fileViewController: FileViewController,_ folderName: String){
        fileViewController.activityIndicator.startAnimating()

        var folderPath = fileViewController.currentPath
        if(folderPath == ""){
            folderPath = "/"
        }
        let urlOriginal = "\(httpType)://\(ip):\(port)/webapi/entry.cgi?api=SYNO.FileStation.CreateFolder&version=2&method=create&folder_path=\(folderPath)&name=\(folderName)&_sid=\(sid)"// À passer en https, avec cert let's encrypt
        let url = URL(string: urlOriginal.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) ?? "")
        
        let session = URLSession.shared
        
        let request = NSMutableURLRequest(url: url!)
        request.httpMethod = "GET"
        
        let task = session.dataTask(with: request as URLRequest, completionHandler: {
            (data, response, error) in
            guard let _:Data = data else
            {
                fileViewController.activityIndicator.stopAnimating()
                return
            }
            let json:Any?
            do
            {
                json = try JSONSerialization.jsonObject(with: data!, options: [])
            }
            catch
            {
                return
            }
            guard let server_response = json as? NSDictionary else
            {
                return
            }
            if let error = server_response["error"] as? NSDictionary
            {
                if let code = error["code"] as? Int
                {
                    if (code == 1100){
                        DispatchQueue.main.async {
                            // create the alert
                            let alert = UIAlertController(title: "Folder Creation Problem", message: "Maybe there is a rights problem. Feel free to contact the administrator.", preferredStyle: .alert)
                            // add an action (button)
                            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                            // show the alert
                            fileViewController.present(alert, animated: true, completion: nil)
                        }
                    }
                    if (code == 400){
                        DispatchQueue.main.async {
                            // create the alert
                            let alert = UIAlertController(title: "Folder Creation Problem", message: "Please enter a name for the folder.", preferredStyle: .alert)
                            // add an action (button)
                            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                            // show the alert
                            fileViewController.present(alert, animated: true, completion: nil)
                        }
                    }
                    DispatchQueue.main.async {
                        fileViewController.activityIndicator.stopAnimating()
                    }
                }
            }
            if (server_response["data"] as? NSDictionary) != nil
            {
                DispatchQueue.main.async {
                    fileViewController.activityIndicator.stopAnimating()
                    self.fetchDirectoriesDetails(fileViewController,folderPath,noBackButton: true)
                }
            }
        })
        task.resume()
    }
    
    /**
     List Share Request to **Synology FileStation API**. List the shared folders if the request is successful. Also handle errors.
     
     - Parameter fileViewController: Permit access to local Controller attributes.
     - Parameter refresh: If the dev wants to use this function to refresh. Refresher indicator ends after the request response.
     */
    func fetchDirectories(_ fileViewController: FileViewController, refresh: Bool=false) {
        if(!refresh){
            fileViewController.activityIndicator.startAnimating()
        }
        
        let urlOriginal = "\(httpType)://\(ip):\(port)/webapi/entry.cgi?api=SYNO.FileStation.List&version=2&method=list_share&_sid=\(sid)"// À passer en https, avec cert let's encrypt
        let url = URL(string: urlOriginal.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) ?? "")
        
        let session = URLSession.shared
        
        let request = NSMutableURLRequest(url: url!)
        request.httpMethod = "GET"
        
        let task = session.dataTask(with: request as URLRequest, completionHandler: {
            (data, response, error) in
            guard let _:Data = data else
            {
                fileViewController.activityIndicator.stopAnimating()
                return
            }
            let json:Any?
            do
            {
                json = try JSONSerialization.jsonObject(with: data!, options: [])
            }
            catch
            {
                return
            }
            guard let server_response = json as? NSDictionary else
            {
                return
            }
            if let data_block = server_response["data"] as? NSDictionary
            {
                if let JSON = data_block as? [String: Any] {
                    guard let jsonArray = JSON["shares"] as? [[String: Any]] else {
                        return
                    }
                    fileViewController.listDirFiles.removeAll()
                    for json in jsonArray
                    {
                        fileViewController.listDirFiles.append(DirFileData(json))
                    }
                    fileViewController.tabListDirFiles[0] = fileViewController.listDirFiles
                    DispatchQueue.main.async {
                        if(fileViewController.activityIndicator.isAnimating){
                            fileViewController.activityIndicator.stopAnimating()
                        }
                    }
                    DispatchQueue.main.async(
                        execute:fileViewController.fetchDone
                    )
                    if(refresh){
                        let deadLine = DispatchTime.now() + .milliseconds(700)
                        DispatchQueue.main.asyncAfter(deadline: deadLine){
                            fileViewController.refresher.endRefreshing()
                        }
                    }
                }
            }
        })
        task.resume()
    }
    
    /**
     List Request to **Synology FileStation API**. List the folder needed if the request is successful. Also handle errors.
     
     - Parameter fileViewController: Permit access to local Controller attributes.
     - Parameter refresh: If the dev wants to use this function to refresh. Refresher indicator ends after the request response.
     - Parameter folderPath: Synology FileStation path to the folder needed.
     - Parameter noBackButton: If the dev wants to use this function without enable back button history.
     */
    func fetchDirectoriesDetails(_ fileViewController: FileViewController,_ folderPath: String, noBackButton: Bool, refresh: Bool=false) {
        if(!refresh){
            fileViewController.activityIndicator.startAnimating()
        }
        let urlOriginal = "\(httpType)://\(ip):\(port)/webapi/entry.cgi?api=SYNO.FileStation.List&version=2&method=list&folder_path=\(folderPath)&_sid=\(sid)"// À passer en https, avec cert let's encrypt
        let url = URL(string: urlOriginal.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) ?? "")
        
        let session = URLSession.shared
        
        let request = NSMutableURLRequest(url: url!)
        request.httpMethod = "GET"
        
        let task = session.dataTask(with: request as URLRequest, completionHandler: {
            (data, response, error) in
            guard let _:Data = data else
            {
                fileViewController.activityIndicator.stopAnimating()
                return
            }
            let json:Any?
            do
            {
                json = try JSONSerialization.jsonObject(with: data!, options: [])
            }
            catch
            {
                return
            }
            guard let server_response = json as? NSDictionary else
            {
                return
            }
            if let data_block = server_response["data"] as? NSDictionary
            {
                if let JSON = data_block as? [String: Any] {
                    guard let jsonArray = JSON["files"] as? [[String: Any]] else {
                        return
                    }
                    if(!noBackButton){
                        fileViewController.lastId+=1
                        fileViewController.tabListDirFiles.insert(fileViewController.listDirFiles, at: fileViewController.lastId)
                    }
                    fileViewController.listDirFiles.removeAll()
                    for json in jsonArray
                    {
                        fileViewController.listDirFiles.append(DirFileData(json))
                    }
                    DispatchQueue.main.async {
                        if(fileViewController.activityIndicator.isAnimating){
                            fileViewController.activityIndicator.stopAnimating()
                        }
                    }
                    DispatchQueue.main.async(
                        execute:fileViewController.fetchDone
                    )
                    if(refresh){
                        let deadLine = DispatchTime.now() + .milliseconds(700)
                        DispatchQueue.main.asyncAfter(deadline: deadLine){
                            fileViewController.refresher.endRefreshing()
                        }
                    }
                }
            }
        })
        task.resume()
    }
    
    /**
     Upload Request to **Synology FileStation API**. Upload the file needed if the request is successful. Also handle errors.
     
     - Parameter fileViewController: Permit access to local Controller attributes.
     - Parameter urls: **Local** application Urls of **selected files**. In our case it is only **one url** to the file selected.
     */
    func uploadFile(_ fileViewController: FileViewController,_ urls: [URL]){
        guard let selectedFileURL = urls.first else {
            return
        }
        do {
            fileViewController.activityIndicator.startAnimating()
            // Lecture du fichier pour la représentation en data
            var documentData = Data()
            documentData.append(try Data(contentsOf: urls.first!))
            
            var folderPath = fileViewController.currentPath
            if(folderPath == ""){
                folderPath = "/"
            }
            
            let urlOriginal = "\(httpType)://\(ip):\(port)/webapi/entry.cgi"// À passer en https, avec cert let's encrypt
            let url = URL(string: urlOriginal.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) ?? "")
            
            let session = URLSession.shared
            let boundary = "Boundary-\(UUID().uuidString)"
            
            var request = URLRequest(url: url!,cachePolicy: URLRequest.CachePolicy.useProtocolCachePolicy,timeoutInterval: 60)
            request.httpMethod = "POST"
            request.httpShouldHandleCookies = true
            let body = self.createBody(contentFile: documentData, folderPath, selectedFileURL,boundary)
            request.httpBody = body as Data
            request.addValue(String(describing: body.length), forHTTPHeaderField: "Content-Length")
            request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            let task = session.dataTask(with: request as URLRequest, completionHandler: {
                (data, response, error) in
                guard let _:Data = data else
                {
                    fileViewController.activityIndicator.stopAnimating()
                    return
                }
                let json:Any?
                do
                {
                    json = try JSONSerialization.jsonObject(with: data!, options: [])
                }
                catch
                {
                    return
                }
                guard let server_response = json as? NSDictionary else
                {
                    return
                }
                if let error = server_response["error"] as? NSDictionary
                {
                    if let code = error["code"] as? Int
                    {
                        if (code == 414){
                            DispatchQueue.main.async {
                                // create the alert
                                let alert = UIAlertController(title: "Upload Problem", message: "File already exists.", preferredStyle: .alert)
                                // add an action (button)
                                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                                // show the alert
                                fileViewController.present(alert, animated: true, completion: nil)
                            }
                        }
                        if (code == 407){
                            DispatchQueue.main.async {
                                // create the alert
                                let alert = UIAlertController(title: "Upload Problem", message: "Maybe there is a rights problem. Feel free to contact the administrator.", preferredStyle: .alert)
                                // add an action (button)
                                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                                // show the alert
                                fileViewController.present(alert, animated: true, completion: nil)
                            }
                        }
                        DispatchQueue.main.async {
                            fileViewController.activityIndicator.stopAnimating()
                        }
                    }
                }
                if (server_response["data"] as? NSDictionary) != nil
                {
                    DispatchQueue.main.async {
                        fileViewController.activityIndicator.stopAnimating()
                        self.fetchDirectoriesDetails(fileViewController,folderPath,noBackButton: true)
                    }
                }
            })
            task.resume()
            
        } catch {
            print("no data")
        }
    }
    
    /**
     Create the http POST body.
     
     - Parameter contentFile: Content of the file the user wants to upload.
     - Parameter selectedFileUrl: Local application url to the file selected.
     - Parameter boundary: Boundary.
     - Parameter folderPath: Synology FileStation path to the wanted folder to upload the file.
     */
    func createBody(contentFile: Data,_ folderPath: String,_ selectedFileUrl: URL,_ boundary: String) -> NSMutableData {
        let body = NSMutableData()
        
        body.append(String("--\(boundary)\r\n").data(using: .utf8)!)
        body.append(String("content-disposition: form-data; name=\"api\"\r\n\r\nSYNO.FileStation.Upload").data(using: .utf8)!)
        
        body.append(String("\r\n--\(boundary)\r\n").data(using: .utf8)!)
        body.append(String("content-disposition: form-data; name=\"version\"\r\n\r\n2").data(using: .utf8)!)
        
        body.append(String("\r\n--\(boundary)\r\n").data(using: .utf8)!)
        body.append(String("content-disposition: form-data; name=\"method\"\r\n\r\nupload").data(using: .utf8)!)
        
        body.append(String("\r\n--\(boundary)\r\n").data(using: .utf8)!)
        body.append(String("content-disposition: form-data; name=\"_sid\"\r\n\r\n\(sid)").data(using: .utf8)!)
        
        body.append(String("\r\n--\(boundary)\r\n").data(using: .utf8)!)
        body.append(String("content-disposition: form-data; name=\"path\"\r\n\r\n\(folderPath)").data(using: .utf8)!)
        
        body.append(String("\r\n--\(boundary)\r\n").data(using: .utf8)!)
        body.append(String("content-disposition: form-data; name=\"create_parents\"\r\n\r\ntrue").data(using: .utf8)!)
        
        body.append(String("\r\n--\(boundary)\r\n").data(using: .utf8)!)
        print("selectedFileUrl.lastPathComponent : ",selectedFileUrl.lastPathComponent)
        body.append(String("content-disposition: form-data; name=\"\(selectedFileUrl.lastPathComponent)\";filename=\"\(selectedFileUrl.lastPathComponent)\"\r\n").data(using: .utf8)!)
        body.append(String("Content-Type: application/octet-stream\r\n\r\n").data(using: .utf8)!)
        body.append(contentFile)
        
        body.append(String("\r\n--\(boundary)--\r\n").data(using: .utf8)!)
        
        return body
    }
    
    /**
     Delete Request to **Synology FileStation API**. Delete the folder or file needed if the request is successful. Also handle errors.
     
     - Parameter fileViewController: Permit access to local Controller attributes.
     - Parameter path: Synology FileStation path to the folder or file the user wants to delete.
     */
    func deleteFile(_ fileViewController: FileViewController,_ path: String){
        fileViewController.activityIndicator.startAnimating()
        
        let urlOriginal = "\(httpType)://\(ip):\(port)/webapi/entry.cgi?api=SYNO.FileStation.Delete&version=2&method=delete&path=\(path)&_sid=\(sid)"// À passer en https, avec cert let's encrypt
        let url = URL(string: urlOriginal.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) ?? "")
        
        let session = URLSession.shared
        
        let request = NSMutableURLRequest(url: url!)
        request.httpMethod = "GET"
        
        let task = session.dataTask(with: request as URLRequest, completionHandler: {
            (data, response, error) in
            guard let _:Data = data else
            {
                fileViewController.activityIndicator.stopAnimating()
                return
            }
            let json:Any?
            do
            {
                json = try JSONSerialization.jsonObject(with: data!, options: [])
            }
            catch
            {
                return
            }
            guard let server_response = json as? NSDictionary else
            {
                return
            }
            if let error = server_response["error"] as? NSDictionary
            {
                if let code = error["code"] as? Int
                {
                    if (code == 900){
                        DispatchQueue.main.async {
                            // create the alert
                            let alert = UIAlertController(title: "Delete Problem", message: "Maybe there is a rights problem. Feel free to contact the administrator.", preferredStyle: .alert)
                            // add an action (button)
                            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                            // show the alert
                            fileViewController.present(alert, animated: true, completion: nil)
                        }
                    }
                    DispatchQueue.main.async {
                        fileViewController.activityIndicator.stopAnimating()
                    }
                }
            }else{
                DispatchQueue.main.async {
                    fileViewController.activityIndicator.stopAnimating()
                    self.fetchDirectoriesDetails(fileViewController,fileViewController.currentPath,noBackButton: true)
                }
            }
        })
        task.resume()
    }
}
