//
//  ShareViewController.swift
//  WatsonDogSNS
//
//  Created by Kiyoto Ryuman on 2019/05/08.
//  Copyright © 2019 Kiyoto Ryuman. All rights reserved.
//

import UIKit
import Photos
import VisualRecognitionV3
import SVProgressHUD
import Firebase
import EMAlertController
import RestKit
class ShareViewController: UIViewController,UIImagePickerControllerDelegate,UINavigationControllerDelegate,UITextViewDelegate {

    @IBOutlet var textView: UITextView!
    @IBOutlet var cameraImageView: UIImageView!
    let refreshControl = UIRefreshControl()
    var userName_Array = [String]()
    var postImage_Array = [String]()
    var comment_Array = [String]()
    var fullName = String()
    var postImageURL:URL!
    var passImage = UIImage()
    let apiKey = ""
    let version = "2019-03-19"
    var dogOrNot:Bool! = true
    var resultString = String()
    var userName = String()
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.delegate = self
        cameraImageView.clipsToBounds = true
        PHPhotoLibrary.requestAuthorization{ (status) in
            
            switch(status){
            case .authorized:break
            case .denied:break
            case .notDetermined:break
            case .restricted:break
            @unknown default:
                break
            }
        }
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.userName = UserDefaults.standard.object(forKey: "userName") as! String
    }

    @IBAction func camera(_ sender: Any) {
        let sourceType:UIImagePickerController.SourceType = UIImagePickerController.SourceType.camera
        // カメラが利用可能かチェック
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera){
            // インスタンスの作成
            let cameraPicker = UIImagePickerController()
            cameraPicker.sourceType = sourceType
            cameraPicker.delegate = self
            cameraPicker.allowsEditing = true
            self.present(cameraPicker, animated: true, completion: nil)
            
        }else{
            
            print("エラー")
        }
    }
    @IBAction func album(_ sender: Any) {
        let sourceType:UIImagePickerController.SourceType = UIImagePickerController.SourceType.photoLibrary
        // カメラが利用可能かチェック
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary){
            // インスタンスの作成
            let cameraPicker = UIImagePickerController()
            cameraPicker.sourceType = sourceType
            cameraPicker.delegate = self
            cameraPicker.allowsEditing = true
            self.present(cameraPicker, animated: true, completion: nil)
            
        }else{
            
            print("エラー")
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        SVProgressHUD.show()
        print("ぐるぐる")
        if let pickedImage = info[.originalImage] as? UIImage{
            
            self.cameraImageView.image = pickedImage
            let visualR = VisualRecognition(version: version, apiKey: apiKey, iamUrl: nil)
            let imageData = pickedImage.jpegData(compressionQuality: 1.0)
            print("データできた")
            let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            let fileURL = documentURL?.appendingPathComponent("tempImage.jpg")
            try! imageData?.write(to: fileURL!, options: [])
            
            print("URLできた")
            visualR.classify(imagesFile: imageData, imagesFilename: nil, imagesFileContentType: "jpeg", url: nil, threshold: nil, owners: nil, classifierIDs: ["default"], acceptLanguage: "ja", headers: nil){ (response, error) in
                                if let error = error {
                                    print("★error=\(error)")
                                }
                                if let classifiedImages = response?.result {
                                    
                                    print(classifiedImages)
                                    
                                    
                                    let classes = classifiedImages.images.first!.classifiers.first!.classes
                                    
                                    self.dogOrNot = false
                                    print("★classes=\(classes)") // ★追加★
                                    for index in 0..<classes.count{
                                        print("-----") // ★追加★
                                        print("★index=\(index):" + classes[index].className) // ★追加★
                                        if classes[index].className == "犬" {
                                            print("犬です")
                                            self.dogOrNot = true
                                            break
                                        }
                                    }
                                    if !self.dogOrNot {
                                        print("犬ではないです")
                                    }
                                    DispatchQueue.main.async{
                                        SVProgressHUD.dismiss()
                                    }
                                    
                                }
                           }
                             picker.dismiss(animated: true, completion: nil)
                   }
             }
    
    func postData(){
        let rootRef = Database.database().reference(fromURL: "https://watsondogsns.firebaseio.com/").child("post")
        let storage = Storage.storage().reference(forURL: "gs://watsondogsns.appspot.com/")
        guard let key = rootRef.child("User").childByAutoId().key else {
            print("error: key が取得できませんでした")
            return
        }
        let imageRef = storage.child("Users").child("\(key).jpg")
        
        var data:NSData = NSData()
        if let image = cameraImageView.image{
            
            data = image.jpegData(compressionQuality: 0.01)! as NSData
        }
        
        let uploadTask = imageRef.putData(data as Data, metadata: nil) { (metaData, error) in
            
            if error != nil{
                
                SVProgressHUD.show()
                return
            }
            
            imageRef.downloadURL(completion: { (url, error) in
                
                if url != nil{
                    
                    let feed = ["postImage":url?.absoluteString,"comment":self.textView.text,"fullName":self.userName] as [String:Any]
                    let postFeed = ["\(key)":feed]
                    rootRef.updateChildValues(postFeed)
                    SVProgressHUD.dismiss()
                    
                }
                
            })
            
        }
        
        uploadTask.resume()
        self.dismiss(animated: true, completion: nil)
        
        
    }
    
    @IBAction func share(_ sender: Any) {
        if dogOrNot == true{
            postData()
        }else{
            let alert = EMAlertController(icon: UIImage(named: "dogIcon.jpg"), title: "ごめんなさい", message: "犬ではないようです")
            let action = EMAlertAction(title: "OK", style: .cancel)
            alert.addAction(action)
            present(alert, animated: true, completion: nil)
        }
    }
    @IBAction func back(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        textView.resignFirstResponder()
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

