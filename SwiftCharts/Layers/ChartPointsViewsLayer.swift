//
//  ChartPointsViewsLayer.swift
//  SwiftCharts
//
//  Created by ischuetz on 27/04/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit


public class ChartPointsViewsLayer<T: ChartPoint, U: UIView>: ChartPointsLayer<T> {

    typealias ChartPointViewGenerator = (chartPointModel: ChartPointLayerModel<T>, layer: ChartPointsViewsLayer<T, U>, chart: Chart) -> U?
    typealias ViewWithChartPoint = (view: U, chartPointModel: ChartPointLayerModel<T>)
    
    private(set) var viewsWithChartPoints: [ViewWithChartPoint] = []
    
    private let delayBetweenItems: Float = 0
    
    let viewGenerator: ChartPointViewGenerator
    
    private var conflictSolver: ChartViewsConflictSolver<T, U>?
    
    public init(xAxis: ChartAxisLayer, yAxis: ChartAxisLayer, innerFrame: CGRect, chartPoints:[T], viewGenerator: ChartPointViewGenerator, conflictSolver: ChartViewsConflictSolver<T, U>? = nil, displayDelay: Float = 0, delayBetweenItems: Float = 0) {
        self.viewGenerator = viewGenerator
        self.conflictSolver = conflictSolver
        super.init(xAxis: xAxis, yAxis: yAxis, innerFrame: innerFrame, chartPoints: chartPoints, displayDelay: displayDelay)
    }
    
    override func display(#chart: Chart) {
        super.display(chart: chart)
        
        self.viewsWithChartPoints = self.generateChartPointViews(chartPointModels: self.chartPointsModels, chart: chart)

        for (index, viewWithChartPoint) in enumerate(self.viewsWithChartPoints) {
            var view = viewWithChartPoint.view
            view.alpha = 0
            chart.addSubview(view)
            UIView.animateWithDuration(0, delay: NSTimeInterval(self.displayDelay) + NSTimeInterval(index) * NSTimeInterval(self.delayBetweenItems), options: .BeginFromCurrentState, animations: {
                view.alpha = 1
            }, completion: nil)
        }
    }
    
    private func generateChartPointViews(#chartPointModels: [ChartPointLayerModel<T>], chart: Chart) -> [ViewWithChartPoint] {
        let viewsWithChartPoints = self.chartPointsModels.reduce(Array<ViewWithChartPoint>()) {viewsWithChartPoints, model in
            if let view = self.viewGenerator(chartPointModel: model, layer: self, chart: chart) {
                return viewsWithChartPoints + [(view: view, chartPointModel: model)]
            } else {
                return viewsWithChartPoints
            }
        }
        
        self.conflictSolver?.solveConflicts(views: viewsWithChartPoints)
        
        return viewsWithChartPoints
    }
    
    override public func chartPointsForScreenLoc(screenLoc: CGPoint) -> [T] {
        return self.filterChartPoints{self.inXBounds(screenLoc.x, view: $0.view) && self.inYBounds(screenLoc.y, view: $0.view)}
    }
    
    override public func chartPointsForScreenLocX(x: CGFloat) -> [T] {
        return self.filterChartPoints{self.inXBounds(x, view: $0.view)}
    }
    
    override public func chartPointsForScreenLocY(y: CGFloat) -> [T] {
        return self.filterChartPoints{self.inYBounds(y, view: $0.view)}
    }
    
    private func filterChartPoints(filter: (ViewWithChartPoint) -> Bool) -> [T] {
        return self.viewsWithChartPoints.reduce([]) {arr, viewWithChartPoint in
            if filter(viewWithChartPoint) {
                return arr + [viewWithChartPoint.chartPointModel.chartPoint]
            } else {
                return arr
            }
        }
    }
    
    private func inXBounds(x: CGFloat, view: UIView) -> Bool {
        return (x > view.frame.origin.x) && (x < (view.frame.origin.x + view.frame.width))
    }
    
    private func inYBounds(y: CGFloat, view: UIView) -> Bool {
        return (y > view.frame.origin.y) && (y < (view.frame.origin.y + view.frame.height))
    }
}
