import UIKit
import CoreData

class IncomingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var incomes: [Income]?
    @IBOutlet weak var currentBalanceLabel: UILabel!
    
    var incomingTableView = UITableView()
//    var currentBalanceLabel = UILabel()
    var incomingView = UIView()
//    var allIncomes = Ambry.shared.allIncomes()
    
    func generateIncomingView(){
        incomingView = UIView(frame: CGRect(x:0, y:0, width:view.frame.size.width, height: view.frame.size.height))
        
        let gradientImageView = UIImageView(frame: CGRect(x:0, y:0, width: view.frame.size.width, height:view.frame.size.height/3))
            gradientImageView.image = UIImage(named: "AccentGreen")
        incomingView.addSubview(gradientImageView)
        
//        currentBalanceLabel = UILabel(frame: CGRect(x: 16, y:24, width: view.frame.size.width-32, height: 116))
            currentBalanceLabel.text = "Баланс:  \(prepareRate(sumOfIncomes()))"
            currentBalanceLabel.textColor = UIColor.white
            currentBalanceLabel.font = currentBalanceLabel.font.withSize(25)
            currentBalanceLabel.adjustsFontSizeToFitWidth = true
        incomingView.addSubview(currentBalanceLabel)
        
        let financeView = UIView(frame: CGRect(x:0, y:117, width:view.frame.size.width, height: view.frame.size.height-82))
            financeView.layer.cornerRadius = 10.0
            financeView.layer.backgroundColor = CGColor(red:100, green:100, blue:100, alpha: 1)
        incomingView.addSubview(financeView)
        
        let incomingLabel = UILabel(frame: CGRect(x:16, y:8, width:view.frame.size.width-72, height: 48))
            incomingLabel.text = "Доходы:"
            incomingLabel.textColor = .black
            incomingLabel.font = incomingLabel.font.withSize(25)
        financeView.addSubview(incomingLabel)
        
        let addIncomingButton = UIButton(frame: CGRect(x: view.frame.size.width-40, y: 20, width: 24, height: 24))
            let addIncomingButtonImage = UIImage(named: "addIncomingButton") as UIImage?
            addIncomingButton.setBackgroundImage(addIncomingButtonImage, for: UIControl.State.normal)
            addIncomingButton.addTarget(self, action: #selector(self.addIncomingButtonAction), for: .touchUpInside)
        financeView.addSubview(addIncomingButton)
        
        incomingTableView = UITableView(frame: CGRect(x:0, y:57, width: view.frame.size.width-16, height:CGFloat(incomes?.count ?? 0)*48+5))
        incomingTableView.register(IncomingTableViewCell.self, forCellReuseIdentifier: "IncomingTableViewCell")
        incomingTableView.backgroundColor = .white
        incomingTableView.isEditing = false
        incomingTableView.dataSource = self
        incomingTableView.delegate = self
        incomingTableView.allowsSelection = true
        incomingTableView.allowsMultipleSelection = true
        incomingTableView.allowsSelectionDuringEditing = true
        incomingTableView.allowsMultipleSelectionDuringEditing = true
        incomingTableView.isUserInteractionEnabled = true
        financeView.addSubview(incomingTableView)
        
        incomingView.addSubview(financeView)
 
        self.view.addSubview(incomingView)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        fetchIncomes()
        DispatchQueue.main.async { self.generateIncomingView() }
    }
    
    
    
    func fetchIncomes() {
        DispatchQueue.main.async {
            self.incomes = try! self.context.fetch(Income.fetchRequest())
//            self.incomingTableView.reloadData()
//            self.currentBalanceLabel.layoutIfNeeded()
//            self.incomingTableView.layoutIfNeeded()
//            self.incomingView.layoutIfNeeded()
//            self.generateIncomingView()
        }
    }
    
    func sumOfIncomes () -> Double {
        fetchIncomes()
        var sum = 0.0
        if let incomes {
            for each in incomes {
                sum += each.rate
            }
        }
        return sum
    }
    
    
//    override func viewWillAppear(_ animated: Bool) {
//       fetchIncomes()
//    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.incomes?.count ?? 0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int { return 1 }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { return  48 }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { // Не работает
        tableView.deselectRow(at: indexPath, animated: true)
//        print("didSelectRow", indexPath.row)
    }
    
//    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
//        return true
//    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "IncomingTableViewCell", for: indexPath) as! IncomingTableViewCell
        cell.incomingDate.text = prepareDate(self.incomes![indexPath.row].date ?? Date.init())
        cell.incomingRate.text = prepareRate(round(self.incomes![indexPath.row].rate))
        return cell
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? { // Для удаления строки дохода !
        let action = UIContextualAction(style: .destructive, title: "Удалить") { (action, view, completionHandler) in
            let incomeToRemove = self.incomes![indexPath.row]
            self.context.delete(incomeToRemove)
            try! self.context.save()
            self.fetchIncomes()
        }
        return UISwipeActionsConfiguration(actions: [action])
    }
    
    @objc func addIncomingButtonAction(sender: UIButton!) { // Кнопка добавления дохода
        print("Button tapped")
        let addingAlert = UIAlertController(title: "Добавить доход", message: "Введите сумму", preferredStyle: .alert)
        addingAlert.addTextField { (textField:UITextField) in textField.keyboardType = UIKeyboardType.numberPad }
        let cancelButton = UIAlertAction(title: "Отменить", style: .cancel)
        let submitButton = UIAlertAction(title: "Добавить", style: .default) { (action) in
            let textField = addingAlert.textFields![0]
            if let value = textField.text {
                if let rate = Double(value) {
                    let newIncome = Income(context: self.context)
                        newIncome.date = Date.init()
                        newIncome.rate = rate
                    try! self.context.save()
                    self.fetchIncomes()
                }
            }
        }
        addingAlert.addAction(cancelButton)
        addingAlert.addAction(submitButton)
        self.present(addingAlert, animated: true, completion: nil)
    }
    
    func prepareRate (_ oldRate: Double) -> String { // Для удобства чтения, разбивает число на куски по три символа и добавляет знак валюты
        var rate = String(round(oldRate))
        rate.remove(at: rate.index(before: rate.endIndex))
        rate.remove(at: rate.index(before: rate.endIndex))
        rate = String(rate.reversed())
        var newRate = ""
        for (i, char) in rate.enumerated() {
            if i.isMultiple(of: 3) && i != 0 {
                newRate += " " + String(char)
            } else {
                newRate += String(char)
            }
        }
        newRate = String(newRate.reversed())
        newRate += " ₽"
        return newRate
    }
    
    func prepareDate (_ incomingDate: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.YYYY"
        let dateString = dateFormatter.string(from: incomingDate)
        return dateString
    }
}

