//
//  WelcomeViewController.swift
//  Beaconn
//
//  Created by 北島研究室２ on 2022/11/04.
//

import Foundation
import UIKit
import Firebase

class WelcomeViewController: UIViewController {
    
    var user: User? {
        didSet {
            print("user?.name: ", user?.name)
        }
    }
    
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var homeButton: UIButton!
    @IBAction func tappedLogoutButton(_ sender: Any) {
        handleLogout()
    }
    @IBAction func tappedHomeButton(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        let homeViewController = storyboard.instantiateViewController(identifier: "HomeViewController") as! HomeViewController
        homeViewController.modalPresentationStyle = .fullScreen
        self.present(homeViewController, animated: true, completion: nil)
        
    }
    
    private func handleLogout() {
        do {
            try Auth.auth().signOut()
            presentToMainViewController()
        } catch (let err) {
            print("ログアウトに失敗しました: \(err)")
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        logoutButton.layer.cornerRadius = 10
        homeButton.layer.cornerRadius = 10
        
        if let user = user {
            nameLabel.text = user.name + "さんようこそ"
            emailLabel.text = user.email
            let dateString = dateFormatterForCreatedAt(date: user.createdAt.dateValue())
            dateLabel.text = "作成日： " + dateString
            
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        confirmLoggedInUser()
        
    }
    
    private func confirmLoggedInUser() {
        if Auth.auth().currentUser?.uid == nil || user == nil {
            presentToMainViewController()
        }
        
    }
    
    private func presentToMainViewController() {
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let ViewController = storyBoard.instantiateViewController(identifier: "ViewController") as! ViewController
        let navController = UINavigationController(rootViewController: ViewController)
        navController.modalPresentationStyle = .fullScreen
        
        self.present(navController, animated: true, completion: nil)
    }
    
    private func dateFormatterForCreatedAt(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}
