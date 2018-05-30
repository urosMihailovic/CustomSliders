import UIKit
import QuartzCore
import ReactiveSwift
import ReactiveCocoa
import Result

private class SliderTrackLayer: CALayer {
    weak var rangeSlider: RestrictedRangeSlider?
    
    override func draw(in ctx: CGContext) {
        guard let slider = rangeSlider else { return }
        
        // Disabled track path
        let disabledTrackPath = UIBezierPath(roundedRect: CGRect(x: slider.trackSidePadding, y: bounds.height / 2 - slider.trackHeight / 2, width: bounds.width - 2*slider.trackSidePadding, height: slider.trackHeight), cornerRadius: slider.trackHeight)
        ctx.addPath(disabledTrackPath.cgPath)
        ctx.setFillColor(slider.disabledTintColor.cgColor)
        ctx.addPath(disabledTrackPath.cgPath)
        ctx.fillPath()
        
        // Interactive track path
        let lowerValuePosition = slider.lowerValue == slider.minimumValue ? slider.trackSidePadding : CGFloat(slider.positionForValue(slider.lowerValue))
        let upperValuePosition = slider.upperValue == slider.maximumValue ? bounds.width - slider.trackSidePadding : CGFloat(slider.positionForValue(slider.upperValue))
        let trackPath = UIBezierPath(roundedRect: CGRect(x: lowerValuePosition, y: bounds.height / 2 - slider.trackHeight / 2, width: upperValuePosition - lowerValuePosition, height: slider.trackHeight), cornerRadius: slider.trackHeight)
        ctx.addPath(trackPath.cgPath)
        ctx.setFillColor(slider.trackTintColor.cgColor)
        ctx.addPath(trackPath.cgPath)
        ctx.fillPath()
    }
}

class SliderThumbLayer: CALayer {
    weak var rangeSlider: RestrictedRangeSlider?
    var highlighted = false
    
    override func draw(in ctx: CGContext) {
        guard let slider = rangeSlider else { return }
        contentsGravity = kCAGravityResizeAspect
        contents = slider.thumbImage.cgImage
    }
    
    override func display() {
        guard let slider = rangeSlider else { return }
        contents = slider.thumbImage.cgImage
    }
}

public class RestrictedRangeSlider: UIControl {
    @IBInspectable public var minimumValue: Double = 0.0 {
        didSet {
            updateLayerFrames()
        }
    }
    
    @IBInspectable public var maximumValue: Double = 1.0 {
        didSet {
            updateLayerFrames()
        }
    }
    
    @IBInspectable public var lowerValue: Double = 0.2 {
        didSet {
            if lowerValue < minimumValue {
                lowerValue = minimumValue
            }
            if lowerValue > currentValue {
                currentValue = lowerValue
                sendActions(for: .valueChanged)
            }
            updateLayerFrames()
        }
    }
    
    @IBInspectable public var currentValue: Double = 0.5 {
        didSet {
            updateLayerFrames()
        }
    }
    
    @IBInspectable public var upperValue: Double = 0.8 {
        didSet {
            if upperValue > maximumValue {
                upperValue = maximumValue
            }
            if currentValue > upperValue {
                currentValue = upperValue
                sendActions(for: .valueChanged)
            }
            updateLayerFrames()
        }
    }
    
    @IBInspectable public var trackTintColor: UIColor = UIColor(red:0.16, green:0.20, blue:0.25, alpha:1.0) {
        didSet {
            trackLayer.setNeedsDisplay()
        }
    }
    
    @IBInspectable public var disabledTintColor: UIColor = UIColor(red:0.16, green:0.20, blue:0.25, alpha:1.0) {
        didSet {
            trackLayer.setNeedsDisplay()
        }
    }
    
    @IBInspectable public var trackHeight: CGFloat = CGFloat(2.0) {
        didSet {
            trackLayer.setNeedsDisplay()
        }
    }
    
    @IBInspectable public var thumbImage: UIImage = UIImage()
    
    @IBInspectable let trackSidePadding: CGFloat = 2.0

    var previouslocation = CGPoint()
    
    private let trackLayer = SliderTrackLayer()
    private let thumbLayer = SliderThumbLayer()
    
    var thumbWidth: CGFloat {
        return CGFloat(bounds.height)
    }
    
    override public var frame: CGRect {
        didSet {
            updateLayerFrames()
        }
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        initializeLayers()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        initializeLayers()
    }
    
    override public func layoutSublayers(of: CALayer) {
        super.layoutSublayers(of: layer)
        updateLayerFrames()
    }
    
    fileprivate func initializeLayers() {
        layer.backgroundColor = UIColor.clear.cgColor
        
        trackLayer.rangeSlider = self
        trackLayer.contentsScale = 2*UIScreen.main.scale
        layer.addSublayer(trackLayer)
        
        thumbLayer.rangeSlider = self
        thumbLayer.contentsScale = UIScreen.main.scale
        layer.addSublayer(thumbLayer)
    }
    
    func updateLayerFrames() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        trackLayer.frame = bounds.insetBy(dx: 0.0, dy: bounds.height / 3)
        trackLayer.setNeedsDisplay()
        
        let lowerThumbCenter = CGFloat(positionForValue(currentValue))
        thumbLayer.frame = CGRect(x: lowerThumbCenter - thumbWidth / 2.0, y: 0.0, width: thumbWidth, height: thumbWidth)
        thumbLayer.setNeedsDisplay()
        
        CATransaction.commit()
    }
    
    func positionForValue(_ value: Double) -> Double {
        let availableWidth = Double(bounds.width + 2 * trackSidePadding - thumbWidth)
        return  availableWidth * (value - minimumValue) / (maximumValue - minimumValue) + Double(thumbWidth/2.0 - trackSidePadding)
    }
    
    func boundValue(_ value: Double, toLowerValue lowerValue: Double, upperValue: Double) -> Double {
        return min(max(value, lowerValue), upperValue)
    }
    
    // MARK: - Touches
    
    override public var isTracking: Bool {
        return thumbLayer.highlighted
    }
    
    override public func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        previouslocation = touch.location(in: self)
        
        if thumbLayer.frame.contains(previouslocation) {
            thumbLayer.highlighted = true
        }
        
        return thumbLayer.highlighted
    }
    
    override public func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let location = touch.location(in: self)
        
        let deltaLocation = Double(location.x - previouslocation.x)
        let deltaValue = (maximumValue - minimumValue) * deltaLocation / Double(bounds.width - bounds.height)
        
        previouslocation = location
        
        if thumbLayer.highlighted {
            currentValue = boundValue(currentValue + deltaValue, toLowerValue: lowerValue, upperValue: upperValue)
        }
        
        sendActions(for: .valueChanged)
        return thumbLayer.highlighted
    }
    
    override public func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        thumbLayer.highlighted = false
        sendActions(for: .valueChanged)
    }
    
    override public func cancelTracking(with event: UIEvent?) {
        thumbLayer.highlighted = false
        sendActions(for: .valueChanged)
    }
}

extension Reactive where Base: RestrictedRangeSlider {
    
    internal var values: Signal<Double, NoError> {
        return mapControlEvents(.valueChanged) { $0.currentValue }
    }
}
