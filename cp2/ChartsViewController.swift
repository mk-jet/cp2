import UIKit
import SwiftChart
import TinyConstraints
import CoreData

class ChartsViewController: UIViewController {
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var incomes: [Income]?
    var expenses: [Expense]?
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var chartsLegendView: UIView!
    @IBOutlet weak var chartsView: UIView!
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

    override func viewDidLoad() {
        super.viewDidLoad()
        setViewOptions()
        buttonTapped(weekButton, 7)
    }
    
    // Нажата кнопка "1Н"
    @IBAction func weekButtonTapped(_ sender: Any) {
        buttonTapped(weekButton, 7)
    }
    
    // Нажата кнопка "1М"
    @IBAction func monthButtonTapped(_ sender: Any) {
        buttonTapped(monthButton, 30)
    }
    
    // Нажата кнопка "1К"
    @IBAction func quarterButtonTapped(_ sender: Any) {
        buttonTapped(quarterButton, 91)
    }
    
    // Нажата кнопка "Все"
    @IBAction func allButtonTapped(_ sender: Any) {
        buttonTapped(allButton, daysToFirstRecord())
    }
    
    // Меняет график в соотвествие нажатой кнопке
    func buttonTapped(_ tappedButton: UIButton, _ timeInterval: Int) {
        let buttons: [UIButton] = [weekButton, monthButton, quarterButton, allButton]
        for button in buttons {
            button.layer.cornerRadius = button.frame.size.height/2
            button.tintColor = accentColor
            button.setTitleColor(sberGreenColor, for: .normal)
        }
        tappedButton.setTitleColor(self.accentColor, for: .normal)
        DispatchQueue.main.async {
            UIViewPropertyAnimator(duration: 1, dampingRatio: 0.4) {
                tappedButton.tintColor = self.sberGreenColor
                self.currentChart.removeFromSuperview()
                self.currentChart = self.buildChart(timeInterval)
                self.chartsView.addSubview(self.currentChart)
                self.currentChart.edges(to: self.chartsView)
                self.chartsView.layoutIfNeeded()
            }.startAnimation()
        }
    }
    
    // Строит графики доходов и расходов в рамках заданного временного интервала
    func buildChart(_ timeInterval: Int) -> Chart {
        let incomeValues = chartData(timeInterval).incomeValues
        let expenseValues = chartData(timeInterval).expenseValues
        // Получает максимально возможное значение для графика
        let maxValue = (incomeValues.max() ?? 0) > (expenseValues.max() ?? 0) ? incomeValues.max() : expenseValues.max()
        // Получает точки для графиков доходов и расходов
        var incomeData: [(x: Double, y: Double)] = []
        if incomeValues.count > 0 {
            for index in 0...(incomeValues.count-1) {
                let point = (x: chartData(timeInterval).incomeDates[index], y: incomeValues[index])
                incomeData.append(point)
            }
        }
        var expenseData: [(x: Double, y: Double)] = []
        if expenseValues.count > 0 {
            for index in 0...(expenseValues.count-1) {
                let point = (x: chartData(timeInterval).expenseDates[index], y: expenseValues[index])
                expenseData.append(point)
            }
        }
        // Костыль, получает координаты для невидимого графика, чтобы нужные графики не растягивались по всей ширине
        var allDatesData: [(x: Double, y: Double)] = []
        if chartData(timeInterval).allDates.count > 0 {
            for index in 0...(chartData(timeInterval).allDates.count-1) {
                let point = (x: chartData(timeInterval).allDates[index], y: (maxValue ?? 0.0)/2)
                allDatesData.append(point)
            }
        }
        // Получает  округлённые значения для подписи оси Y
        var valueLabels: [Double] = []
        if let maxY = maxValue {
            for divider in 1...5 {
                let label = ((maxY*1.1)/Double(5)*Double(divider))
                valueLabels.append(round(label/1000)*1000)
            }
        }
        // Прописывает аттрибуты графиков
        let chart = Chart()
            chart.axesColor = .white
            chart.labelColor = chartAttributesColor
            chart.showXLabelsAndGrid = false
            chart.minY = 0
            chart.yLabelsOnRightSide = true
            chart.yLabels = valueLabels
            chart.yLabelsFormatter = { String(Int(round($1))) }
            chart.gridColor = chartAttributesColor
        let series0 = ChartSeries(data: allDatesData)
            series0.color = .clear
        let series1 = ChartSeries(data: incomeData)
            series1.color = sberGreenColor
        let series2 = ChartSeries(data: expenseData)
            series2.color = expensesColor
        // Добавляет линии на график
        chart.add(series0)
        chart.add(series1)
        chart.add(series2)
        
        //Метод подписывает координаты оси X, три значения: первый день, середина отрезка, и сегодняшний день. Если меньше 100 дней - число_месяц, больше - месяц_год. У SwiftChart это выглядит жутковато.
        func assignAxisXdates () {
            var dates: [Date] = []
            dates.append(Date.init(timeIntervalSinceNow: Double(-timeInterval*60*60*24)))
            dates.append(Date.init(timeIntervalSinceNow: Double(-timeInterval/2*60*60*24)))
            dates.append(Date.init())
            
            let dateFormatterRu = DateFormatter()
            dateFormatterRu.locale = Locale(identifier: "ru_RU")
            //Получает число-месяц, или год-месяц, если отрезок времени больше 100 дней
            if timeInterval < 100 { dateFormatterRu.dateFormat = "dd MMM"
            } else { dateFormatterRu.dateFormat = "YY MMM" }
            var datesData: [String] = []
            for date in dates {
                datesData.append(String(dateFormatterRu.string(from: date)))
            }
            // Обрезает название месяца до трёх знаков
            for (index, date) in datesData.enumerated() {
                var shortDate = date
                shortDate.removeSubrange(date.index(date.startIndex, offsetBy: 6)..<date.endIndex)
                datesData[index] = shortDate
            }
            // Для больших периодов меняет год и месяц местами
            if timeInterval >= 100 {
                for (index, date) in datesData.enumerated() {
                    var yearCut = date
                    yearCut.removeSubrange(date.index(date.startIndex, offsetBy: 2)..<date.endIndex)
                    var monthCut = date
                    monthCut.removeSubrange(date.startIndex..<(date.index(date.endIndex, offsetBy: -3)))
                    if monthCut == "мая" { monthCut = "май" } // 22 мая, но май 22-го
                    datesData[index] = "\(monthCut) \(yearCut)"
                }
            }
            // Подписывет этикетки
            let axisXLabels: [UILabel] = [self.axisXLabel1, self.axisXLabel2, self.axisXLabel3]
            for (index, label) in axisXLabels.enumerated() {
                label.backgroundColor = UIColor.clear
                label.textColor = chartAttributesColor
                label.text = datesData[index]
            }
        }
        assignAxisXdates()
        return chart
    }
    
    //Получает количество дней для построения графика, и возвращает доходы и расходы тех дней, в которых есть начисления. Вместо дат получаем координаты 1..n для SwiftChart, т.к. он не умеет в даты. ВсеДаты тоже нужны, чтобы устаканить SwiftChart.
    func chartData(_ timeInterval: Int) -> (incomeDates: [Double], incomeValues: [Double], expenseDates: [Double], expenseValues: [Double], allDates: [Double]) {
        var incomeDates: [Double] = []
        var incomeValues: [Double] = []
        var expenseDates: [Double] = []
        var expenseValues: [Double] = []
        var allDates: [Double] = []
        let today = Date.init()
        let dateFormatter = DateFormatter()
        var counter = 0.0
        fetchData()
        // Данные за неделю и месяц разбиваются по дням
        if timeInterval < 32 {
            dateFormatter.dateFormat = "YYMMdd"
            for day in (-timeInterval+1)...(0) {
                let timeCode = dateFormatter.string(from: Calendar.current.date(byAdding: .day, value: day, to: today)!)
                getIndexData(timeCode)
            }
        // Данные за квартал разбиваются по неделям
        } else if timeInterval >= 32 && timeInterval < 100 {
            dateFormatter.dateFormat = "YYww"
            for week in (-11)...(0) {
                let timeCode = dateFormatter.string(from: Calendar.current.date(byAdding: .weekOfYear, value: week, to: today)!)
                getIndexData(timeCode)
            }
        // Данные за всё время разбиваются по месяцам
        } else {
            dateFormatter.dateFormat = "YYMM"
            for month in monthsToFirstRecord()...(0) {
                let timeCode = dateFormatter.string(from: Calendar.current.date(byAdding: .month, value: month, to: today)!)
                getIndexData(timeCode)
            }
        }
        
        // Метод возвращает доходы и расходы, соответствующие заданному тайм-коду
        func getIndexData(_ timeCode: String) {
            var value = 0.0
            if let incomeData = self.incomes {
                for income in incomeData {
                    if dateFormatter.string(from: income.date!) == timeCode {
                        value += income.rate
                    }
                }
            }
            counter += 1
            if value != 0 {
                incomeDates.append(counter)
                incomeValues.append(value)
            }
            
            value = 0.0
            if let expenseData = self.expenses {
                for expense in expenseData {
                    if dateFormatter.string(from: expense.date!) == timeCode {
                        value += expense.rate
                    }
                }
            }
            if value != 0 {
                expenseDates.append(counter)
                expenseValues.append(value)
            }
            allDates.append(counter)
        }
        // Получает разницу в месяцах между сегодняшней датой и самой ранней записью в реестре доходов-расходов
        func monthsToFirstRecord() -> Int {
            var earliestDate = today
            if let incomeData = self.incomes {
                for income in incomeData {
                    if income.date! < earliestDate {
                        earliestDate = income.date!
                    }
                }
            }
            if let expenseData = self.expenses {
                for expense in expenseData {
                    if expense.date! < earliestDate {
                        earliestDate = expense.date!
                    }
                }
            }
            let monthComponent: Set<Calendar.Component> = [.month]
            let monthDifference = Calendar.current.dateComponents(monthComponent, from: earliestDate, to: today)
            return (-(Int(String(format: "%02d", monthDifference.month ?? 0)) ?? 0))
        }
        return (incomeDates, incomeValues, expenseDates, expenseValues, allDates)
    }
    
    // Получает/обновляет данные расходов и доходов
    func fetchData() {
        do {
            let incomeRequest = Income.fetchRequest() as NSFetchRequest<Income>
            let expenseRequest = Expense.fetchRequest() as NSFetchRequest<Expense>
            let sort = NSSortDescriptor(key: "date", ascending: false)
            incomeRequest.sortDescriptors = [sort]
            expenseRequest.sortDescriptors = [sort]
            self.incomes = try self.context.fetch(incomeRequest)
            self.expenses = try self.context.fetch(expenseRequest)
        } catch { print(error) }
    }
    // Добавляет необходимые штрихи на экран с графиками
    func setViewOptions() {
        headerLabel.text = "График доходов/расходов"
        headerLabel.textColor = UIColor.white
        
        chartsLegendView.layer.cornerRadius = 10.0
        chartsLegendView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        let expensesLine = UIView()
            expensesLine.backgroundColor = expensesColor
            expensesLine.layer.cornerRadius = 1.5
        let incomeLine = UIView()
            incomeLine.backgroundColor = sberGreenColor
            incomeLine.layer.cornerRadius = 1.5
        let expensesLabel = UILabel()
            expensesLabel.text = "расходы"
            expensesLabel.textAlignment = .center
            expensesLabel.textColor = chartAttributesColor//.black
            expensesLabel.font = expensesLabel.font.withSize(12)
        let incomeLabel = UILabel()
            incomeLabel.text = "доходы"
            incomeLabel.textAlignment = .center
            incomeLabel.textColor = chartAttributesColor//.black
            incomeLabel.font = incomeLabel.font.withSize(12)
        chartsLegendView.addSubview(expensesLine)
        chartsLegendView.addSubview(incomeLine)
        chartsLegendView.addSubview(expensesLabel)
        chartsLegendView.addSubview(incomeLabel)
        
        expensesLine.height(2)
        expensesLine.width(48)
        incomeLine.height(2)
        incomeLine.width(48)
        expensesLabel.height(32)
        expensesLabel.width(96)
        incomeLabel.height(32)
        incomeLabel.width(96)
        expensesLabel.center(in: chartsLegendView, offset: CGPoint(x: 52, y: 0))
        incomeLabel.center(in: chartsLegendView, offset: CGPoint(x: -52, y: 0))
        expensesLine.center(in: expensesLabel, offset: CGPoint(x: 0, y: 10))
        incomeLine.center(in: incomeLabel, offset: CGPoint(x: 0, y: 10))
    }
    
    // Возвращает количество дней между датой первой записи в реестре доходов-расходов и сегодняшним днём
    func daysToFirstRecord() -> Int {
        var earliestDate = Date.init()
        if let incomeData = self.incomes {
            for income in incomeData {
                if income.date! < earliestDate {
                    earliestDate = income.date!
                }
            }
        }
        if let expenseData = self.expenses {
            for expense in expenseData {
                if expense.date! < earliestDate {
                    earliestDate = expense.date!
                }
            }
        }
        let dayComponent: Set<Calendar.Component> = [.day]
        let dayDifference = Calendar.current.dateComponents(dayComponent, from: earliestDate, to: Date.init())
        return (Int(String(format: "%02d", dayDifference.day ?? 0)) ?? 0) == 0 ? 1 : (Int(String(format: "%02d", dayDifference.day ?? 0)) ?? 0)
    }
}
