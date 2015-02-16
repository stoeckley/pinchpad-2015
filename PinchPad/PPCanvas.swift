//
//  PPCanvas.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 2/6/15.
//
//

import UIKit

class PPCanvas: UIView{
    var strokes = [PPStroke]()
    var redoStrokes = [PPStroke]()
    var activeStroke: PPStroke?
    var activeStrokeSegmentsDrawn = 0
    var canvasThusFar: UIImage?
    var touchEvents = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clearColor()
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    
    // MARK: Touch handling
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        self.touchEvents++
        self.activeStroke = PPStroke(color: UIColor.blackColor(), width: 5.0)
        self.activeStroke!.addPoint(touches.anyObject() as UITouch, inView:self)
        self.activeStrokeSegmentsDrawn = 0
    }
    
    override func touchesMoved(touches: NSSet, withEvent event: UIEvent) {
        self.touchEvents++
        self.activeStroke!.addPoint(touches.anyObject() as UITouch, inView:self)
        
        // Only redraw the active stroke once every .05s or so
        if (!self.activeStroke!.isDot()){
            self.setNeedsDisplay()
        }
    }
    
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        self.touchEvents++
        self.activeStroke!.addPoint(touches.anyObject() as UITouch, inView:self)
        strokes.append(self.activeStroke!)
        self.activeStroke = nil
        self.setNeedsDisplay()
    }
    
    
    // MARK: Toolbar actions
    
    func clear(){
        self.canvasThusFar = nil
        self.strokes = [PPStroke]()
        self.setNeedsDisplay()
    }
    
    func undo(){
        if self.strokes.count > 0{
            self.redoStrokes.append(self.strokes.removeLast())
            self.setNeedsDisplay()
        }
    }
    
    func redo(){
        if self.redoStrokes.count > 0{
            self.strokes.append(self.redoStrokes.removeLast())
            self.setNeedsDisplay()
        }
    }
    
    
    // MARK: Rendering
    
    func drawStroke(stroke: PPStroke, quickly:Bool){
        if CGColorGetAlpha(stroke.color.CGColor) == 0 {
            // Eraser mode
            CGContextSetBlendMode(UIGraphicsGetCurrentContext(), kCGBlendModeClear)
        } else {
            // Pencil mode
            CGContextSetBlendMode(UIGraphicsGetCurrentContext(), kCGBlendModeNormal)
        }
        
        stroke.color.setFill()
        if (quickly){
            var paths = stroke.asBezierPaths()
            for var i = max(0, self.activeStrokeSegmentsDrawn - 1); i < paths.count; i++ {
                paths[i].fill()
            }
            self.activeStrokeSegmentsDrawn = paths.count
        } else {
            for path in stroke.asBezierPaths(){
                path.fill()
            }
        }
    }
    
    override func drawRect(rect: CGRect) {
        // We're gonna save everything to a cached UIImage
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, true, 0.0)
        
        if let stroke = activeStroke{
            // Draw just the latest line segment
            if let cachedImage = canvasThusFar {
                cachedImage.drawInRect(rect)
            } else {
                UIColor.whiteColor().setFill()
                UIBezierPath(rect: self.bounds).fill()
            }
            
            drawStroke(stroke, quickly: true)
        } else {
            // Redraw everything from scratch
            UIColor.whiteColor().setFill()
            UIBezierPath(rect: self.bounds).fill()
            for stroke in strokes{
                drawStroke(stroke, quickly: false)
            }
        }
        
        // Save results to a cached image
        canvasThusFar = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // Draw result to screen
        canvasThusFar!.drawInRect(rect)
    }
    
    func asImage() -> UIImage{
        if canvasThusFar == nil{
            return UIImage()
        } else {
            return canvasThusFar!
        }
    }
}