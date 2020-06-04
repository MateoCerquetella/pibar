//
//  NetworkOverviewView.swift
//  PiBar for iOS
//
//  Created by Brad Root on 6/2/20.
//  Copyright © 2020 Brad Root. All rights reserved.
//

import UIKit
import Charts

class NetworkOverviewView: UIView {

    weak var manager: PiBarManager?

    @IBOutlet var totalQueriesLabel: UILabel!
    @IBOutlet var blockedQueriesLabel: UILabel!
    @IBOutlet var networkStatusLabel: UILabel!
    @IBOutlet var avgBlocklistLabel: UILabel!

    @IBOutlet var disableButton: UIButton!
    @IBOutlet var viewQueriesButton: UIButton!

    @IBOutlet var chart: BarChartView!

    @IBAction func disableButtonAction(_ sender: UIButton) {
        let seconds = sender.tag > 0 ? sender.tag : nil
        Log.info("Disabling via Menu for \(String(describing: seconds)) seconds")
        manager?.disableNetwork(seconds: seconds)
    }

    var networkOverview: PiholeNetworkOverview? {
        didSet {
            DispatchQueue.main.async {
                guard let networkOverview = self.networkOverview else { return }
                self.totalQueriesLabel.text = networkOverview.totalQueriesToday.string
                self.blockedQueriesLabel.text = networkOverview.adsBlockedToday.string
                self.networkStatusLabel.text = networkOverview.networkStatus.rawValue
                self.avgBlocklistLabel.text = networkOverview.averageBlocklist.string
                self.createChart()
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        disableButton.layer.cornerRadius = disableButton.frame.height / 2
        viewQueriesButton.layer.cornerRadius = viewQueriesButton.frame.height / 2

        let maskLayer = CAShapeLayer()
        maskLayer.path = UIBezierPath(roundedRect: bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 38.5, height: 38.5)).cgPath
        layer.mask = maskLayer
        clipsToBounds = true

    }

    func createChart() {
        // Chart setup
        chart.chartDescription?.enabled = false
        chart.isUserInteractionEnabled = false
        chart.leftAxis.drawLabelsEnabled = false
        chart.legend.enabled = false
        chart.minOffset = 0
        chart.xAxis.drawGridLinesEnabled = false
        chart.leftAxis.drawGridLinesEnabled = false
        chart.leftAxis.axisMinimum = 0
        chart.leftAxis.drawAxisLineEnabled = false
        chart.xAxis.drawAxisLineEnabled = false
        chart.xAxis.enabled = false
        chart.leftAxis.enabled = false
        let xAxis = chart.xAxis
        xAxis.labelPosition = .bottom
        chart.rightAxis.enabled = false
        chart.xAxis.drawLabelsEnabled = false

        // Chart Data
        var yVals: [BarChartDataEntry] = []

        guard let dataOverTime = networkOverview?.overTimeData, !dataOverTime.overview.isEmpty else { return }

        let sorted = dataOverTime.overview.sorted { $0.key < $1.key }

        for (key, value) in sorted {
            let entry = BarChartDataEntry(x: key, yValues: [value.0, value.1])
            yVals.append(entry)
        }

        if yVals.isEmpty { return }

        var set1: BarChartDataSet! = nil
        if let set = chart.data?.dataSets.first as? BarChartDataSet {
            set1 = set
            set1.replaceEntries(yVals)
            chart.leftAxis.axisMaximum = dataOverTime.maximumValue
            chart.data?.notifyDataChanged()
            chart.notifyDataSetChanged()
        } else {
            set1 = BarChartDataSet(entries: yVals)
            set1.label = "Queries Over Time"
            set1.colors = [UIColor(named: "red") ?? .systemRed, .darkGray]
            set1.drawValuesEnabled = false

            chart.leftAxis.axisMaximum = dataOverTime.maximumValue

            let data = BarChartData(dataSet: set1)
            data.barWidth = 0.8
            chart.data = data
        }
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
