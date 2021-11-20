//
//  PaymentViewController.swift
//  Kakeibo
//
//  Created by 近藤大伍 on 2021/10/15.
//

import UIKit
import FirebaseFirestore

class PaymentViewController: UIViewController{
    
    
    @IBOutlet weak var paymentConfirmedButton: UIButton!
    @IBOutlet weak var paymentNameTextField: UITextField!
    @IBOutlet weak var paymentDayTextField: UITextField!
    @IBOutlet weak var categoryTextField: UITextField!
    @IBOutlet weak var priceTextField: UITextField!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var resetButton: UIButton!
    
    var db = Firestore.firestore()
    var groupID = String()
    var userID = String()
    let dateFormatter = DateFormatter()
    var paymentDay = Date()
    var year = String()
    var month = String()
    var textFieldCalcArray = [Int]()
    
    var buttonAnimatedModel = ButtonAnimatedModel(withDuration: 0.1, delay: 0.0, options: UIView.AnimationOptions.curveEaseIn, transform: CGAffineTransform(scaleX: 0.95, y: 0.95), alpha: 0.7)
    
    var pickerViewOfPaymentDay = UIDatePicker()
    var pickerViewOfCategory = UIPickerView()
    let categoryArray = ["食費", "水道代", "電気代", "ガス代", "通信費","家賃","その他"]
    var valueOfCategory = String()
    var valueOfPaymentDay = String()
    var today = Int()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        priceTextField.delegate = self
        
        paymentConfirmedButton.addTarget(self, action: #selector(touchDown(_:)), for: .touchDown)
        paymentConfirmedButton.addTarget(self, action: #selector(touchUpOutside(_:)), for: .touchUpOutside)
        paymentConfirmedButton.layer.shadowOffset = CGSize(width: 1, height: 1)
        paymentConfirmedButton.layer.shadowOpacity = 0.5
        paymentConfirmedButton.layer.shadowRadius = 1
        paymentConfirmedButton.layer.cornerRadius = 5
        
        resetButton.layer.cornerRadius = 5
        
        let calendar = Calendar(identifier: .gregorian)
        let date = calendar.dateComponents([.year,.month], from: Date())
        year = String(date.year!)
        month = String(date.month!)
        //金額入力を数字のみに指定
        let toolberOfPrice = UIToolbar()
        toolberOfPrice.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 44)
        let buttonItemOfPrice = UIBarButtonItem(title: "合計金額に反映する", style: .done, target: self, action: #selector(self.doneButtonOfPrice))
        let flexibleItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace,target: nil, action: nil)
        
        toolberOfPrice.setItems([flexibleItem,buttonItemOfPrice,flexibleItem], animated: true)
        priceTextField.inputAccessoryView = toolberOfPrice
        priceTextField.keyboardType = UIKeyboardType.numberPad
        makePickerView()
        paymentDayTextField.text = dateFormatter.string(from: Date())
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        priceLabel.text = ""
        
        let calendar = Calendar(identifier: .gregorian)
        let date = calendar.dateComponents([.year,.month], from: Date())
        year = String(date.year!)
        month = String(date.month!)
        groupID = UserDefaults.standard.object(forKey: "groupID") as! String
        userID = UserDefaults.standard.object(forKey: "userID") as! String
        
    }
    
    @objc func touchDown(_ sender:UIButton){
        buttonAnimatedModel.startAnimation(sender: sender)
        paymentConfirmedButton.layer.shadowOffset = CGSize(width: 0, height: 0)
        paymentConfirmedButton.layer.shadowOpacity = 0
        paymentConfirmedButton.layer.shadowRadius = 0
    }
    
    @objc func touchUpOutside(_ sender:UIButton){
        buttonAnimatedModel.endAnimation(sender: sender)
        paymentConfirmedButton.layer.shadowOffset = CGSize(width: 1, height: 1)
        paymentConfirmedButton.layer.shadowOpacity = 0.5
        paymentConfirmedButton.layer.shadowRadius = 1
    }
    
    @IBAction func paymentConfirmedButton(_ sender: Any) {
        buttonAnimatedModel.endAnimation(sender: sender as! UIButton)
        paymentConfirmedButton.layer.shadowOffset = CGSize(width: 1, height: 1)
        paymentConfirmedButton.layer.shadowOpacity = 0.5
        paymentConfirmedButton.layer.shadowRadius = 1
        
        dateFormatter.dateFormat = "yyyy年MM月dd日"
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        print(paymentDayTextField.text)
        paymentDay = dateFormatter.date(from: "\(paymentDayTextField.text!)")!
        
        if priceLabel.text?.isEmpty == false {
            db.collection("paymentData").document().setData([
                "paymentAmount" : Int(priceLabel.text!)!,
                "productName" : paymentNameTextField.text!,
                "paymentDay" : paymentDay as Date,
                "category" : categoryTextField.text!,
                "userID" : userID,
                "groupID" : groupID
            ])
            
            dismiss(animated: true, completion: nil)
        }else{
            //空だった場合の処理をお願いします
            //ここに来たのは２回目です。elseの処理がわかりません。お願いします。
            //支払名、カテゴリなどが空だったらどうしましょうか。時間が無いので先進みます。
        }
        
    }
    
    @IBAction func resetButton(_ sender: Any) {
        priceTextField.text = ""
        priceLabel.text = ""
        textFieldCalcArray = []
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        paymentDayTextField.text = dateFormatter.string(from: pickerViewOfPaymentDay.date)
        paymentDayTextField.endEditing(true)
    }
    
}

// MARK: - PickerView
extension PaymentViewController: UIPickerViewDelegate,UIPickerViewDataSource{
    
    func makePickerView(){
        
        pickerViewOfCategory.delegate = self
        pickerViewOfCategory.dataSource = self
        
        categoryTextField.inputView = pickerViewOfCategory
        let toolbarOfCategory = UIToolbar()
        toolbarOfCategory.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 44)
        //        let buttonItemOfCategory = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.doneButtonOfCategory))
        let buttonItemOfCategory = UIBarButtonItem(title: "決定", style: .done, target: self, action: #selector(self.doneButtonOfCategory))
        toolbarOfCategory.setItems([buttonItemOfCategory], animated: true)
        categoryTextField.inputAccessoryView = toolbarOfCategory
        dateFormatter.dateFormat = "yyyy年MM月dd日"
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        pickerViewOfPaymentDay.preferredDatePickerStyle = .wheels
        pickerViewOfPaymentDay.datePickerMode = .date
        pickerViewOfPaymentDay.locale = Locale(identifier: "ja_JP")
        
        paymentDayTextField.inputView = pickerViewOfPaymentDay
        let toolbarOfPaymentDay = UIToolbar()
        toolbarOfPaymentDay.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 44)
        let buttonItemOfPaymentDay = UIBarButtonItem(title: "決定", style: .done, target: self, action: #selector(self.doneButtonOfPaymentDay))
        toolbarOfPaymentDay.setItems([buttonItemOfPaymentDay], animated: true)
        paymentDayTextField.inputAccessoryView = toolbarOfPaymentDay
        
        today = getOfToday()
        print(UserDefaults.standard.object(forKey: "settlementDay"))
        let settlementDayString = UserDefaults.standard.object(forKey: "settlementDay") as! String
        let settlementDay = Int(settlementDayString)
        dateOfselection(today: today, settelement: settlementDay!) { maxDate, minDate in
            print("\(maxDate):\(minDate)")
            let maxDate = dateFormatter.date(from: maxDate)
            let minDate = dateFormatter.date(from: minDate)
            pickerViewOfPaymentDay.maximumDate = maxDate
            pickerViewOfPaymentDay.minimumDate = minDate
        }
        
    }
    
    @objc func doneButtonOfCategory(){
        categoryTextField.endEditing(true)
        
    }
    @objc func doneButtonOfPaymentDay(){
        paymentDayTextField.text = dateFormatter.string(from: pickerViewOfPaymentDay.date)
        paymentDayTextField.endEditing(true)
    }
    
    @objc func doneButtonOfPrice(){
        priceTextField.resignFirstResponder()
        if let num:Int = Int(priceTextField.text!){
            textFieldCalcArray.append(num)
            print(num)
        }
        priceLabel.text = "\(textFieldCalcArray.reduce(0){ $0 + $1 })"
        priceTextField.text = ""
    }
    
    func getOfToday() -> Int{
        let calendar = Calendar(identifier: .gregorian)
        let date = calendar.dateComponents([.day], from: Date())
        let today = date.day!
        return today
    }
    
    func dateOfselection(today: Int,settelement: Int,completion:(String,String) -> ()){
        var minimumDate = String()
        var maximumDate = String()
        let numOfMonth = Int(month)
        if today <= settelement{
            maximumDate = "\(year)年\(month)月\(settelement)日"
            if numOfMonth == 1{
                minimumDate = "\(year)年12月\(settelement)日"
            }else{
                minimumDate = "\(year)年\(numOfMonth! - 1)月\(settelement)日"
            }
            completion(maximumDate,minimumDate)
        }else if today >= settelement{
            minimumDate = "\(year)年\(month)月\(settelement)日"
            if numOfMonth == 12{
                maximumDate = "\(year)年1月\(settelement)日"
            }else{
                maximumDate = "\(year)年\(numOfMonth! + 1)月\(settelement)日"
            }
            completion(maximumDate,minimumDate)
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return categoryArray.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        categoryTextField.text = categoryArray[row]
        return categoryArray[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.categoryTextField.text = categoryArray[row]
    }
    
}

// MARK: - UITextFieldDelegate
extension PaymentViewController: UITextFieldDelegate{
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if let num:Int = Int(textField.text!){
            textFieldCalcArray.append(num)
            print(num)
        }
        priceLabel.text = "\(textFieldCalcArray.reduce(0){ $0 + $1 })"
        textField.text = ""
        return true
    }
    
}

extension PaymentViewController{
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion)
        guard let presentationController = presentationController else {
            return
        }
        presentationController.delegate?.presentationControllerDidDismiss?(presentationController)
    }
}
