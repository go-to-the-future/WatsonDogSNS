//
//  ViewController.swift
//  WatsonDogSNS
//
//  Created by Kiyoto Ryuman on 2019/05/07.
//  Copyright © 2019 Kiyoto Ryuman. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet var userNameTextField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        userNameTextField.delegate = self
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let userName = UserDefaults.standard.object(forKey: "userName"){
            performSegue(withIdentifier: "next", sender: nil)
        }
        
    }
    @IBAction func login(_ sender: Any) {
        let ud = UserDefaults.standard
        ud.set(userNameTextField.text, forKey: "userName")
        performSegue(withIdentifier: "next", sender: nil)
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        userNameTextField.resignFirstResponder()
    }
}

