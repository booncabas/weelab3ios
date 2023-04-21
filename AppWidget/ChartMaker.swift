import Foundation
import SwiftUI

struct ChartMaker: View {
    var thresholdHigh : CGFloat
    var thresholdLow : CGFloat
    var dataSet : [CGFloat]
    var isAlarmActive: Bool

    var body: some View {
        GeometryReader { geometry in
            let frameSize = geometry.frame(in: .local)
            let boxPercentWidth: CGFloat = frameSize.width  / 100
            let fontSize1: CGFloat = boxPercentWidth * 5
            Canvas { context, size in
                var path = Path()
                let maxX: CGFloat = CGFloat(Float(frameSize.width * 0.94))
                let maxY: CGFloat = CGFloat(Float(frameSize.height))
                var THHigh: CGFloat = thresholdHigh
                var THLow: CGFloat = thresholdLow
                let lineColor: Color
                if (isAlarmActive){
                    lineColor = Color(red: 255 / 255, green: 0 / 255, blue: 0 / 255)
                }
                else{
                    lineColor = Color(red: 12 / 255, green: 229 / 255, blue: 64 / 255)
                }
                if (THLow > THHigh){
                    let aux1 = THHigh + 0
                    THHigh = THLow + 0
                    THLow = aux1 + 0
                }
                var limitMax: CGFloat = THHigh
                var limitMin: CGFloat = THLow
                let max = dataSet.max()!
                let min = dataSet.min()!
                if (max > THHigh){
                    limitMax = max
                }
                if(0 > limitMax){
                    limitMax = 0
                }
                if (min < THLow){
                    limitMin = min
                }
                if(0 < limitMin){
                    limitMin = 0
                }
                let step: CGFloat = maxX / CGFloat(dataSet.count - 1)
                var step2: CGFloat = 0.1//default first line
                let borderPercentage: CGFloat = maxY * 0.2
                let sizeUnit: CGFloat = (maxY * 0.6) / (limitMax - limitMin)
                
                /// TimeSeries
                path.move(to: CGPoint(x: 0, y: maxY - (borderPercentage +   (-((limitMin - (dataSet[0])) * sizeUnit))     )))
                for i in 0 ... (dataSet.count-1){
                    path.addLine(to: CGPoint(x: step2, y: maxY - (borderPercentage +   (-((limitMin - (dataSet[i])) * sizeUnit))     )  ))
                    path.move(to: CGPoint(x: step2, y: maxY - (borderPercentage +   (-((limitMin - (dataSet[i])) * sizeUnit))     )   ))
                    step2 = step * CGFloat((i + 1))
                }
                context.stroke(
                    path,
                    with: .color(lineColor),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )
                // #########################################
                ///Line High
                var path2 = Path()
                path2.move(to: CGPoint(x: CGFloat(0), y: CGFloat(maxY - (borderPercentage + ( -(limitMin - THHigh) * sizeUnit))) ))
                path2.addLine(to: CGPoint(x: maxX, y: CGFloat(maxY - (borderPercentage + ( -(limitMin - THHigh) * sizeUnit))) ))
                var style = StrokeStyle(lineWidth: 1)
                style.dash = [2, 3]
                context.stroke(
                    path2,
                    with: .color(Color.gray),
                    style: style
                )
                // #########################################
                ///Tip High
                context.draw(Text("➤").bold().foregroundColor(Color.gray).font(.system(size: fontSize1)), in: CGRect(x: maxX - (maxX * 0.035), y: CGFloat(maxY - (maxY * 0.13) - (borderPercentage + ( -(limitMin - THHigh) * sizeUnit))), width: boxPercentWidth * 3, height: maxY * 0.3))
                // #########################################
                ///Line Low
                var path3 = Path()
                path3.move(to: CGPoint(x: CGFloat(0), y: CGFloat(maxY - (borderPercentage + ( -(limitMin - THLow) * sizeUnit))) ))
                path3.addLine(to: CGPoint(x: maxX, y: CGFloat(maxY - (borderPercentage + ( -(limitMin - THLow) * sizeUnit))) ))
                context.stroke(
                    path3,
                    with: .color(Color.gray),
                    style: style
                )
                // #########################################
                ///Tip Low
                context.draw(Text("➤").bold().foregroundColor(Color.gray).font(.system(size: fontSize1)), in: CGRect(x: maxX - (maxX * 0.035), y: CGFloat(maxY - (maxY * 0.13) - (borderPercentage + ( -(limitMin - THLow) * sizeUnit))), width: boxPercentWidth * 3, height: maxY * 0.3))
                // #########################################
                ///Line zero
                var path4 = Path()
                path4.move(to: CGPoint(x: CGFloat(0), y: CGFloat(maxY - (borderPercentage + ((0 - limitMin) * sizeUnit)) )))
                path4.addLine(to: CGPoint(x: CGFloat(maxX), y: CGFloat(maxY - (borderPercentage + ((0 - limitMin) * sizeUnit)) )))
                context.stroke(
                    path4,
                    with: .color(Color(red: 0 / 255, green: 48 / 255, blue: 146 / 255))
                )
                // #########################################
                ///0 degree
//                context.draw(Text("0").bold().foregroundColor(Color(red: 179 / 255, green: 255 / 255, blue: 255 / 255)).font(.system(size: fontSize1)), in: CGRect(x: maxX + (boxPercentWidth * 2), y: (maxY - ((boxPercentWidth * 3) + borderPercentage + ((0 - limitMin) * sizeUnit))), width: boxPercentWidth * 4, height: boxPercentWidth * 4))
                // #########################################
            }
            .frame(width: frameSize.width, height: frameSize.height)
            .background(Color.black)
        } // end geometry

    }

}
