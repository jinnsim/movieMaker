 
import Foundation
import Photos
 
class PhotoHelper: NSObject {
    static let shared = PhotoHelper()
 
    private var assetCollection: PHAssetCollection?

    //저장후 성공 얼럿
    var isShowDownloadAfterAlert = false

    private override init() {
        super.init()
    }

 

    func photoAccess(_ handler: @escaping (() -> Void), denied: @escaping (() -> Void)){
        if PHPhotoLibrary.authorizationStatus() == .authorized{
            if let _ = self.assetCollection{
                handler()
            }else{
              
            }
        }else if PHPhotoLibrary.authorizationStatus() == .denied{
            denied()
        }else{
            PHPhotoLibrary.requestAuthorization() {
                (status) in
                switch status {
                case .authorized:
                    if let _ = self.assetCollection{
                        handler()
                    }else{
                       
                    }
                    break
                default:
                    denied()
                }
            }
        }
    }

    func photoAccessForRead(_ handler: @escaping (() -> Void), denied: @escaping (() -> Void)){
        if PHPhotoLibrary.authorizationStatus() == .authorized{
              handler()
        }else if PHPhotoLibrary.authorizationStatus() == .denied{
            denied()
        }else{
            PHPhotoLibrary.requestAuthorization() {
                (status) in
                switch status {
                case .authorized:
                      handler()
                     break
                default:
                    denied()
                }
            }
        }
    }
   
}
