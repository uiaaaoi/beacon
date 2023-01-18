import UIKit
import Firebase
import CoreLocation
import FirebaseAuth
import PKHUD
import FirebaseFirestore




class ViewController: UIViewController, CLLocationManagerDelegate  {

    var user: User?
    
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBAction func tappedRegisterButton(_ sender: Any) {
        handleAuthToFirebase()
    }
    
    @IBAction func tappedHaveAccountButton(_ sender: Any) {
        pushToLoginViewController()
    }
    
    private func handleAuthToFirebase() {
        HUD.show(.progress, onView: view)
        guard let email = emailTextField.text else { return }
        guard let password = passwordTextField.text else { return }
        
        Auth.auth().createUser(withEmail: email, password: password) { (res, err) in
            if let err = err {
                print("認証情報の保存に失敗しました。 \(err)")
                HUD.hide { (_) in
                    HUD.flash(.error, delay: 1)
                }
                return
            }
            self.addUserInfotoFirestore(email: email)
        }
    }

    var attendance = "欠席"

    private func addUserInfotoFirestore(email: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let name = self.usernameTextField.text else { return }
        let docData = ["email": email, "name": name, "createdAt": Timestamp(), "attendance": attendance] as [String : Any]
        let userRef = Firestore.firestore().collection("users").document(uid)
        userRef.setData(docData) { (err) in
            if let err = err {
                print("Firebaseの保存に失敗しました。 \(err)")
                HUD.hide { (_) in
                    HUD.flash(.error, delay: 1)
                }
                return
            }
            self.fetchUserInfoFromFirestore(userRef: userRef)
        }
    }
    
    private func fetchUserInfoFromFirestore(userRef: DocumentReference) {
        userRef.getDocument{ (snapshot, err) in
            if let err = err {
                print("ユーザー情報の取得に失敗しました。 \(err)")
                HUD.hide { (_) in
                    HUD.flash(.error, delay: 1)
                }
                return
            }
            
            guard let data = snapshot?.data() else { return }
            let user = User.init(dic: data)
            
            print("ユーザー情報の取得ができました。 \(user.name)")
            HUD.hide { (_) in
                HUD.flash(.success, onView: self.view, delay: 1) { (_) in
                    self.presentToWelcomeViewController(user: user)
                }
                
            }
            
        }
    }
     
    private func presentToWelcomeViewController(user: User) {
        let storyBoard = UIStoryboard(name: "Welcome", bundle: nil)
        let welcomeViewController = storyBoard.instantiateViewController(identifier: "WelcomeViewController") as! WelcomeViewController
        welcomeViewController.user = user
        welcomeViewController.modalPresentationStyle = .fullScreen
        self.present(welcomeViewController, animated: true, completion: nil)
    }
    
    private var locationManager: CLLocationManager = {
        var locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        return locationManager
    }()
    
    var beaconRegion : CLBeaconRegion!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupNotificationObserver()
        let uuid:UUID? = UUID(uuidString: "BA104F92-2CF9-DFA4-6D2A-328DA3804C0E")
        beaconRegion = CLBeaconRegion(uuid: uuid!, identifier: "BeaconApp")
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        Timer.scheduledTimer(timeInterval: 10, target: self,
                             selector: #selector(self.updateTime),
                             userInfo: nil, repeats: true)
    }

    var timeflag = 0
    var resultflag: Int = 0 {
        didSet {
            updatesituation()
        }
    }
    
    let starttimer = "12:58:00"
    let starttimer2 = "12:59:00"
    let secondtimer = "13:28:00"
    let secondtimer2 = "13:29:00"
    let lasttimer = "13:58:00"
    let lasttimer2 = "13:59:00"
    let resettimer = "14:00:00"
    
    func updatesituation() {
        guard let uid2 = Auth.auth().currentUser?.uid else { return }
        if resultflag == 1 || resultflag == 3 {
            print("早退")
            Firestore.firestore().collection("users").document(uid2).updateData([
                "attendance": "早退"
            ]) { (err) in
                if let err = err {
                    print("Firestoreの更新に失敗しました。 \(err)")
                }
                return
            }
            
        } else if resultflag == 2 || resultflag == 4 || resultflag == 6 {
            print("遅刻")
            Firestore.firestore().collection("users").document(uid2).updateData([
                "attendance": "遅刻"
            ]) { (err) in
                if let err = err {
                    print("Firestoreの更新に失敗しました。 \(err)")
                }
                return
            }
        } else if resultflag == 7 {
            print("出席")
            Firestore.firestore().collection("users").document(uid2).updateData([
                "attendance": "出席"
            ]) { (err) in
                if let err = err {
                    print("Firestoreの更新に失敗しました。 \(err)")
                }
                return
            }
        }
    }
     
    func datemanagement() {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone  = TimeZone.current
        dateFormatter.locale  = Locale.current
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZZ"
        let dateForTime: Date? = dateFormatter.date(from: Date().description)
        if let date: Date = dateForTime {
            dateFormatter.dateFormat = "HH:mm:ss"
            print(dateFormatter.string(from: date))
            if starttimer <= dateFormatter.string(from: date) && starttimer2 >= dateFormatter.string(from: date) {
                if timeflag == 0 {
                    timeflag = timeflag + 1
                    print("timeflag:",timeflag)
                }
            }
            if secondtimer <= dateFormatter.string(from: date) && secondtimer2 >= dateFormatter.string(from: date) {
                if timeflag == 0 || timeflag == 1 {
                    timeflag = timeflag + 2
                    print("timeflag:",timeflag)
                }
            }
            if lasttimer <= dateFormatter.string(from: date) && lasttimer2 >= dateFormatter.string(from: date) {
                if timeflag == 0 || timeflag == 1 || timeflag == 2 || timeflag == 3  {
                    timeflag = timeflag + 4
                    print("timeflag:",timeflag)
                }
            }
            if resettimer == dateFormatter.string(from: date) {
                timeflag = 0
                print("timeflag:",timeflag)
            }
        }
    }

    @objc func updateTime() {
        datemanagement()
    }
 
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }
    
    private func pushToLoginViewController() {
        let storyBoard = UIStoryboard(name: "Login", bundle: nil)
        let welcomeViewController = storyBoard.instantiateViewController(identifier: "LoginViewController") as! LoginViewController
        navigationController?.pushViewController(welcomeViewController, animated: true)
    }
    
    private func setupViews() {
        //RegisterButtonの角を丸にする
        registerButton.layer.cornerRadius = 10
        registerButton.isEnabled = false
        registerButton.backgroundColor = UIColor.rgb(red: 255, green: 221, blue: 187)
        emailTextField.delegate = self
        passwordTextField.delegate = self
        usernameTextField.delegate = self
    }
    
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(showKeyboard), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector:  #selector (hideKeyboard), name: UIResponder.keyboardDidHideNotification, object: nil)
    }
    
    @objc func showKeyboard(notification: Notification) {
        let keyboardFrame = (notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as AnyObject).cgRectValue
        guard let keyboardMinY = keyboardFrame?.minY else { return }
        let registerButtonMaxY = registerButton.frame.maxY
        let distance = registerButtonMaxY - keyboardMinY + 20
        let transform = CGAffineTransform(translationX: 0, y: -distance)
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [], animations: {
            self.view.transform = transform
        })
    }
    
    @objc func hideKeyboard() {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [], animations: {
            self.view.transform = .identity
        })
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        locationManager.delegate = self
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()
            locationManager.startMonitoring(for: self.beaconRegion)
            break
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
            break
        case .denied:
            break
        case .restricted:
            break
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        locationManager.requestState(for: self.beaconRegion)
    }
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for inRegion: CLRegion) {
        switch (state) {
        case .inside:
            self.locationManager.startRangingBeacons(satisfying: self.beaconRegion.beaconIdentityConstraint)
            break
        case .outside:
            break
        case .unknown:
            break
            
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        self.locationManager.startRangingBeacons(satisfying: self.beaconRegion.beaconIdentityConstraint)
        print("測定を開始しました。")
    }
        
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        self.locationManager.stopRangingBeacons(satisfying: self.beaconRegion.beaconIdentityConstraint)
        print("測定を終了しました。")
    }
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion){
        if timeflag == 1 {
            if beacons.count > 0 {
                if resultflag == 0 {
                    resultflag = resultflag + 1
                    print("resultflag",resultflag)
                }
            }
        }
        
        if timeflag == 2 || timeflag == 3 {
            if beacons.count > 0 {
                if resultflag == 0 || resultflag == 1 {
                    resultflag = resultflag + 2
                    print("resultflag",resultflag)
                }
            }
        }
        
        if timeflag == 4 || timeflag == 5 || timeflag == 6 || timeflag == 7{
            if beacons.count > 0 {
                if resultflag == 0 || resultflag == 1 || resultflag == 2 || resultflag == 3  {
                    resultflag = resultflag + 4
                    print("resultflag",resultflag)
                }
            }
        }
    }
}

extension ViewController: UITextFieldDelegate {
    func textFieldDidChangeSelection(_ textField: UITextField) {
        let emailIsEmpty = emailTextField.text?.isEmpty ?? true
        let passwordIsEmpty = passwordTextField.text?.isEmpty ?? true
        let usernameIsEmpty = usernameTextField.text?.isEmpty ?? true
        if emailIsEmpty || passwordIsEmpty || usernameIsEmpty {
            registerButton.isEnabled = false
            registerButton.backgroundColor = UIColor.rgb(red: 255, green: 221, blue: 187)
        } else {
            registerButton.isEnabled = true
            registerButton.backgroundColor = UIColor.rgb(red: 255, green: 141, blue: 0)
        }
    }
}






