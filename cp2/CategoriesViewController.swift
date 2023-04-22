import UIKit
import CoreData

class CategoriesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var categories: [Category]?
    var expenses: [Expense]?
    var incomes: [Income]?
    
    @IBOutlet weak var currentBalanceLabel: UILabel!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var expensesCategoryLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    let sberGreenColor: UIColor = .init(red: 48/255, green: 175/255, blue: 95/255, alpha: 1.0)
    let accentColor: UIColor = .white
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        setViewOptions()
        fetchIndexData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        fetchIndexData()
    }
    
    // Передаёт в расходы имяКатогории и раскрывает новый VC на весь экран
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let cell = sender as? UITableViewCell, let index = tableView.indexPath(for: cell), let controllerToSwitch = segue.destination as? ExpensesViewController, segue.identifier == "showExpensesSegue" {
            controllerToSwitch.modalPresentationStyle = .fullScreen
            controllerToSwitch.category = categories?[index.row]
            tableView.deselectRow(at: index, animated: true)
        }
    }
    
    // Данные для таблицы
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoriesTableViewCell", for: indexPath) as! CategoriesTableViewCell
        if categories != nil {
            cell.categoryLabel.text = self.categories![indexPath.row].name
        } else { cell.categoryLabel.text = "Empty yet"}
        return cell
    }
    
    // Удаляет категорию расхода
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .destructive, title: "Удалить") { (action, view, completionHandler) in
            let categoryToRemove = self.categories![indexPath.row]
            self.context.delete(categoryToRemove)
            do { try self.context.save() } catch { print (error) }
            self.fetchIndexData()
        }
        // Проверяет, есть ли в категории записи.
        var categoryExpenses: [Expense]?
        do {
            let request = Expense.fetchRequest() as NSFetchRequest<Expense>
            let pred = NSPredicate(format: "category.name CONTAINS %@", categories![indexPath.row].name ?? "None")
            request.predicate = pred
            categoryExpenses = try self.context.fetch(request)
        } catch { print (error) }
        // Непустую категорию удалять нельзя.
        return categoryExpenses!.isEmpty ? UISwipeActionsConfiguration(actions: [action]) : nil
    }
    
    // Добавляет необходимые штрихи на экран
    func setViewOptions() {
        currentBalanceLabel.textColor = accentColor
        expensesCategoryLabel.text = "Категории расходов"
        headerView.layer.cornerRadius = 10.0
        headerView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
    }
    
    // Добавляет категории
    @IBAction func addCategoryButtonTapped(_ sender: Any) {
        print("Button tapped")
        let addingAlert = UIAlertController(title: "Добавить категорию расходов", message: nil, preferredStyle: .alert)
        addingAlert.addTextField { (textField:UITextField) in
            textField.keyboardType = UIKeyboardType.alphabet
            textField.placeholder = "Введите название"
            textField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: .editingChanged)
        }
        let cancelButton = UIAlertAction(title: "Отменить", style: .cancel)
        submitButton = UIAlertAction(title: "Добавить", style: .default) { (action) in
            let textField = addingAlert.textFields![0]
            if let value = textField.text {
                let newCategory = Category(context: self.context)
                newCategory.name = value
                do { try self.context.save() } catch { print (error) }
                self.fetchIndexData()
            }
        }
        submitButton.isEnabled = false
        addingAlert.addAction(cancelButton)
        addingAlert.addAction(submitButton)
        self.present(addingAlert, animated: true, completion: nil)
    }
    //Переменная и метод, необходимые, чтобы добавить можно было только уникальное название
    private var submitButton: UIAlertAction!
    @objc private func textFieldDidChange(_ field: UITextField) {
        var nameUnique = true
        if categories != nil && field.text != nil {
            for category in categories! {
                if category.name == field.text {
                    nameUnique = false
                }
            }
        }
        submitButton.isEnabled = field.text?.count ?? 0 > 0 && nameUnique
    }
    
    // Получает/обновляет данные расходов и доходов
    func fetchIndexData() {
        do {
            self.incomes = try context.fetch(Income.fetchRequest())
            self.expenses = try context.fetch(Expense.fetchRequest())
            self.categories = try context.fetch(Category.fetchRequest())
            DispatchQueue.main.async {
                self.updateBalance()
                self.tableView.reloadData()
            }
        } catch { print (error) }
    }
    
    // Считает-обновляет баланс
    func updateBalance() {
        var sum = 0.0
        if let incomes { for each in incomes { sum += each.rate} }
        if let expenses { for each in expenses { sum -= each.rate }  }
        currentBalanceLabel.text = "Баланс: \(formatRate(sum))"
    }
    
    // Для удобства чтения, разбивает число на куски по три символа и добавляет знак валюты
    func formatRate (_ oldRate: Double) -> String {
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
    
    // Стандартные опции для таблицы
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { categories?.count ?? 0 }
    func numberOfSections(in tableView: UITableView) -> Int { return 1 }
}
