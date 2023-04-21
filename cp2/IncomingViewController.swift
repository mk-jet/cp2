import UIKit
import CoreData

class IncomingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var incomes: [Income]?
    var expenses: [Expense]?
    var categories: [Category]?
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var currentBalanceLabel: UILabel!
    @IBOutlet weak var incomesView: UIView!
    @IBOutlet weak var incomesLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        deleteStoredData() // < удаляет сохраненные данные
        setTestData() // < создаёт тестовые данные
        setViewOptions()
        fetchIndexData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        fetchIndexData()
    }
    
    // Добавляет необходимые штрихи на экран
    func setViewOptions() {
        incomesView.layer.cornerRadius = 10.0
        incomesView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        incomesLabel.text = "Доходы:"
        currentBalanceLabel.textColor = .white
    }
    
    // Получает/обновляет данные расходов и доходов
    func fetchIndexData() {
        do {
            let request = Income.fetchRequest() as NSFetchRequest<Income>
            let sort = NSSortDescriptor(key: "date", ascending: false)
            request.sortDescriptors = [sort]
            self.incomes = try self.context.fetch(request)
            self.expenses = try self.context.fetch(Expense.fetchRequest())
            self.categories = try context.fetch(Category.fetchRequest())
        } catch { print (error) }
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.updateBalance()
        }
    }
    
    // Данные для таблицы
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "IncomingTableViewCell", for: indexPath) as! IncomingTableViewCell
        cell.dateLabel.text = formatDate(self.incomes![indexPath.row].date ?? Date.init())
        cell.rateLabel.text = formatRate(round(self.incomes![indexPath.row].rate))
        return cell
    }
    
    // Удаляет строку дохода
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .destructive, title: "Удалить") { (action, view, completionHandler) in
            let incomeToRemove = self.incomes![indexPath.row]
            self.context.delete(incomeToRemove)
            try! self.context.save()
            self.fetchIndexData()
        }
        return UISwipeActionsConfiguration(actions: [action])
    }
    
    // Добавляет доход по нажатию на кнопку
    @IBAction func addIncome(_ sender: Any) {
        let addingAlert = UIAlertController(title: "Добавить доход", message: "Введите сумму", preferredStyle: .alert)
        addingAlert.addTextField { (textField:UITextField) in
            textField.keyboardType = UIKeyboardType.numberPad
            textField.placeholder = "₽"
            textField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: .editingChanged)
        }
        
        let cancelButton = UIAlertAction(title: "Отменить", style: .cancel)
        submitButton = UIAlertAction(title: "Добавить", style: .default) { (action) in
            let textField = addingAlert.textFields![0]
            if let value = textField.text {
                if let rate = Double(value) {
                    let newIncome = Income(context: self.context)
                        newIncome.date = Date.init()
                        newIncome.rate = rate
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
    // Переменная и метод, необходимые, чтобы добавить можно было только число.
    private var submitButton: UIAlertAction!
    @objc private func textFieldDidChange(_ field: UITextField) { submitButton.isEnabled = Double(field.text ?? "0") ?? 0 > 0 }
    
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
    
    // Преобразовывает дату в привычный глазу вид
    func formatDate (_ incomingDate: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.YYYY"
        let dateString = dateFormatter.string(from: incomingDate)
        return dateString
    }
    
    // Считает-обновляет баланс
    func updateBalance() {
        var sum = 0.0
        if let incomes { for each in incomes { sum += each.rate} }
        if let expenses { for each in expenses { sum -= each.rate }  }
        currentBalanceLabel.text = "Баланс: \(formatRate(sum))"
    }
    
    // Стандартные опции для таблицы
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return self.incomes?.count ?? 0  }
    func numberOfSections(in tableView: UITableView) -> Int { return 1 }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { tableView.deselectRow(at: indexPath, animated: true)  }
    
    // MARK: - Функции для тестирования приложения
    
    // Удалает все данные хранилища
    func deleteStoredData () {
        fetchIndexData()
        // Удаляет доходы
        if let incomes {
            for each in incomes {
                self.context.delete(each)
                do { try self.context.save() } catch { print (error) }
            }
        }
        // Удаляет расходы
        if let expenses {
            for each in expenses {
                self.context.delete(each)
                do { try self.context.save() } catch { print (error) }
            }
        }
        // Удаляет категории
        if let categories {
            for each in categories {
                self.context.delete(each)
                do { try self.context.save() } catch { print(error) }
            }
        }
    }
    
    //Создаёт базу с тестовыми значениями
    func setTestData() {
        // Доходы в течение года
        for days in  1...334 {
            if days.isMultiple(of: 10) {
                let newIncome = Income(context: self.context)
                let date = Date.init(timeIntervalSinceNow: Double(-365*60*60*24+(60*60*24*days)))
                newIncome.date = date
                let rate = round(Double.random(in: 5...100))*1000
                newIncome.rate = rate
                do { try self.context.save() } catch { print (error) }
            }
        }
        // Доходы за последний месяц
        for days in  1...24 {
            if days.isMultiple(of: 3) {
                let newIncome = Income(context: self.context)
                newIncome.date = Date.init(timeIntervalSinceNow: Double(-31*60*60*24+(60*60*24*days)))
                newIncome.rate = round(Double.random(in: 5...100))*1000
                do { try self.context.save() } catch { print (error) }
            }
        }
        // Доходы за последнюю неделю
        for days in 1...7 { //Последняя неделя
            let newIncome = Income(context: self.context)
            newIncome.date = Date.init(timeIntervalSinceNow: Double(-7*60*60*24+(60*60*24*days)))
            newIncome.rate = round(Double.random(in: 5...100))*1000
            do { try self.context.save() } catch { print (error) }
        }
        
        // Создаёт категории расходов и записи в них
        let categoryNames = ["Дом", "Продукты", "Досуг", "Постоянные траты", "Отпуск"]
        let expensesNames = ["Лампочки", "Стулья", "Мелкий ремонт", "Дрель", "Ручка", "Цветы", "Мусорные пакеты", "Бумага",
                             "Бананы", "Мясо", "Рыба", "Сок", "Апельсины", "Морковь", "Картофель", "Курица",
                             "Игры для PS", "Ресторан", "Гости", "Концерт", "Кино", "Сериалы", "Музыка", "Спорт",
                             "Кредит за дом", "Кредит за авто", "Оплата за свет", "Оплата за ЖКХ", "Учёба", "Проезд", "Бензин", "Ремонт авто",
                             "Билеты", "Отель", "Транспорт", "Сувениры", "Экскурсии", "Прокат авто", "Еда", "Одежда"]
        for index in 0...4 {
            let category = Category(context: self.context)
            category.name = categoryNames[index]
            // Для простоты примеров и наглядности в графиках, платежи ближе к текущей дате – чаще.
            for days in  1...334 {
                if days.isMultiple(of: 10) {
                    let newExpense = Expense(context: self.context)
                    let date = Date.init(timeIntervalSinceNow: Double(-365*60*60*24+(60*60*24*(days-index))))
                    newExpense.date = date
                    let rate = round(Double.random(in: 1...19))*1000
                    newExpense.rate = rate
                    let num = Int.random(in: 0...7) + (index * 8)
                    newExpense.designation = expensesNames[num]
                    newExpense.category = category
                    do { try self.context.save() } catch { print (error) }
                }
            }
            // Последний месяц
            for days in  1...24 {
                if days.isMultiple(of: 3) {
                    let newExpense = Expense(context: self.context)
                    newExpense.date = Date.init(timeIntervalSinceNow: Double(-31*60*60*24+(60*60*24*days)))
                    newExpense.rate = round(Double.random(in: 1...19))*1000
                    newExpense.designation = expensesNames[(Int.random(in: 0...7) + (index * 8))]
                    newExpense.category = category
                    do { try self.context.save() } catch { print (error) }
                }
            }
            //Последняя неделя
            for days in 1...7 {
                let newExpense = Expense(context: self.context)
                newExpense.date = Date.init(timeIntervalSinceNow: Double(-7*60*60*24+(60*60*24*days)))
                newExpense.rate = round(Double.random(in: 5...19))*1000
                newExpense.designation = expensesNames[(Int.random(in: 0...7) + (index * 8))]
                newExpense.category = category
                do { try self.context.save() } catch { print (error) }
            }
        }
    }
}

