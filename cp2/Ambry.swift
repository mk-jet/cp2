import UIKit
import CoreData

//class Ambry{
//    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
//    var incomes: [Income]?
//
//    func fetchIncomes() { self.incomes = try! self.context.fetch(Income.fetchRequest()) }
//
//
//        func setTestInocomes() {
//            fetchIncomes()
//            for days in  1...334 {
//                if days.isMultiple(of: 10) {
//                    let newIncome = Income()
//                    newIncome.date = Date.init(timeIntervalSinceNow: Double(-365*60*60*24+(60*60*24*days)))
//                    newIncome.rate = round(Double.random(in: 5...100))*1000
//                    try! self.context.save()
//                }
//            }
//
//            for days in  1...24 {
//                if days.isMultiple(of: 3) {
//                    let newIncome = Income()
//                    newIncome.date = Date.init(timeIntervalSinceNow: Double(-31*60*60*24+(60*60*24*days)))
//                    newIncome.rate = round(Double.random(in: 5...100))*1000
//                    try! self.context.save()
//                }
//            }
//
//            for days in 1...7 { //Последняя неделя
//                let newIncome = Income()
//                newIncome.date = Date.init(timeIntervalSinceNow: Double(-7*60*60*24+(60*60*24*days)))
//                newIncome.rate = round(Double.random(in: 5...100))*1000
//                try! self.context.save()
//            }
//            fetchIncomes()
//        }
//
//    func deleteIncomes () {
//        fetchIncomes()
//        if let incomes {
//            for each in incomes {
//                self.context.delete(each)
//                try! self.context.save()
//            }
//        }
//        fetchIncomes()
//    }
//
//    let newIncome = Income(context: self.context)
//        newIncome.date = Date.init()
//        newIncome.rate = rate
//    try! self.context.save()
//    self.fetchIncomes()
    
//    func sumOfIncomes () -> Double {
//        var sum = 0.0
//        if let incomes {
//            for each in incomes { sum += each.rate  }
//        }
//        return sum
//    }
//}
//
//class Income: Object {
//    @Persisted var date: Date
//    @Persisted var rate: Double
//}
//
//class Ambry {
//    static let shared = Ambry()
//    private let income = try! Realm()
//
//    func addIncome(rate: Double) { // Внесение дохода
//        let newIncome = Income()
//        newIncome.date = Date.init()
//        newIncome.rate = rate
//        try! income.write{
//            income.add(newIncome)
//        }
//        ambryRefresh()
//    }
//
//    func deleteIncome(_ number: Int) {
//        try! income.write {
//            income.delete(income.objects(Income.self)[number])
//        }
//        ambryRefresh()
//    }
//
//    func allIncomes() -> [Income] { // Возвращает все доходы
//        ambryRefresh()
//        var incomesArray: [Income] = []
//        for record in income.objects(Income.self) {
//            incomesArray.append(record)
//        }
//        incomesArray.reverse()
//        return incomesArray
//    }
//
//    func sumOfIncomes() -> Double { // Сумма доходов
//        ambryRefresh()
//        var sum = 0.0
//        for record in income.objects(Income.self) {
//            sum += record.rate
//        }
//        return sum
//    }
//
//    func incomePerWeek() -> ([Double], [String]) { //Доходы за неделю
//        ambryRefresh()
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "dd"
//        var result: [Double] = []
//        var days: [String] = []
//        var day: String = ""
//        for record in income.objects(Income.self) {
//            if record.date > Date.init(timeIntervalSinceNow: Double(-6*60*60*24)) {
//                if dateFormatter.string(from: record.date) == day {
//                    result[result.endIndex - 1] += record.rate
//                } else {
//                    day = dateFormatter.string(from: record.date)
//                    result.append(record.rate)
//                    days.append(day)
//                }
//            }
//        } //Условие нужно для того, чтобы складывать суммы доходов, полученных в один день
//        return (result, days)
//    }
//
//
//
//    func ambryRefresh() {
//        DispatchQueue.main.async {
//            self.income.refresh()
//        }
//    }
//
//    func setTestInocomes() {
//        ambryRefresh()
//        for days in  1...334 {
//            if days.isMultiple(of: 10) {
//                let newIncome = Income()
//                newIncome.date = Date.init(timeIntervalSinceNow: Double(-365*60*60*24+(60*60*24*days)))
//                newIncome.rate = round(Double.random(in: 5...100))*1000
//                try! income.write{
//                    income.add(newIncome)
//                }
//            }
//        }
//
//        for days in  1...24 {
//            if days.isMultiple(of: 3) {
//                let newIncome = Income()
//                newIncome.date = Date.init(timeIntervalSinceNow: Double(-31*60*60*24+(60*60*24*days)))
//                newIncome.rate = round(Double.random(in: 5...100))*1000
//                try! income.write{
//                    income.add(newIncome)
//                }
//            }
//        }
//
//        for days in 1...7 { //Последняя неделя
//            let newIncome = Income()
//            newIncome.date = Date.init(timeIntervalSinceNow: Double(-7*60*60*24+(60*60*24*days)))
//            newIncome.rate = round(Double.random(in: 5...100))*1000
//            try! income.write{
//                income.add(newIncome)
//            }
//        }
//        ambryRefresh()
//    }
//
//    func deleteAllIncomes() {
//        ambryRefresh()
//        for record in income.objects(Income.self) {
//            try! income.write {
//                income.delete(record)
//            }
//        }
//        ambryRefresh()
//    }
//
//    func eraseBase(){
//        let realm = try! Realm()
//        try! realm.write {
//          realm.deleteAll()
//        }
//    }
//
//    func printIncome() {
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "dd.MM.YYYY"
//        for record in income.objects(Income.self) {
//            print("\(dateFormatter.string(from: record.date)) -  \(record.rate)")
//        }
//    }
//    //        try! FileManager.default.removeItem(at: Realm.Configuration.defaultConfiguration.fileURL!)
//}
