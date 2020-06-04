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

        chart.delegate = self

        chart.chartDescription?.enabled = false

        chart.isUserInteractionEnabled = false

        chart.leftAxis.drawLabelsEnabled = false
        chart.legend.enabled = false

        chart.minOffset = 0

        chart.xAxis.drawGridLinesEnabled = false
        chart.leftAxis.drawGridLinesEnabled = false
        chart.leftAxis.axisMinimum = 0

        chart.xAxis.enabled = false
        chart.leftAxis.enabled = false


        let xAxis = chart.xAxis
        xAxis.labelPosition = .bottom

        chart.rightAxis.enabled = false
        chart.xAxis.drawLabelsEnabled = false

        var yVals: [BarChartDataEntry] = []
        var x: Double = 0
        if let domainsOverTime = networkOverview?.piholes["pi-hole.local"]?.overTimeData?.domainsOverTime,
            let adsOverTime = networkOverview?.piholes["pi-hole.local"]?.overTimeData?.adsOverTime {
            let sorted = domainsOverTime.sorted { $0.key < $1.key }
            for (key, value) in sorted {
                let entry = BarChartDataEntry(x: x, yValues: [Double(adsOverTime[key]!), Double(value)])
                yVals.append(entry)
                x += 1
            }
        }

        if yVals.isEmpty { return }

        var set1: BarChartDataSet! = nil
        if let set = chart.data?.dataSets.first as? BarChartDataSet {
            set1 = set
            set1.replaceEntries(yVals)
            chart.data?.notifyDataChanged()
            chart.notifyDataSetChanged()
        } else {
            set1 = BarChartDataSet(entries: yVals)
            set1.label = "Queries Over Time"
            set1.colors = [.clear, .systemRed]

            let data = BarChartData(dataSet: set1)
            data.barWidth = 1.2
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

extension NetworkOverviewView: ChartViewDelegate {

}
