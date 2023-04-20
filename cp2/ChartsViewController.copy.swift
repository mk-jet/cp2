import UIKit
import SwiftChart
import TinyConstraints
import CoreData

class ChartsViewController: UIViewController {
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    var incomes: [Income]?
    var weekIncome: ([Double], [String]) = ([],[])
    
    let chartsView = UIView()
    let generalView = UIView()
    var chart = Chart()

    func generateChartsView(){
        self.view.addSubview(generalView)
            generalView.edgesToSuperview()

        let gradientImageView = UIImageView()
            gradientImageView.image = UIImage(named: "AccentGreen")
            generalView.addSubview(gradientImageView)
            gradientImageView.edges(to: view, insets: .bottom(300))

        let headingLabel = UILabel()
            headingLabel.text = "График доходов/расходов"
            headingLabel.textColor = UIColor.white
            headingLabel.font = headingLabel.font.withSize(25)
            generalView.addSubview(headingLabel)
            headingLabel.edges(to: view, excluding: .bottom, insets: .top(64) + .left(16) + .right(16))
            headingLabel.height(48, relation: .equalOrLess, priority: .defaultLow)

        generalView.addSubview(chartsView)
            chartsView.layer.cornerRadius = 10.0
            chartsView.layer.backgroundColor = CGColor(red:100, green:100, blue:100, alpha: 1)
            chartsView.edges(to: view, insets: .top(128) + .bottom(165))
        
        chart = weekChart()
            chartsView.addSubview(chart)
            chart.edges(to: view, excluding: .bottom, insets: .top(152) + .left(16) + .right(16))
            chart.height(272, relation: .equalOrLess, priority: .defaultLow)

        UIViewPropertyAnimator(duration: 3, dampingRatio: 0.4) {
            self.chart.layoutIfNeeded()
        }.startAnimation()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.weekIncome = incomePerWeek()
        self.generateChartsView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        fetchIncomes()
        generalView.removeFromSuperview()
        generateChartsView()
        UIViewPropertyAnimator(duration: 2, dampingRatio: 0.4) {
            self.chart.layoutIfNeeded()
        }.startAnimation()
    }

    func chartsBackLines() {
//        let chartDays = ChartSeries(
    }

    func weekChart() -> Chart {
        let chartValues = weekIncome.0
        let chartDays = weekIncome.1.map { Double($0) ?? 0.0 }
        let maxValue = chartValues.max()
        var lastWeekIncomeData: [(x: Double, y: Double)] = []
        if chartValues.count > 0 {
            for each in 0...(chartValues.count-1) {
                let value = (x: chartDays[each], y: chartValues[each])
                lastWeekIncomeData.append(value)
            }
        }

        var lastWeekDays: [Double] = [] //Числа последней календарной недели
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd"
        for days in 1...7 {
            let day = Date.init(timeIntervalSinceNow: Double(-7*60*60*24+(60*60*24*days)))
            lastWeekDays.append(Double(dateFormatter.string(from: day)) ?? 0.0)
        }
        
        let lastWeekOutcomeData = [
            (x: lastWeekDays[0], y: 35000.0),
            (x: lastWeekDays[2], y: 3000.0),
            (x: lastWeekDays[4], y: 45000.0),
            (x: lastWeekDays[5], y: 5000.0)
        ]

        var valueLabels: [Double] = []
        if let maxY = maxValue {
            for divider in 1...5 {
                let label = ((maxY*1.1)/Double(5)*Double(divider))
                valueLabels.append(round(label/1000)*1000)
            }
        }

        let chart = Chart()
            chart.xLabels = lastWeekDays
            chart.xLabelsFormatter = { String(Int(round($1))) }
            chart.minY = 0
            chart.yLabelsOnRightSide = true
            chart.yLabels = valueLabels
            chart.yLabelsFormatter = { String(Int(round($1))) }

        let series1 = ChartSeries(data: lastWeekIncomeData)
//          series1.area = true
            series1.color = .systemGreen

        let series2 = ChartSeries(data: lastWeekOutcomeData)
            series2.color = .orange

        chart.add(series1)
        chart.add(series2)

        return chart
    }
    
    func incomePerWeek() -> ([Double], [String]) { //Доходы за неделю
        fetchIncomes()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd"
        var result: [Double] = []
        var days: [String] = []
        var day: String = ""
        if let incomes {
            for income in incomes {
                if income.date! > Date.init(timeIntervalSinceNow: Double(-7*60*60*24)) {
                    if dateFormatter.string(from: income.date!) == day { //Условие нужно, чтобы складывать суммы доходов, полученных в один день
                        result[result.endIndex - 1] += income.rate
                    } else {
                        day = dateFormatter.string(from: income.date!)
                        result.append(income.rate)
                        days.append(day)
                    }
                }
            }
        }
        return (result, days)
    }
    
    func fetchIncomes() {
        do {
            let request = Income.fetchRequest() as NSFetchRequest<Income>
            let sort = NSSortDescriptor(key: "date", ascending: false)
            request.sortDescriptors = [sort]
            self.incomes = try self.context.fetch(request)
        } catch { print (error) }
    }
}
