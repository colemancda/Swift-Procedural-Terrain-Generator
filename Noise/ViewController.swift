//
//  ViewController.swift
//  Noise
//
//  Created by William Vabrinskas on 5/18/18.
//  Copyright © 2018 William Vabrinskas. All rights reserved.
//

import UIKit


class ViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var sampleNumberLabel: UILabel!

    @IBOutlet weak var settingsButton: UIButton! {
        didSet {
            settingsButton.imageView?.contentMode = .scaleAspectFit
        }
    }
    @IBOutlet weak var settingsLeading: NSLayoutConstraint!
    @IBOutlet weak var settingsTop: NSLayoutConstraint!
    
    @IBOutlet weak var sampleTextField: UITextField! {
        didSet {
            sampleTextField.delegate = self
            sampleTextField.text = "\(501)"
            sampleTextField.keyboardType = .numberPad
        }
    }
    @IBOutlet weak var steepnessTextField: UITextField!  {
        didSet {
            steepnessTextField.delegate = self
            steepnessTextField.text = "\(30)"
            steepnessTextField.keyboardType = .numberPad

        }
    }
    @IBOutlet weak var hillFactorTextField: UITextField!  {
        didSet {
            hillFactorTextField.delegate = self
            hillFactorTextField.text = "\(10)"
            hillFactorTextField.keyboardType = .numberPad
        }
    }
    
    @IBOutlet weak var sharpnessTextField: UITextField! {
        didSet {
            sharpnessTextField.delegate = self
            sharpnessTextField.text = "\(10)"
            sharpnessTextField.keyboardType = .numberPad
        }
    }
    
    @IBOutlet weak var settingsView: UIView! {
        didSet {
            settingsView.layer.shadowColor = UIColor.black.cgColor
            settingsView.layer.shadowOffset = CGSize(width: 0.0, height: -4.0)
            settingsView.layer.shadowRadius = 10.0
            settingsView.layer.shadowOpacity = 0.8
            settingsView.clipsToBounds = true
            settingsView.layer.cornerRadius = 10.0
            settingsView.alpha = 0.0
        }
    }
    
    private lazy var height = self.view.frame.size.height * 0.7
    
    private var adjustment:UInt32! {
        get {
           return UInt32(steepnessTextField.text ?? "\(30)")!
        }
    }
    private var spacing:CGFloat! {
        get {
            return CGFloat(UInt32(sharpnessTextField.text ?? "\(10)")!)
        }
    }
    
    private var timer:Timer!
    
    private let ellipseWidth:CGFloat = 1.0
    private let ellipseHeight:CGFloat = 1.0
    
    private let graphLayer = CAShapeLayer()

    private var previousLine: CGMutablePath!
    private var previousLineLayer: CAShapeLayer!
    private var previousColor: CGColor!
    
    
    enum TerrainType:Int {
        case Plains, Ocean, Hills, Mountains, Marsh, Islands
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        settingsTop.constant = -160.0
        self.view.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(hideKeyboard)))
        
        graphLayer.backgroundColor = UIColor(red: 44.0/255.0, green: 48.0/255.0, blue: 49.0/255.0, alpha: 1.0).cgColor
        graphLayer.frame = CGRect(x: 0, y: self.view.frame.midY - (height / 2.0), width: self.view.frame.size.width, height: height)
        self.contentView.layer.addSublayer(graphLayer)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        contentView.backgroundColor = .clear
        view.backgroundColor = .clear
        //startOneDNoise(samples: 2000)
        let twoD = TwoDimensionalNoiseView(frame: CGRect(x: 50, y: 56, width: self.view.frame.size.width - 100, height: 300))
        self.view.addSubview(twoD)
    }
    
    @objc func hideKeyboard() {
        DispatchQueue.main.async {
            self.view.endEditing(true)
        }
    }
    
    private func clear() {
        self.sampleNumberLabel.text = "0"

        timer?.invalidate()
        self.graphLayer.sublayers?.forEach({ (layer) in
            layer.removeFromSuperlayer()
        })
        self.contentView.subviews.forEach { (subview) in
            if subview is UILabel {
                subview.removeFromSuperview()
            }
        }
    }
    
    private func getColor(point: CGPoint) -> CGColor {
        
        let terrainColors:[CGFloat : CGColor] = [
                             0.2 : UIColor.white.cgColor,
                             0.5 : UIColor.lightGray.cgColor,
                             0.7 : UIColor(red: 179.0/255.0, green: 114.0/255.0, blue: 25.0/255.0, alpha: 1.0).cgColor,
                             0.85: UIColor(red: 24.0/255.0, green: 169.0/255.0, blue: 59.0/255.0, alpha: 1.0).cgColor,
                             0.9 : UIColor(red: 67.0/255.0, green: 180.0/255.0, blue: 212.0/255.0, alpha: 1.0).cgColor,
                             1.0 : UIColor(red: 36.0/255.0, green: 95.0/255.0, blue: 217.0/255.0, alpha: 1.0).cgColor
                            ]
        
        let sorted = terrainColors.sorted(by: { $0.key < $1.key} )
        
        for terrain in sorted {
            let y = point.y
            let heightValue = self.graphLayer.bounds.height * terrain.key
            
            if y < heightValue {
                return terrain.value
            }
        }
        
        return UIColor.white.cgColor
    }
    
    private func addGraphics(index: Int, previousPoint: CGPoint?, currentPoint: CGPoint) {
        
        let shouldGetNewLine:Bool = {
            if previousColor == self.getColor(point: currentPoint) {
                return false
            }
            return true
        }()
        
        var line = CGMutablePath()

        if !shouldGetNewLine {
            line = previousLine
        }
        
        if previousPoint != nil {
            line.move(to: CGPoint(x: previousPoint!.x - (0.5 * self.ellipseWidth), y: previousPoint!.y))
            line.addLine(to: CGPoint(x: currentPoint.x - (0.5 * self.ellipseWidth), y: currentPoint.y))
        }
        
        let lineLayer = !shouldGetNewLine ? previousLineLayer! : CAShapeLayer()

        lineLayer.lineWidth = 2.0
        lineLayer.lineCap = kCALineCapRound
        lineLayer.strokeColor = self.getColor(point: currentPoint)
        lineLayer.path = line
        
        if shouldGetNewLine {
            self.graphLayer.addSublayer(lineLayer)
        }
        
        previousLineLayer = lineLayer
        previousColor = self.getColor(point: currentPoint)
        previousLine = line

        let oval = UIBezierPath(ovalIn: CGRect(x:currentPoint.x, y: currentPoint.y, width: self.ellipseWidth, height: self.ellipseHeight))
        let ovalLayer = CAShapeLayer()

        ovalLayer.fillColor = self.getColor(point: currentPoint)
        ovalLayer.strokeColor = UIColor.clear.cgColor
        ovalLayer.path = oval.cgPath
        
        self.graphLayer.addSublayer(ovalLayer)
        
        if currentPoint.x >= self.view.frame.maxX - 107 {
            self.graphLayer.frame.size = CGSize(width: self.graphLayer.frame.size.width + (self.view.frame.maxX - 107), height:  self.graphLayer.frame.size.height)
            self.scrollView.setContentOffset(CGPoint(x: currentPoint.x - (self.view.frame.maxX - 107), y: 0), animated: true)
        }
        
    }
    
    func getTerrain(terrainType: TerrainType) -> (startPoint: CGFloat, offset: CGFloat, type: TerrainType) {
        var startPoint:CGFloat = 0.0
        var offset: CGFloat = 0.0
        let max = graphLayer.bounds.maxY
        
        switch terrainType {
        case .Hills:
            startPoint = 0.5 * max
            offset = 50.0
            break
        case .Ocean:
            startPoint = 0.1 * max
            offset = 20.0
            break
        case .Islands:
            startPoint = 0.12 * max
            offset = 40.0
            break
        case .Marsh:
            startPoint = 0.15 * max
            offset = 35.0
            break
        case .Mountains:
            startPoint = 0.7 * max
            offset = 100.0
            break
        case .Plains:
            startPoint = 0.2 * max
            offset = 10.0
            break
        }
        return (startPoint:startPoint, offset: offset, type: terrainType)
    }
    
    private func transition(terrain:(startPoint: CGFloat, offset: CGFloat, type: TerrainType)) {
        let randomChange = arc4random_uniform(100)
        if randomChange == 0 {
            if terrain.type == TerrainType.Mountains {
                self.getTerrain(terrainType: .Hills)
            } else if terrain.type == TerrainType.Hills {
                self.getTerrain(terrainType: .Plains)
            } else if terrain.type == TerrainType.Plains {
                self.getTerrain(terrainType: .Marsh)
            } else if terrain.type == TerrainType.Ocean {
                self.getTerrain(terrainType: .Islands)
            } else if terrain.type == TerrainType.Islands {
                self.getTerrain(terrainType: .Plains)
            }
        }
    }
    
    private func startOneDNoise(samples: Int) {
        self.clear()

        var i = 0
        var yOff = 0.0
        
        self.scrollView.contentSize = CGSize(width: CGFloat(samples) + 107, height: self.scrollView.contentSize.height)

        var previousPoint: CGPoint?

        let max = graphLayer.bounds.minY
        let min = graphLayer.bounds.maxY
        
        let terrain = getTerrain(terrainType: .Mountains)

        timer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { (timer) in
            if i == samples {
                timer.invalidate()
                return
            }
            
            if i >= samples - 1 {
                DispatchQueue.main.async {
                    self.scrollView.scrollRectToVisible(CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.contentView.frame.size.height), animated: true)
                }
                timer.invalidate()
            }
            
            self.sampleNumberLabel.text = "\(i + 1)"

            var noise = (CGFloat(Noise().perlin(x: 0.0, y: yOff, z: 0.0)) * terrain.offset) + terrain.startPoint
            
            if noise < max {
                noise = max
            } else if noise > min {
                noise = min
            }
            
            let current = CGPoint(x: CGFloat(i), y: noise)

            let currentPoint = CGPoint(x: current.x, y: self.graphLayer.bounds.maxY - (current.y + self.ellipseHeight))
            self.addGraphics(index: i, previousPoint: previousPoint, currentPoint: currentPoint)
            
            previousPoint = currentPoint
            
            yOff += 0.02
            i += 1
        }
        timer.fire()
        
    }

    
    @IBAction func settingsButtonPressed(_ sender: Any) {
        var isHidden = false
        
        if settingsTop.constant == 40.0 {
            settingsTop.constant = -160.0
            isHidden = true
            settingsButton.setImage(#imageLiteral(resourceName: "Hamburger_icon.svg"), for: .normal)
        } else {
            isHidden = false
            settingsTop.constant = 40.0
            settingsButton.setImage(#imageLiteral(resourceName: "delete-sign"), for: .normal)
        }
        
        UIView.animate(withDuration: 0.38, delay: 0.0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.4, options: .curveEaseIn, animations: {
            self.settingsView.alpha = isHidden ? 0.0 : 1.0
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    @IBAction func startTapped(_ sender: Any) {
       self.scrollView.scrollRectToVisible(CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.contentView.frame.size.height), animated: true)
        timer.invalidate()
        view.endEditing(true)
        startOneDNoise(samples:  Int(sampleTextField.text ?? "\(500)")!)
        settingsButtonPressed(self)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.clear()
    }
}

