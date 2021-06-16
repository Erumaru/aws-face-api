//
//  File.swift
//  AWSFaceAPI
//
//  Created by Abzal Toremuratuly on 23.04.2021.
//

import UIKit
import AVFoundation
import MLKit
import Vision

protocol FaceDetectorViewControllerDelegate: class {
    func didFoundFace(image: UIImage)
}

class FaceDetectorViewController: UIViewController {
    private lazy var previewView: AVCaptureVideoPreviewLayer? = {
        guard let session = session else { return nil }
        let view = AVCaptureVideoPreviewLayer(session: session)
        view.frame = self.view.bounds
        view.videoGravity = AVLayerVideoGravity.resizeAspect
        return view
    }()
    
    private lazy var videoDataOutput: AVCaptureVideoDataOutput = {
        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.setSampleBufferDelegate(self, queue:self.videoDataOutputQueue)
        videoDataOutput.connection(with: .video)?.isEnabled = true
        return videoDataOutput
    }()
    
    private lazy var videoDataOutputQueue: DispatchQueue = {
        DispatchQueue(label: "VideoDataOutputQueue")
    }()
    
    private lazy var deviceInput: AVCaptureDeviceInput? = {
        guard let captureDevice = captureDevice else { return nil }
        return try? AVCaptureDeviceInput(device: captureDevice)
    }()
    
    private lazy var captureDevice : AVCaptureDevice? = {
        guard let device = AVCaptureDevice
        .default(AVCaptureDevice.DeviceType.builtInWideAngleCamera,
                 for: .video,
                 position: AVCaptureDevice.Position.front) else { return nil }
        return device
    }()
    
    private lazy var session: AVCaptureSession? = {
        guard let input = deviceInput else { return nil }
        let session = AVCaptureSession()
        session.sessionPreset = AVCaptureSession.Preset.vga640x480
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        if session.canAddOutput(videoDataOutput) {
            session.addOutput(videoDataOutput)
        }
        
        return session
    }()
    
    private lazy var detectorOptions: FaceDetectorOptions = {
        let options = FaceDetectorOptions()
        options.performanceMode = .accurate
        options.landmarkMode = .all
        options.contourMode = .none
        options.classificationMode = .none
        options.minFaceSize = 0.4
        return options
    }()
    
    private lazy var detector: FaceDetector = {
        let faceDetector = FaceDetector.faceDetector(options: detectorOptions)
        return faceDetector
    }()
    
    weak var delegate: FaceDetectorViewControllerDelegate?
    
    private lazy var leftLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 40, weight: .bold)
        return label
    }()
    
    private lazy var rightLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 40, weight: .bold)
        return label
    }()
    
    private lazy var stackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [leftLabel, rightLabel])
        view.axis = .horizontal
        view.distribution = .fillEqually
        view.spacing = 16
        return view
    }()
    
    private lazy var faceView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.blue.cgColor
        view.isHidden = true
        return view
    }()
    
    private lazy var outerFaceView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.red.cgColor
        view.isHidden = true
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        if let layer = previewView {
            self.view.layer.addSublayer(layer)
        }
        
        [stackView, faceView, outerFaceView].forEach { view.addSubview($0) }
        
        stackView.snp.makeConstraints {
            $0.top.equalTo(view.snp.topMargin)
            $0.left.right.equalToSuperview()
        }
        
        session?.startRunning()
    }
    
    private var leftEyes: Queue<CGFloat> = .init()
    private var rightEyes: Queue<CGFloat> = .init()
    
    
    private func size(image: CMSampleBuffer) -> CGSize? {
        guard let buffer = CMSampleBufferGetImageBuffer(image) else { return nil }
        let w = CVPixelBufferGetWidth(buffer)
        let h = CVPixelBufferGetHeight(buffer)
        return .init(width: w, height: h)
    }
    
    private func detectFace(image: CMSampleBuffer) {
        let visionImage = VisionImage(buffer: image)
        visionImage.orientation = .leftMirrored
        
        do {
            let faces = try detector.results(in: visionImage)
        
            DispatchQueue.main.async {
                guard let leftEye = faces.first?.landmark(ofType: .leftEye)?.position,
                      let rightEye = faces.first?.landmark(ofType: .rightEye)?.position,
                      let mouth = faces.first?.landmark(ofType: .mouthBottom)?.position else {
                    self.faceView.isHidden = true
                    return
                }
                
                var y = leftEye.y
                var x = leftEye.x
                var h = rightEye.y - leftEye.y
                var w = mouth.x - leftEye.x
                
                guard
                    let rect = self.previewView?.layerRectConverted(fromMetadataOutputRect: .init(x: x, y: y, width: w, height: h)),
                    let size = self.size(image: image) else {
                    self.faceView.isHidden = true
                    return
                }
                
                let viewSize = self.view.bounds.size
                let topOffset = (viewSize.height - size.width * viewSize.width / size.height) / 2.0
                self.faceView.isHidden = false
                self.faceView.frame = .init(x: rect.origin.x / size.height,
                                            y: rect.origin.y / size.width + topOffset,
                                            width: rect.width / size.height,
                                            height: rect.height / size.width)
                self.faceView.layoutIfNeeded()
                
                guard let leftEar = faces.first?.landmark(ofType: .leftEar)?.position,
                      let rightEar = faces.first?.landmark(ofType: .rightEar)?.position else {
                    self.outerFaceView.isHidden = true
                    return
                }
                
                y = leftEar.y
                x = leftEar.x
                h = rightEar.y - leftEar.y
                w = mouth.x - leftEar.x
                
                guard
                    let rect2 = self.previewView?.layerRectConverted(fromMetadataOutputRect: .init(x: x, y: y, width: w, height: h)) else {
                    self.outerFaceView.isHidden = true
                    return
                }
                
                self.outerFaceView.isHidden = false
                self.outerFaceView.frame = .init(x: rect2.origin.x / size.height,
                                            y: rect2.origin.y / size.width + topOffset,
                                            width: rect2.width / size.height,
                                            height: rect2.height / size.width)
                self.outerFaceView.layoutIfNeeded()
            }
        } catch {
            print(error)
        }
    }
}

extension FaceDetectorViewController:  AVCaptureVideoDataOutputSampleBufferDelegate {
    // Convert CIImage to UIImage
    func convert(buffer: CMSampleBuffer) -> UIImage {
        let imageBuffer = CMSampleBufferGetImageBuffer(buffer)!
        let ciimage = CIImage(cvPixelBuffer: imageBuffer)
        let context = CIContext(options: nil)
        let cgImage = context.createCGImage(ciimage, from: ciimage.extent)!
        let image = UIImage(cgImage: cgImage)
        return image
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        self.detectFace(image: sampleBuffer)
    }
}

extension Array where Element: FloatingPoint {

    func sum() -> Element {
        return self.reduce(0, +)
    }

    func avg() -> Element {
        return self.sum() / Element(self.count)
    }

    func std() -> Element {
        let mean = self.avg()
        let v = self.reduce(0, { $0 + ($1-mean)*($1-mean) })
        return sqrt(v / (Element(self.count) - 1))
    }

}

private final class QueueNode<T> {
    // note, not optional – every node has a value
    var value: T
    // but the last node doesn't have a next
    var next: QueueNode<T>? = nil

    init(value: T) { self.value = value }
}

// Ideally, Queue would be a struct with value semantics but
// I'll leave that for now
public final class Queue<T> {
    // note, these are both optionals, to handle
    // an empty queue
    private var head: QueueNode<T>? = nil
    private var tail: QueueNode<T>? = nil
    public var count: Int = 0
    public var maxElements: Int = 20

    public init() { }
}

extension Queue {
    // append is the standard name in Swift for this operation
    public func append(_ newElement: T) {
        count += 1
        let oldTail = tail
        self.tail = QueueNode(value: newElement)
        if  head == nil { head = tail }
        else { oldTail?.next = self.tail }
        if count > maxElements { dequeue() }
    }

    @discardableResult
    public func dequeue() -> T? {
        if let head = self.head {
            count -= 1
            self.head = head.next
            if head.next == nil { tail = nil }
            return head.value
        }
        else {
            return nil
        }
    }
}

extension Queue where T == CGFloat {
    public func std() -> CGFloat {
        var values: [CGFloat] = []
        var cur = head
        while let value = cur?.value {
            values.append(value)
            cur = cur?.next
        }
        return values.std()
    }
}
