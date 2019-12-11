//
//  LeaderboardViewController.swift
//  ARPaperToss
//
//  Created by Shikhar Shah on 2019-12-10.
//  Copyright © 2019 Lambton. All rights reserved.
//

import Foundation
import UIKit
import FirebaseDatabase
import FirebaseAuth

class LeaderboardViewController : UIViewController,UITableViewDataSource,UITableViewDelegate{
    
    @IBOutlet weak var tableview: UITableView!
    
    var names  = [String]()
    var scores  = [Int]()
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        names.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = TableCell(style: .default, reuseIdentifier: "reusable")
        let score = scores[indexPath.row]
        var stringData = "\(score) by \(names[indexPath.row])"
        cell.textLabel?.font = UIFont(name: "BlueberryRegular", size: 18.0)
        cell.textLabel?.text = stringData

         return cell
    }
    
    @IBAction func onClose(_ sender: Any) {
  navigationController?.popViewController(animated: true)

  dismiss(animated: true, completion: nil)
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableview.dataSource = self
        tableview.delegate = self
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "bg_leaderboard.png")!)
        fetchGlobalLeaderboard()
    }
    func fetchGlobalLeaderboard(){
          print("fetchLeaderboardData")
          let ref = Database.database().reference()
        
        ref.observe(.childAdded, with: {(snapshot) in
          print(snapshot.value!)
            for(key,value) in (snapshot.value as? NSDictionary)!{
                if(key  as! String == "username")
                {
                    print("Name \(value)")
                    self.names.append(value as! String)
                }
                if(key as! String == "highscore"){
                    print("Score  \(value)")
                    self.scores.append(value as! Int)
                }
            }
            self.tableview.reloadData()
        })

}
    
func getScoreFromLocalDb()->NSString{
    let fetchedUsername: NSString  = NSString( string: UserDefaults.standard.string(forKey: "username")!)
    
       if(fetchedUsername != nil){
           print("Username fetched from local storage : ")
                  print(fetchedUsername)
           return fetchedUsername
       }
       else{
           return ""
       }
   }
   }
