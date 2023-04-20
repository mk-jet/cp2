import UIKit
import CoreData

class ExpensesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var category: Category?
    var expenses: [Expense]?
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var buttonsView: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 15.0, *) { tableView.sectionHeaderTopPadding = 0.0 }
        tableView.dataSource = self
        tableView.delegate = self
        setViewOptions()
        fetchIndexData()
    }
    
    func setViewOptions() {
        headerLabel.text = category?.name ?? "Empty"
        headerLabel.textColor = .white
        buttonsView.layer.cornerRadius = 10.0
        buttonsView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
    }
    
    // Передаёт для графика имяКатогории и раскрывает новый VC на весь экран
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controllerToSwitch = segue.destination as? ExpensesChartsViewController, segue.identifier == "showExpensesChartsSegue" {
            controllerToSwitch.modalPresentationStyle = .fullScreen
            controllerToSwitch.category = self.category
        }
    }
    
    // Данные для таблицы
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ExpensesTableViewCell", for: indexPath) as! ExpensesTableViewCell
        if expenses != nil {
            cell.designationLabel.text = self.expenses![indexPath.row].designation
            cell.dateLabel.text = formatDate(self.expenses![indexPath.row].date!)
            cell.rateLabel.text = formatRate(self.expenses![indexPath.row].rate)
        } //else { cell.dateLabel.text = "Empty yet"}
        return cell
    }
    
    // Стандартные опции для таблицы
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return self.expenses?.count ?? 0  }
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) { tableView.deselectRow(at: indexPath, animated: true) }
    func numberOfSections(in tableView: UITableView) -> Int { return 1 }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { return 12 }
    
    // Подписывает колонки таблицы
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ExpensesTableViewCell") as! ExpensesTableViewCell
        cell.dateLabel.text = "Когда?"
        cell.dateLabel.font = .systemFont(ofSize: 12)
        cell.dateLabel.textColor = .lightGray
        cell.designationLabel.text = "На что?"
        cell.designationLabel.font = .systemFont(ofSize: 12)
        cell.designationLabel.textColor = .lightGray
        cell.rateLabel.text = "Сколько?"
        cell.rateLabel.font = .systemFont(ofSize: 12)
        cell.rateLabel.textColor = .lightGray
        return cell
        }
    
    // Удаляет строку расхода
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .destructive, title: "Удалить") { (action, view, completionHandler) in
            let incomeToRemove = self.expenses![indexPath.row]
            self.context.delete(incomeToRemove)
            try! self.context.save()
            self.fetchIndexData()
        }
        return UISwipeActionsConfiguration(actions: [action])
    }
    
    // Получает/обновляет данные расходов для категории
    func fetchIndexData() {
        do {
            let request = Expense.fetchRequest() as NSFetchRequest<Expense>
            let sort = NSSortDescriptor(key: "date", ascending: false)
            let pred = NSPredicate(format: "category.name CONTAINS %@", category?.name ?? "None")
            request.predicate = pred
            request.sortDescriptors = [sort]
            self.expenses = try self.context.fetch(request)
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        } catch { print (error) }
    }

    // Добавляет расход
    @IBAction func addButton(_ sender: Any) {
        let addingAlert = UIAlertController(title: "Добавить расход", message: "", preferredStyle: .alert)
        addingAlert.addTextField { (designationTextField: UITextField) in
            designationTextField.keyboardType = UIKeyboardType.alphabet
            designationTextField.placeholder = "Наименование платежа"
            designationTextField.addTarget(self, action: #selector(self.designationFieldDidChange(_:)), for: .editingChanged)
        }
        
        addingAlert.addTextField { (rateTextField: UITextField) in
            rateTextField.keyboardType = UIKeyboardType.numberPad
            rateTextField.placeholder = "Сумма"
            rateTextField.addTarget(self, action: #selector(self.rateFieldDidChange(_:)), for: .editingChanged)
        }
        let cancelButton = UIAlertAction(title: "Отменить", style: .cancel)
        submitButton = UIAlertAction(title: "Добавить", style: .default) { (action) in
            let textField = addingAlert.textFields!//[0]
            if let designation = textField[0].text {
                if let rate = Double(textField[1].text ?? "0") {
                    let newExpense = Expense(context: self.context)
                        newExpense.date = Date.init()
                        newExpense.designation = designation
                        newExpense.rate = rate
                        newExpense.category = self.category
                    print(newExpense)
                    try! self.context.save()
                    self.fetchIndexData()
                }
            }
        }
        submitButton.isEnabled = false
        addingAlert.addAction(cancelButton)
        addingAlert.addAction(submitButton)
        self.present(addingAlert, animated: true, completion: nil)
    }
    // Переменные и методы для проверки, что сумма в диалоге - это число, а наименование – не пустое
    private var submitButton: UIAlertAction!
    private var designationIsFine = false
    private var rateIsFine = false
    @objc private func designationFieldDidChange(_ field: UITextField) {
        if field.text?.count ?? 0 > 0 { designationIsFine = true } else { designationIsFine = false}
        submitButton.isEnabled = designationIsFine && rateIsFine
    }
    @objc private func rateFieldDidChange(_ field: UITextField) {
        if Double(field.text ?? "0") ?? 0 > 0 { rateIsFine = true } else { rateIsFine = false }
        submitButton.isEnabled = designationIsFine && rateIsFine
    }
    
    // Преобразовывает дату в привычный глазу вид
    func formatDate (_ incomingDate: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.YY"
        let dateString = dateFormatter.string(from: incomingDate)
        return dateString
    }
    
    // Для удобства чтения, разбивает число на куски по три символа и добавляет знак валюты
    func formatRate (_ oldRate: Double) -> String { // Для удобства чтения, разбивает число на куски по три символа и добавляет знак валюты
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
    
    // Вернуться к категориям
    @IBAction func backButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
