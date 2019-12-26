//
//  VideoMakerViewController.swift
//  GOQMOVIE
//
//  Created by jongjin seok on 12/10/2018.
//  Copyright © 2018 OGQ. All rights reserved.
//


import AVFoundation
import UIKit
import Photos
import AVKit
var tempurl=""

typealias RetuenTempUrl = (String) -> Void

class VideoMakerViewController: UIViewController {
    
    var returnTempUrl: RetuenTempUrl?
    
    var images:[UIImage]=[]
    var videoview: UIView = {
       let view = UIView()
        view.backgroundColor = .white
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(videoview)
        videoview.frame = self.view.bounds
        
       
    }
    
    func createLiveWallpaper() {
        DispatchQueue.main.async {
            if #available(iOS 11.0, *) {
                let settings = RenderSettings()
                let imageAnimator = ImageAnimator(renderSettings: settings,imagearr: self.images)
                imageAnimator.render() { 
                    self.returnTempUrl?(tempurl)
                    self.save(UIBarButtonItem())
                }
            } else {
                // Fallback on earlier versions
            }
            
        }
        
    }
    
    func displayVideo()
    {
        
        let u:String=tempurl
        let player = AVPlayer(url: URL(fileURLWithPath: u))
        let playerController = AVPlayerViewController()
        playerController.player = player
        self.addChild(playerController)
        videoview.addSubview(playerController.view)
        playerController.view.frame.size=(videoview.frame.size)
        playerController.view.contentMode = .scaleAspectFit
        playerController.view.backgroundColor=UIColor.clear
        
        player.play()
        
    }
    
    @IBAction func save(_ sender: UIBarButtonItem) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }
            
            let u:String=tempurl
            PHPhotoLibrary.shared().performChanges({
                let creationRequest = PHAssetCreationRequest.forAsset()
                let options = PHAssetResourceCreationOptions()
                
                creationRequest.addResource(with: PHAssetResourceType.video, fileURL: URL(fileURLWithPath: u) as URL, options: options)
               // PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL(fileURLWithPath: u) as URL)
            }) { success, error in
                if !success {
                    print("Could not save video to photo library:", error!)
                }
            }
        }
    }
    
    
}

@available(iOS 11.0, *)
struct RenderSettings {
    
    var width: CGFloat = UIScreen.main.bounds.size.width
    var height: CGFloat = UIScreen.main.bounds.size.height
    var fps: Int32 = 24
    var avCodecKey = AVVideoCodecType.h264
    var videoFilename = "renderExportVideo"
    var videoFilenameExt = "MOV"
    
    var size: CGSize {
        return CGSize(width: width, height: height)
    }
    
    var outputURL: NSURL {
        
        let fileManager = FileManager.default
        if let tmpDirURL = try? fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true) {
            return tmpDirURL.appendingPathComponent(videoFilename).appendingPathExtension(videoFilenameExt) as NSURL
        }
        fatalError("URLForDirectory() failed")
    }
}

@available(iOS 11.0, *)
class VideoWriter {
    
    let renderSettings: RenderSettings
    
    var videoWriter: AVAssetWriter!
    var videoWriterInput: AVAssetWriterInput!
    var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor!
    
    var isReadyForData: Bool {
        return videoWriterInput?.isReadyForMoreMediaData ?? false
    }
    
    class func pixelBufferFromImage(image: UIImage, pixelBufferPool: CVPixelBufferPool, size: CGSize) -> CVPixelBuffer {
        
        var pixelBufferOut: CVPixelBuffer?
        
        let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, &pixelBufferOut)
        if status != kCVReturnSuccess {
            fatalError("CVPixelBufferPoolCreatePixelBuffer() failed")
        }
        
        let pixelBuffer = pixelBufferOut!
        
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        
        let data = CVPixelBufferGetBaseAddress(pixelBuffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: data, width: Int(size.width), height: Int(size.height),
                                bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)
        
        context!.clear(CGRect(x: 0, y: 0, width: size.width, height: size.height))
        
        let horizontalRatio = size.width / image.size.width
        let verticalRatio = size.height / image.size.height
        
        let aspectRatio = min(horizontalRatio, verticalRatio) // ScaleAspectFit
        let newSize = CGSize(width: image.size.width * aspectRatio, height: image.size.height * aspectRatio)
 
        let x = newSize.width < size.width ? (size.width - newSize.width) / 2 : 0
        let y = newSize.height < size.height ? (size.height - newSize.height) / 2 : 0
        
        context!.concatenate(CGAffineTransform.identity)
        context!.draw(image.cgImage!, in: CGRect(x: x, y: y, width: newSize.width, height: newSize.height))
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
        
        return pixelBuffer
    }
    
    init(renderSettings: RenderSettings) {
        self.renderSettings = renderSettings
    }
    
    func start() {
        
        let avOutputSettings: [String: AnyObject] = [
            AVVideoCodecKey: renderSettings.avCodecKey as AnyObject,
            AVVideoWidthKey: NSNumber(value: Float(renderSettings.width)),
            AVVideoHeightKey: NSNumber(value: Float(renderSettings.height))
        ]
        
        func createPixelBufferAdaptor() {
            let sourcePixelBufferAttributesDictionary = [
                kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32ARGB),
                kCVPixelBufferWidthKey as String: NSNumber(value: Float(renderSettings.width)),
                kCVPixelBufferHeightKey as String: NSNumber(value: Float(renderSettings.height))
            ]
            pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput,
                                                                      sourcePixelBufferAttributes: sourcePixelBufferAttributesDictionary)
        }
        
        func createAssetWriter(outputURL: NSURL) -> AVAssetWriter {
            guard let assetWriter = try? AVAssetWriter(outputURL: outputURL as URL, fileType: AVFileType.mp4) else {
                fatalError("AVAssetWriter() failed")
            }
            
            guard assetWriter.canApply(outputSettings: avOutputSettings, forMediaType: AVMediaType.video) else {
                fatalError("canApplyOutputSettings() failed")
            }
            
            return assetWriter
        }
        
        videoWriter = createAssetWriter(outputURL: renderSettings.outputURL)
        videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: avOutputSettings)
        
        if videoWriter.canAdd(videoWriterInput) {
            videoWriter.add(videoWriterInput)
        }
        else {
            fatalError("canAddInput() returned false")
        }
        
        
        createPixelBufferAdaptor()
        
        if videoWriter.startWriting() == false {
            fatalError("startWriting() failed")
        }
     
        videoWriter.startSession(atSourceTime: CMTime.zero)
        
        precondition(pixelBufferAdaptor.pixelBufferPool != nil, "nil pixelBufferPool")
    }
    
    func render(appendPixelBuffers: @escaping (VideoWriter)->Bool, completion: @escaping ()->Void) {
        
        precondition(videoWriter != nil, "Call start() to initialze the writer")
        
        let queue = DispatchQueue(label: "mediaInputQueue")
        videoWriterInput.requestMediaDataWhenReady(on: queue) {
            let isFinished = appendPixelBuffers(self)
            if isFinished {
                self.videoWriterInput.markAsFinished()
                self.videoWriter.finishWriting() {
                    DispatchQueue.main.async {
                        completion()
                    }
                }
            }
            else {
                
            }
        }
    }
    
    func addImage(image: UIImage, withPresentationTime presentationTime: CMTime) -> Bool {
        
        precondition(pixelBufferAdaptor != nil, "Call start() to initialze the writer")
        
        let pixelBuffer = VideoWriter.pixelBufferFromImage(image: image, pixelBufferPool: pixelBufferAdaptor.pixelBufferPool!, size: renderSettings.size)
        return pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime)
    }
    
}

@available(iOS 11.0, *)
class ImageAnimator{
    
    static let kTimescale: Int32 = 12000
    
    let settings: RenderSettings
    let videoWriter: VideoWriter
    var images: [UIImage]!
    
    var frameNum = 0
    
    class func removeFileAtURL(fileURL: NSURL) {
        do {
            try FileManager.default.removeItem(atPath: fileURL.path!)
        }
        catch _ as NSError {
            //
        }
    }
    
    init(renderSettings: RenderSettings,imagearr: [UIImage]) {
        settings = renderSettings
        videoWriter = VideoWriter(renderSettings: settings)
        images = imagearr
    }
    
    func render(completion: @escaping ()->Void) {
        
        // The VideoWriter will fail if a file exists at the URL, so clear it out first.
        ImageAnimator.removeFileAtURL(fileURL: settings.outputURL)
        
        videoWriter.start()
        videoWriter.render(appendPixelBuffers: appendPixelBuffers) {
            
            let s:String=self.settings.outputURL.path!
            
            tempurl=s
            completion()
        }
        
    }
    
    
    func appendPixelBuffers(writer: VideoWriter) -> Bool {
        
        //let frameDuration = CMTimeMake(Int64(ImageAnimator.kTimescale / settings.fps), ImageAnimator.kTimescale)
        let frameDuration = CMTimeMake(value: Int64(10000), timescale: ImageAnimator.kTimescale)
        
        while !images.isEmpty {
            
            if writer.isReadyForData == false {
                
                return false
            }
            
            let image = images.removeFirst()
            let presentationTime = CMTimeMultiply(frameDuration, multiplier: Int32(frameNum))
            let success = videoWriter.addImage(image: image, withPresentationTime: presentationTime)
            if success == false {
                fatalError("addImage() failed")
            }
            
            frameNum=frameNum+1
        }
        
        
        return true
    }
    
}
