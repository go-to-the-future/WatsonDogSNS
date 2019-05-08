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
    let version = "2019-5-8"
    var dogOrNot:Bool! = true
    var resultString = String()
    var classificationResult:[String] = []
    var userName = String()
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.delegate = self
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
        if let pickedImage = info[.originalImage] as? UIImage{
            
            self.cameraImageView.image = pickedImage
            let visualR = VisualRecognition(version: version, apiKey: apiKey, iamUrl: nil)
            let imageData = pickedImage.jpegData(compressionQuality: 1.0)
            let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            let fileURL = documentURL?.appendingPathComponent("tempImage.jpg")
            try! imageData?.write(to: fileURL!, options: [])
            self.classificationResult = []
            
            visualR.classify(imagesFile: imageData,
                             imagesFilename: nil, imagesFileContentType: "ja",
                             url: nil,
                             threshold: nil,
                             owners: nil,
                             classifierIDs: ["default"],
                             acceptLanguage: nil) { (response, error) in
                                
                                if let classifiedImages = response?.result {
                                    
                                    print(classifiedImages)
                                    
                                    
                                    let classes = classifiedImages.images.first!.classifiers.first!.classes
                                    
                                    for index in 1..<classes.count{
                                        
                                        self.classificationResult.append(classes[index].className)
                                        if self.classificationResult.contains("犬"){
                                            
                                            DispatchQueue.main.async{
                                                print("犬です")
                                                self.dogOrNot = true
                                                SVProgressHUD.dismiss()
                                                
                                            }
                                        }else{
                                            DispatchQueue.main.async{
                                                print("犬ではないです")
                                                self.dogOrNot = false
                                                SVProgressHUD.dismiss()
                                                
                                            }
                                            
                                        }
                                        
                                    }
                                    
                                }
                           }
                             picker.dismiss(animated: true, completion: nil)
                   }
             }
    
    func postData(){
        let rootRef = Database.database().reference(fromURL: "https://watsondogsns.firebaseio.com/").child("post")
        let storage = Storage.storage().reference(forURL: "gs://watsondogsns.appspot.com/")
        let key = rootRef.child("User").childByAutoId().key
        let imageRef = storage.child("User").child("\(key).jpg")
        var data:NSData = NSData()
        if let image = cameraImageView.image{
            data = image.jpegData(compressionQuality: 0.01) as!NSData
        
        }
        let uploadTask = imageRef.putData(data as Data, metadata: nil){(metadata, error) in
            
            if error != nil {
                SVProgressHUD.show()
                return
            }
            
            imageRef.downloadURL(completion: {(url, error) in
                if url != nil {
                    let feed = ["postImage": url?.absoluteString,"comment":self.textView.text,"fullName":self.userName] as! [String:Any]
                    let postFeed = ["\(key)":feed]
                    rootRef.updateChildValues(postFeed)
                    SVProgressHUD.dismiss()
                }
            } )
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
