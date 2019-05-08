//
//  TimeLineViewController.swift
//  WatsonDogSNS
//
//  Created by Kiyoto Ryuman on 2019/05/08.
//  Copyright © 2019 Kiyoto Ryuman. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD
import SDWebImage
class TimeLineViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
   
    @IBOutlet var tableView: UITableView!
    let refreshControl = UIRefreshControl()
    var fullName_Array = [String]()
    var postImage_Array = [String]()
    var comment_Array = [String]()
    
    var posts = [Post]()
    var posst = Post()
    
    override func viewDidLoad() {
        super.viewDidLoad()

       tableView.delegate = self
       tableView.dataSource = self
       refreshControl.attributedTitle = NSAttributedString(string: "引っ張って更新")
       refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
       tableView.addSubview(refreshControl)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchData()
        tableView.reloadData()
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        SVProgressHUD.dismiss()
    }
    @objc func refresh(){
        fetchData()
        refreshControl.endRefreshing()
    }
    func fetchData(){
        self.posts = [Post]()
        self.posst = Post()
        self.fullName_Array = [String]()
        self.comment_Array = [String]()
        self.postImage_Array = [String]()
        
        let ref = Database.database().reference()
        ref.child("post").queryLimited(toFirst: 10).observeSingleEvent(of: .value){(snap,error) in
            
            guard let postsSnap = snap.value as? [String:NSDictionary]else {
                return
            }
            
            self.posts = [Post]()
            
            for(_,post) in postsSnap {
                self.posts = [Post]()
                self.posst = Post()
                self.fullName_Array = [String]()
                self.comment_Array = [String]()
                self.postImage_Array = [String]()
                
                if let comment = post["comment"] as? String,let userName = post["userName"] as? String, let postImage = post["postImage"] as? String{
                    self.posst.comment = comment
                    self.posst.fullName = userName
                    self.posst.postImage = postImage
                    
                    self.comment_Array.append(self.posst.comment)
                    self.fullName_Array.append(self.posst.fullName)
                    self.postImage_Array.append(self.posst.postImage)
                }
                
                self.posts.append(self.posst)
            }
            self.tableView.reloadData()
            
            }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let profileImageView = cell.viewWithTag(1) as! UIImageView
        let profileImageURL = URL(string: self.posts[indexPath.row].postImage as String)!
        profileImageView.sd_setImage(with: profileImageURL, completed: nil)
        profileImageView.layer.cornerRadius = 8.0
        profileImageView.clipsToBounds = true
        let userNameLabel = cell.viewWithTag(2) as! UILabel
        userNameLabel.text = self.posts[indexPath.row].fullName
        let comment = cell.viewWithTag(3) as! UILabel
        comment.text = self.posts[indexPath.row].comment
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 535
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
