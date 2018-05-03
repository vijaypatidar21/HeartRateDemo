//
//  ViewController.swift
//  PubNubHeartRateDemo
//
//  Created by Vijendra-New_Mac on 27/04/18.
//  Copyright © 2018 Vijendra-New_Mac. All rights reserved.
//

import UIKit

import AVFoundation
enum CURRENT_STATE : Int {
    case state_PAUSED
    case state_SAMPLING
}
class ViewController: UIViewController,AVCaptureVideoDataOutputSampleBufferDelegate {

    @IBOutlet weak var puseRate: UILabel!
    
    @IBOutlet weak var validFrames: UILabel!
    
    @IBOutlet weak var startButton: UIButton!
    
    var timer:Timer?
    var session:AVCaptureSession?
    var camera:AVCaptureDevice?
    var captureSession:AVCaptureSession?
    var validFrameCounter:Int = Int();
    var MIN_FRAMES_FOR_FILTER_TO_SETTLE  = 10
    var currentState:CURRENT_STATE?
    var pulseDetector:PulseDetector = PulseDetector()
    var pubNubBool:Bool = false
    var timerBool:Bool = false
    var filter:Filter = Filter()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        camera = AVCaptureDevice.default(for: .video)
       self.resume()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.pause()
    }
    
    @IBAction func btnAction_Start(_ sender: UIButton)// throws
    {
        if (startButton.currentTitle == "Start") {
            startButton.setTitle("Stop", for: .normal)
            do {
                try startCameraCapture()
            } catch {
                print("Not me error")
            }
           // try startCameraCapture()
            pubNubBool = false
        } else {
            startButton.setTitle("Start", for: .normal)
            timer?.invalidate()
            stopCameraCapture()
            puseRate.text = "Please start reading"
        }
    }
    func startCameraCapture() throws
    {
        
        // timer = Timer(timeInterval: 0.5, target: self, selector: #selector(BlinkingMethod), userInfo: nil, repeats: true)
        
        self.session = AVCaptureSession()
        
        self.camera = AVCaptureDevice.default(for: .video)
        
        if(self.camera?.isTorchModeSupported(.on))!
        {
            
            try self.camera?.lockForConfiguration()
            
            self.camera?.torchMode = .on
            
            camera?.unlockForConfiguration()
        }
        let error:Error? = nil
        
        let cameraInput:AVCaptureInput = try AVCaptureDeviceInput(device: self.camera!)
        
        
        if(cameraInput == nil)
        {
            
            print("Error")
            
        }
        
        let videoOutput:AVCaptureVideoDataOutput = AVCaptureVideoDataOutput()
        
        let captureQueue = DispatchQueue(label: "captureQueue")
        
        videoOutput.setSampleBufferDelegate(self, queue: captureQueue)
        
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey : Int(kCVPixelFormatType_32BGRA)] as [String : Any]
        
       // var conn: AVCaptureConnection? = videoOutput.connection(with: .video)
        let conn: AVCaptureDevice? = AVCaptureDevice.default(for: .video)
        
        
        if conn?.isTorchModeSupported(.on) ?? false {
            try? conn?.lockForConfiguration()
            //configure frame rate
          //  conn?.activeVideoMaxFrameDuration = CMTimeMake(1, 10)
            conn?.activeVideoMinFrameDuration = CMTimeMake(1, 10)
            
            conn?.unlockForConfiguration()
        }
        
      //  conn?.activeVideoMinFrameDuration = CMTimeMake(1, 10)
        
        session?.canSetSessionPreset(AVCaptureSession.Preset.low)
        session?.addInput(cameraInput)
        
        session?.addOutput(videoOutput)
        
      //  session?.sessionPreset = .medium
        
        session?.startRunning()
        
        self.currentState = CURRENT_STATE.state_SAMPLING
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.update), userInfo: nil, repeats: true)
        
    }

    @objc func update()
    {
        
        validFrames.text = "Captured Frames: \(min(100, (100 * validFrameCounter) / MIN_FRAMES_FOR_FILTER_TO_SETTLE))%"
        // if we're paused then there's nothing to do
        if(self.currentState == CURRENT_STATE.state_PAUSED) {
            return;
        }
        let avePeriod: Float = pulseDetector.getAverage()
        if(avePeriod == Float(INVALID_PULSE_PERIOD))
        {
            
            
            
        }else
        {
            let pulse:Float = 60.0 / avePeriod
            print(pulse)
            puseRate.text = String(format: "%0.0f", pulse)
            if !pubNubBool {
                pubNubMethod(pulseRate: puseRate.text!)
            }
        }
    }
    
    func pubNubMethod(pulseRate:String)
    {
        pubNubBool = true
        stopCameraCapture()
        timer?.invalidate()
        
    }
    func stopCameraCapture() {
        session?.stopRunning()
        session = nil
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // if we're paused don't do anything
        if(self.currentState==CURRENT_STATE.state_PAUSED)
        {
            // reset our frame counter
            self.validFrameCounter=0;
            return;
        }
        
        let cvimgRef = CMSampleBufferGetImageBuffer(sampleBuffer)
        print("sample buffer \(String(describing: cvimgRef)) buffer end")
        // Lock the image buffer
        CVPixelBufferLockBaseAddress(cvimgRef!, CVPixelBufferLockFlags(rawValue: 0))
        
        
        // access the data
        
        let width: size_t = CVPixelBufferGetWidth(cvimgRef!)
        let height: size_t = CVPixelBufferGetHeight(cvimgRef!)
        // get the raw image bytes
        //var buf = UnsafeRawPointer((CVPixelBufferGetBaseAddress(cvimgRef!)))
       // let buf = UnsafeMutablePointer<UInt8>(CVPixelBufferGetBaseAddress(cvimgRef!))

        if let baseAddress = CVPixelBufferGetBaseAddress(cvimgRef!) {
            var buf = baseAddress.assumingMemoryBound(to: UInt8.self)
            // `buf` is `UnsafeMutablePointer<UInt8>`
            
            let bprow: size_t = CVPixelBufferGetBytesPerRow(cvimgRef!)
            var r: Float = 0
            var g: Float = 0
            var b: Float = 0
            for y in 0..<height {
                var x = 0
                while x < width * 4 {
                    b = b + Float(buf[x])
                    g = g + Float(buf[x + 1])
                    r = r + Float(buf[x + 2])
                    x += 4
                }
                buf = buf + bprow
            }
            r = r/(255 * Float(width * height))
            g = g/(255 * Float(width * height))
            b = g/(255 * Float(width * height))
            
            var h: Float = 0.0
            var s: Float = 0.0
            var v: Float = 0.0
            RGBtoHSV(r: r, g: g, b: b, h: &h, s: &s, v: &v)
            
            if(s>0.5 && v>0.5)
            {
              //  print("RatePulse: \(puseRate.text)")
                
                // increment the valid frame count
                
                validFrameCounter += 1
                // filter the hue value - the filter is a simple band pass filter that removes any DC component and any high frequency noise
                var filtered: Float = filter.processValue(h)
                print("filtered value \(filtered)")
                if validFrameCounter > MIN_FRAMES_FOR_FILTER_TO_SETTLE {
                    // add the new value to the pulse detector
                    pulseDetector.addNewValue(filtered, atTime: CACurrentMediaTime())
                }
                timerBool = true
            }else
            {
                timerBool = false
                validFrameCounter = 0
                // clear the pulse detector - we only really need to do this once, just before we start adding valid samples
                pulseDetector.reset()
            }
        } else {
            // `baseAddress` is `nil`
        }
        
    }
    func RGBtoHSV(r: Float, g: Float, b: Float, h: UnsafeMutablePointer<Float>?, s: UnsafeMutablePointer<Float>?, v: UnsafeMutablePointer<Float>?) {
        var min1: Float
        var max1: Float
        var delta: Float
        min1 = min(r, min(g, b))
        max1 = max(r, max(g, b))
        v?.pointee = max1
        delta = max1 - min1
        if max1 != 0 {
            s?.pointee = delta / max1
        } else {
            // r = g = b = 0
            s?.pointee = 0.0
            h?.pointee = -1
            return
        }
        if r == max1 {
            h?.pointee = (g - b) / delta
        } else if g == max1 {
            h?.pointee = 2 + (b - r) / delta
        } else {
            h?.pointee = 4 + (r - g) / delta
        }
        h?.pointee = (h?.pointee)!*60
        if Int(h?.pointee ?? 0) < 0 {
            h?.pointee += 360
        }
    }
    
    func pause()
    {
         if(self.currentState==CURRENT_STATE.state_PAUSED)
         {
            return;
         }
        
        if (camera?.isTorchModeSupported(.on))! {
            try? camera?.lockForConfiguration()
            camera?.torchMode = .off
            camera?.unlockForConfiguration()
        }
         self.currentState=CURRENT_STATE.state_PAUSED;
        
        UIApplication.shared.isIdleTimerDisabled = false
        
    }
    func resume()
    {
     
        if(self.currentState==CURRENT_STATE.state_PAUSED)
        {
            return;
        }
        // switch on the torch
        
        if (camera?.isTorchModeSupported(.on))! {
            
            try? camera?.lockForConfiguration()
           
            camera?.unlockForConfiguration()
        
        }
        self.currentState = CURRENT_STATE.state_SAMPLING
        
        UIApplication.shared.isIdleTimerDisabled = true
        
    }
    
}

