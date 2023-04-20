import UIKit
import SwiftChart
import TinyConstraints
import CoreData

class ChartsViewController: UIViewController {
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    var incomes: [Income]?
    var weekIncome: ([Double], [Double]) = ([],[])
    
    @IBOutlet weak var headingLabel: UILabel!
    @IBOutlet weak var chartsLegendView: UIView!
    @IBOutlet weak var chartsView: UIView!
    @IBOutlet weak var buttonsView: UIView!
    @IBOutlet weak var weekButton: UIButton!
    @IBOutlet weak var monthButton: UIButton!
    @IBOutlet weak var quarterButton: UIButton!
    @IBOutlet weak var allButton: UIButton!
    
    @IBOutlet weak var axisXLabel1: UILabel!
    @IBOutlet weak var axisXLabel2: UILabel!
    @IBOutlet weak var axisXLabel3: UILabel!
    
    let sberGreenColor: UIColor = .init(red: 48/255, green: 175/255, blue: 95/255, alpha: 1.0)
    let expensesColor: UIColor = .systemOrange
    let accentColor: UIColor = .white
    let chartAttributesColor: UIColor = .darkGray
    
    var currentChart = Chart()
    
    func buttonTapped(_ tappedButton: UIButton) {
        let buttons: [UIButton] = [weekButton, monthButton, quarterButton, allButton]
        for button in buttons {
            button.layer.cornerRadius = button.frame.size.height/2
            button.tintColor = accentColor
            button.setTitleColor(sberGreenColor, for: .normal)
        }
        
        tappedButton.setTitleColor(self.accentColor, for: .normal)
        UIView.animate(withDuration: 7, delay: 0, options: .allowAnimatedContent, animations: {tappedButton.tintColor = self.accentColor}, completion: {_ in tappedButton.tintColor = self.sberGreenColor})
    }
    
        
    
    
    
    
//    func generateChartsView(){
//        self.view.addSubview(generalView)
//            generalView.edgesToSuperview()
//
//        let gradientImageView = UIImageView()
//            gradientImageView.image = UIImage(named: "AccentGreen")
//            generalView.addSubview(gradientImageView)
//            gradientImageView.edges(to: view, insets: .bottom(300))
//
//        let headingLabel = UILabel()
//            headingLabel.text = "График доходов/расходов"
//            headingLabel.textColor = UIColor.white
//            headingLabel.font = headingLabel.font.withSize(25)
//            generalView.addSubview(headingLabel)
//            headingLabel.edges(to: view, excluding: .bottom, insets: .top(64) + .left(16) + .right(16))
//            headingLabel.height(48, relation: .equalOrLess, priority: .defaultLow)
//
//        generalView.addSubview(chartsView)
//            chartsView.layer.cornerRadius = 10.0
//            chartsView.layer.backgroundColor = CGColor(red:100, green:100, blue:100, alpha: 1)
//            chartsView.edges(to: view, insets: .top(128) + .bottom(165))
//
//        chart = weekChart()
//            chartsView.addSubview(chart)
//            chart.edges(to: view, excluding: .bottom, insets: .top(152) + .left(16) + .right(16))
//            chart.height(272, relation: .equalOrLess, priority: .defaultLow)
//            chart.gridColor = .lightGray
//
//        UIViewPropertyAnimator(duration: 3, dampingRatio: 0.4) {
//            self.chart.layoutIfNeeded()
//        }.startAnimation()
//    }

    override func viewDidLoad() {
        super.viewDidLoad()
        generateHeader()
        generateLegend()
        buttonTapped(weekButton)
        assignAxisXdates(7)

        weekIncome = incomePerWeek()
        currentChart = weekChart()
        chartsView.addSubview(currentChart)
//        chartsView.insertSubview(currentChart, at: 0)
        currentChart.edges(to: chartsView)
        UIViewPropertyAnimator(duration: 2, dampingRatio: 0.4) {
            self.currentChart.layoutIfNeeded()
        }.startAnimation()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
    }
    
    override func viewWillAppear(_ animated: Bool) {
    }

    func weekChart() -> Chart {
        let chartDays = weekIncome.0 //.map { Double($0) ?? 0.0 }
        let chartValues = weekIncome.1
        let maxValue = chartValues.max()
        var lastWeekIncomeData: [(x: Double, y: Double)] = []
        
        if chartValues.count > 0 {
            for each in 0...(chartValues.count-1) {
                let value = (x: chartDays[each], y: chartValues[each])
                lastWeekIncomeData.append(value)
            }
        }

        var lastWeekDays: [Double] = [] //Значения интервала последней календарной недели
        for days in 1...7 {
            let day = Date.init(timeIntervalSinceNow: Double(-7*60*60*24+(60*60*24*days)))
            lastWeekDays.append(Double(day.timeIntervalSince1970))
        }

        
        let lastWeekExpensesData = [
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
            chart.axesColor = .white
            chart.labelColor = chartAttributesColor
            chart.showXLabelsAndGrid = false
            chart.minY = 0
            chart.yLabelsOnRightSide = true
            chart.yLabels = valueLabels
            chart.yLabelsFormatter = { String(Int(round($1))) }
            chart.gridColor = chartAttributesColor

        let series1 = ChartSeries(data: lastWeekIncomeData)
            //series1.area = true
            series1.color = sberGreenColor
        let series2 = ChartSeries(data: lastWeekExpensesData)
            series2.color = expensesColor

        chart.add(series1)
        chart.add(series2)

        return chart
    }
    
//    func incomeData(_ timeInterval: Int)
    
    func incomePerWeek() -> ([Double], [Double]) { //Доходы за неделю
        fetchIncomes()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd"
        var result: [Double] = []
        var days: [Double] = []
        var day: String = ""
        if let incomes {
            for income in incomes {
                if income.date! > Date.init(timeIntervalSinceNow: Double(-7*60*60*24)) {
                    if dateFormatter.string(from: income.date!) == day { //Условие нужно, чтобы складывать доходы, полученные в один день
                        result[result.endIndex - 1] += income.rate
                    } else {
                        day = dateFormatter.string(from: income.date!)
                        result.append(income.rate)
                        days.append(Double(income.date!.timeIntervalSince1970))
                    }
                }
            }
        }
        return (days, result)
    }
    
    func assignAxisXdates (_ amountOfdays: Int) /*-> [String] */ { //Подписывает координаты оси X
        var dates: [Date] = []
        dates.append(Date.init(timeIntervalSinceNow: Double(-amountOfdays*60*60*24)))
        dates.append(Date.init(timeIntervalSinceNow: Double(-amountOfdays/2*60*60*24)))
        dates.append(Date.init())
        
        let dateFormatterRu = DateFormatter()
        dateFormatterRu.locale = Locale(identifier: "ru_RU")
        //Получаем число-месяц, или год-месяц, если отрезок времени больше 100 дней
        if amountOfdays < 100 { dateFormatterRu.dateFormat = "dd MMM"
        } else { dateFormatterRu.dateFormat = "YY MMM" }
        
        
        var lastWeekDates: [String] = []
        for date in dates {
            lastWeekDates.append(String(dateFormatterRu.string(from: date)))
        }
       
        for (index, date) in lastWeekDates.enumerated() { //Обрезаем месяц до трёх знаков
            var shortDate = date
            shortDate.removeSubrange(date.index(date.startIndex, offsetBy: 6)..<date.endIndex)
            lastWeekDates[index] = shortDate
        }
        
        if amountOfdays >= 100 { //Меняем год и месяц местами
            for (index, date) in lastWeekDates.enumerated() {
                var yearCut = date
                yearCut.removeSubrange(date.index(date.startIndex, offsetBy: 2)..<date.endIndex)
                var monthCut = date
                monthCut.removeSubrange(date.startIndex..<(date.index(date.endIndex, offsetBy: -3)))
                lastWeekDates[index] = "\(monthCut) \(yearCut)"
            }
        }
        
        let axisXLabels: [UILabel] = [self.axisXLabel1, self.axisXLabel2, self.axisXLabel3]
        for (index, label) in axisXLabels.enumerated() {
            label.backgroundColor = UIColor.clear
            label.textColor = chartAttributesColor
            label.text = lastWeekDates[index]
        }
        //return lastWeekDates
    }
    
    func fetchIncomes() {
        do {
            let request = Income.fetchRequest() as NSFetchRequest<Income>
            let sort = NSSortDescriptor(key: "date", ascending: false)
            request.sortDescriptors = [sort]
            self.incomes = try self.context.fetch(request)
        } catch { print (error) }
    }
    
    func generateHeader() {
        headingLabel.text = "График доходов/расходов"
        headingLabel.textColor = UIColor.white
    }
    
    func generateLegend() {
        chartsLegendView.layer.cornerRadius = 10.0
        chartsLegendView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        let expensesLine = UIView()
            expensesLine.backgroundColor = expensesColor
            expensesLine.layer.cornerRadius = 1.5
        let incomeLine = UIView()
            incomeLine.backgroundColor = sberGreenColor
            incomeLine.layer.cornerRadius = 1.5
        let expensesLabel = UILabel()
            expensesLabel.text = "Расходы"
            expensesLabel.textAlignment = .center
            expensesLabel.textColor = .black
            expensesLabel.font = expensesLabel.font.withSize(19)
        let incomeLabel = UILabel()
            incomeLabel.text = "Доходы"
            incomeLabel.textAlignment = .center
            incomeLabel.textColor = .black
            incomeLabel.font = incomeLabel.font.withSize(19)
        chartsLegendView.addSubview(expensesLine)
        chartsLegendView.addSubview(incomeLine)
        chartsLegendView.addSubview(expensesLabel)
        chartsLegendView.addSubview(incomeLabel)
        
        expensesLine.height(3)
        expensesLine.width(78)
        incomeLine.height(3)
        incomeLine.width(72)
        expensesLabel.height(32)
        expensesLabel.width(96)
        incomeLabel.height(32)
        incomeLine.width(96)
        expensesLabel.center(in: chartsLegendView, offset: CGPoint(x: 52, y: 0))
        incomeLabel.center(in: chartsLegendView, offset: CGPoint(x: -52, y: 0))
        expensesLine.center(in: expensesLabel, offset: CGPoint(x: 0, y: 16))
        incomeLine.center(in: incomeLabel, offset: CGPoint(x: 0, y: 16))
    }
}
