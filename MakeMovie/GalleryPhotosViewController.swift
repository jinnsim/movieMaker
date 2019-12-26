 
import UIKit
import Photos
import PhotosUI 

class AlbumModel {
    let name:String
    let count:Int
    let collection:PHFetchResult<PHAsset>
    init(name:String, count:Int, collection:PHFetchResult<PHAsset>) {
        self.name = name
        self.count = count
        self.collection = collection
    }
}

enum collectionViewSeq {
    case category
    case details
}
enum galleryMode{
    case cover
    case contents
    case addToPublish
    case updateToPublish
}
typealias SelectedFromContent = (Int,Bool) -> Void
typealias SelectCover = (GalleryPublish) -> Void
typealias AddPhotoToPublish = (GalleryPublish) -> ()
typealias UpdatePublish = (GalleryPublish) -> ()

class GalleryPhotosViewController: UIViewController {
    var publishModel = GalleryPublish()
    var galleryMode: galleryMode = .cover
    var selectCover: SelectCover?
    var addPhotoToPublish: AddPhotoToPublish?
    var updatePublish: UpdatePublish?
    var itemIndex: Int = 0
    var addPhotoToPublishCount: Int = 0
    let ratio = UIScreen.main.bounds.size.width / 360
    let width = UIScreen.main.bounds.size.width / 2
    var album: [AlbumModel] = [AlbumModel]()
    var selectedCategory: Int = 0
    var selectedItem: [[Int:Int]] = [[:]]
    
    let btnClose: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.close)
            button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let btnDone: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "icPhotoSelect"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let titleLable: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        label.textColor = UIColor.systemGray
        label.text = "Jiyul"
        return label
    }()
    
    let subTitleLable: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor.systemGray
        label.text =  "select photos"
        return label
    }()
    
    lazy var collectionViewCategory: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.estimatedItemSize = CGSize(width: 114 * ratio , height: 138 * ratio)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.showsHorizontalScrollIndicator = false
        cv.showsVerticalScrollIndicator = false
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = UIColor.clear
        cv.delegate = self
        cv.dataSource = self
        return cv
    }()
    
    lazy var collectionViewDetail: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.estimatedItemSize = CGSize(width: 114 * ratio, height: 114 * ratio)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.showsHorizontalScrollIndicator = false
        cv.showsVerticalScrollIndicator = true
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = UIColor.clear
        cv.delegate = self
        cv.dataSource = self
        return cv
    }()
    class func instantiate(_ galleryMode: galleryMode, publishModel: GalleryPublish? = GalleryPublish()) -> GalleryPhotosViewController{
        let vc =  GalleryPhotosViewController()
            vc.galleryMode = galleryMode
            vc.publishModel = publishModel!
            vc.addPhotoToPublishCount = vc.publishModel.selectedItem?.count ?? 0
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        
        selectedItem.removeAll()
       
        PhotoHelper.shared.photoAccessForRead({
             self.listAlbums()
        }) {
            self.photoDenied({
                 
            })
        }
        collectionViewCategory.tag = collectionViewSeq.category.hashValue
        collectionViewCategory.register(GalleryPhotoCollectionViewCell.self, forCellWithReuseIdentifier: "GalleryCategoryCell")
        collectionViewDetail.tag = collectionViewSeq.details.hashValue
        collectionViewDetail.register(GalleryPhotoDetailCollectionViewCell.self, forCellWithReuseIdentifier: "GalleryCategoryDetailCell")
        
        settingView()
    
    }
 
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
       // BGHelper.shared.saveTempGallery(self.publishModel)
    }
}

extension GalleryPhotosViewController {
    @objc func close(){
        self.dismiss(animated: true) {
            
        }
    }
    
    @objc func selected(){
        guard selectedItem.count > 0 else {
            return
        }
        
        guard  galleryMode == .cover || galleryMode == .addToPublish || galleryMode == .updateToPublish  else {
            //publish
            publishModel.album = album
            publishModel.selectedItem = self.selectedItem
 
            var images:[UIImage] = []
            for item  in  publishModel.selectedItem!{
                let index = item.first
                let album = publishModel.album?[index!.key]
                let asset = album?.collection.object(at: index!.value)
                let options = PHImageRequestOptions()
                   options.deliveryMode = .highQualityFormat
                   options.isSynchronous = true
                PHImageManager.default().requestImage(for: asset!, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: options) { (image, info) in
                    images.append(image!)
                   }
                
                print(item)
            }
            let vc = VideoMakerViewController()
            vc.images = images
            vc.returnTempUrl = {(url) in
                self.saveToLivePhoto(url)
            }
            vc.createLiveWallpaper()

            return
        }
        

    }
    
    struct FilePaths {
        static let documentsPath : AnyObject = NSSearchPathForDirectoriesInDomains(.cachesDirectory,.userDomainMask,true)[0] as AnyObject
        struct VidToLive {
            static var livePath = FilePaths.documentsPath.appending("/")
        }
    }
    
    func saveToLivePhoto(_ videoImageUrl: String){
        //  let videoImageUrl = "http://virginia.bghcdn.ogqcorp.com/live_screens/f600/preview/1e2af.mp4"
        
        DispatchQueue.global(qos: .background).async {
            let url = URL(fileURLWithPath: videoImageUrl)
            if   let urlData = NSData(contentsOf: url) {
                let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0];
                let filePath="\(documentsPath)/tempFile.mp4"
                DispatchQueue.main.async {
                    urlData.write(toFile: filePath, atomically: true)
                    PHPhotoLibrary.shared().performChanges({
                        //  PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL(fileURLWithPath: filePath))
                    }) { completed, error in
                        if completed {
                            print("Video is saved!")
                            self.loadVideoWithVideoURL(filePath)
                            
                        }
                    }
                }
            }
        }
        
    }
        func loadVideoWithVideoURL(_ filePath: String) {
        let videoURL = URL(fileURLWithPath: filePath)
        let asset = AVURLAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
            let time = NSValue(time: CMTimeMakeWithSeconds(CMTimeGetSeconds(asset.duration)/2, preferredTimescale: asset.duration.timescale))
        generator.generateCGImagesAsynchronously(forTimes: [time]) { [weak self] _, image, _, _, _ in
            if let image = image, let data = UIImage(cgImage: image).pngData() {
                let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                let imageURL = urls[0].appendingPathComponent("image.jpg")
                try? data.write(to: imageURL, options: [.atomic])
                
                let image = imageURL.path
                let mov = videoURL.path
                let output = FilePaths.VidToLive.livePath
                let assetIdentifier = UUID().uuidString
                let _ = try? FileManager.default.createDirectory(atPath: output, withIntermediateDirectories: true, attributes: nil)
                do {
                    try FileManager.default.removeItem(atPath: output + "/IMG.JPG")
                    try FileManager.default.removeItem(atPath: output + "/IMG.MOV")
                    
                } catch {
                    
                }
                JPEG(path: image).write(output + "/IMG.JPG",
                                        assetIdentifier: assetIdentifier)
                QuickTimeMov(path: mov).write(output + "/IMG.MOV",
                                              assetIdentifier: assetIdentifier)
                
                self?.exportLivePhoto(filePath)
                
            }
        }
    }
      
    func exportLivePhoto (_ filePath: String) {
      
        PHPhotoLibrary.shared().performChanges({ () -> Void in
            let creationRequest = PHAssetCreationRequest.forAsset()
            let options = PHAssetResourceCreationOptions()
            
            
            creationRequest.addResource(with: PHAssetResourceType.pairedVideo, fileURL: URL(fileURLWithPath: FilePaths.VidToLive.livePath + "/IMG.MOV"), options: options)
         
            creationRequest.addResource(with: PHAssetResourceType.photo, fileURL: URL(fileURLWithPath: FilePaths.VidToLive.livePath + "/IMG.JPG"), options: options)
             
            
        }, completionHandler: { (success, error) -> Void in
            self.close()
            
            if !success {
                print((error?.localizedDescription)!)
            }
        })
    }
    
    @objc func selectedImage(_ sender: UIButton){
      
        if galleryMode == .cover || galleryMode == .updateToPublish || galleryMode == .addToPublish  {
            self.selectedItem.removeAll()
            for c in self.collectionViewDetail.visibleCells {
                let cell = c as! GalleryPhotoDetailCollectionViewCell
                cell.checkBtn.isSelected = false
                cell.imageSelected(false)
            }
        }
 
        let val = [selectedCategory:sender.tag]
        let contains =  self.selectedItem.contains(val)
        if contains == true {
            print("exist")
            self.selectedItem.remove(at: self.selectedItem.firstIndex(of: val)!)
        }else{
            print("none")
           
            self.selectedItem.append(val)
        }
        for cell in self.collectionViewDetail.visibleCells {
            self.collectionViewDetail.reloadData()
            //self.collectionViewDetail.reloadItems(at: [IndexPath(item: cell.tag, section: 0)])
        }
    }
    
   
    
    func settingView(){
        btnClose.addTarget(self, action: #selector(close), for: .touchUpInside)
        btnDone.addTarget(self, action: #selector(selected), for: .touchUpInside)
        
        self.view.addSubview(btnClose)
        self.view.addSubview(btnDone)
        
        btnClose.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 16).isActive = true
        btnDone.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -16).isActive = true
        
        self.view.addSubview(titleLable)
        titleLable.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 44).isActive = true
        titleLable.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -44).isActive = true
        
        
        if #available(iOS 11, *) {
            let guide = view.safeAreaLayoutGuide
         btnClose.topAnchor.constraint(equalTo: guide.topAnchor, constant: 16).isActive = true
         btnDone.topAnchor.constraint(equalTo: guide.topAnchor, constant: 16).isActive = true
         titleLable.topAnchor.constraint(equalTo: guide.topAnchor, constant: 16).isActive = true
        }else{
         btnClose.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 40).isActive = true
         btnDone.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 40).isActive = true
         titleLable.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 40).isActive = true
            
        }
       
        self.view.addSubview(subTitleLable)
        subTitleLable.topAnchor.constraint(equalTo: titleLable.bottomAnchor, constant: 26).isActive = true
        subTitleLable.centerXAnchor.constraint(equalTo: self.view.centerXAnchor, constant: 0).isActive = true
        
        self.view.addSubview(collectionViewCategory)
        collectionViewCategory.topAnchor.constraint(equalTo: self.btnClose.bottomAnchor, constant: 56).isActive = true
        collectionViewCategory.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 2 * ratio).isActive = true
        collectionViewCategory.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -2 * ratio).isActive = true
        collectionViewCategory.heightAnchor.constraint(equalToConstant: 139 * ratio  ).isActive = true
        
        self.view.addSubview(collectionViewDetail)
        collectionViewDetail.topAnchor.constraint(equalTo: self.collectionViewCategory.bottomAnchor, constant: 0).isActive = true
        collectionViewDetail.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 2 * ratio).isActive = true
        collectionViewDetail.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -14 * ratio).isActive = true
        collectionViewDetail.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 7).isActive = true
    }

    //  권한
      func photoDenied(_ handler: @escaping (() -> Void)){
        DispatchQueue.main.async {
            handler()
  
        }
    }
 
    
    func listAlbums() {
   
        // 옵션 값
        let fetchOptions = PHFetchOptions()
        //fetchAssetCollectionsWithType의 subtype 타입값을 설정하여 가지고 오고 싶은 앨범만 선택
        let Customalbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        let SmartAlbumFavorites = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumFavorites, options: fetchOptions)
        let Cmeraroll = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: fetchOptions)
        // 각 앨범의 사진 타이틀이름, 수 가져오기
        [Cmeraroll,SmartAlbumFavorites,  Customalbums].forEach {
            $0.enumerateObjects { collection, index, stop in
                let album = collection as PHAssetCollection  
                // PHAssetCollection 의 localizedTitle 을 이용해 앨범 타이틀 가져오기
                let albumTitle : String = album.localizedTitle!
                // 이미지만 가져오도록 옵션 설정
                let fetchOptions2 = PHFetchOptions()
                fetchOptions2.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
                fetchOptions2.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                
                let assetsFetchResult: PHFetchResult = PHAsset.fetchAssets(in: album, options: fetchOptions2)
                // PHFetchResult 의 count 을 이용해 앨범 사진 갯수 가져오기
                let albumCount = assetsFetchResult.count
                // 저장
                let newAlbum = AlbumModel(name:albumTitle, count: albumCount, collection:assetsFetchResult)
                
                //앨범 정보 추가
                if albumCount > 0 {
                self.album.append(newAlbum)
                }
            }
        }

    }
  
    
}

extension GalleryPhotosViewController: UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        switch collectionView.tag {
        case collectionViewSeq.category.hashValue:
            guard  self.selectedCategory != indexPath.row else{
                return
            }
            self.selectedCategory = indexPath.row
            
            for c in self.collectionViewCategory.visibleCells {
                let cell = c as! GalleryPhotoCollectionViewCell
                    cell.albumLable.font = UIFont.systemFont(ofSize: 12, weight: self.selectedCategory == cell.tag ? .bold : .regular)
            }
            
            self.collectionViewDetail.scrollToItem(at:  IndexPath(item: 0, section: 0), at: .top, animated: false)
            self.collectionViewDetail.reloadData()
            return
        default:
        
          
            return
        }
        
    }
}

extension GalleryPhotosViewController: UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        switch collectionView.tag {
        case collectionViewSeq.category.hashValue:
             return self.album.count == 0 ? 1 : self.album.count
        default:
             return album[selectedCategory].count
        }
     }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch collectionView.tag {
        case collectionViewSeq.category.hashValue:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GalleryCategoryCell", for: indexPath) as! GalleryPhotoCollectionViewCell
                cell.tag = indexPath.row
                let item = album[indexPath.row  ]
                let asset = item.collection.object(at: 0)
               
                
                cell.albumLable.text = item.name
                cell.albumLable.font = UIFont.systemFont(ofSize: 12, weight: self.selectedCategory == indexPath.row ? .bold : .regular)
                let options = PHImageRequestOptions()
                options.deliveryMode = .opportunistic
                options.isSynchronous = false
                PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: width, height: width), contentMode: .aspectFit, options: options) { (image, info) in
                    DispatchQueue.main.async {
                        cell.thumbnailImageView.image = image
                    }
                }
          
            return cell
        default:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GalleryCategoryDetailCell", for: indexPath) as! GalleryPhotoDetailCollectionViewCell
                cell.tag = indexPath.row
                let item = album[selectedCategory  ]
                let asset = item.collection.object(at: indexPath.row)
                
                let options = PHImageRequestOptions()
                options.deliveryMode = .opportunistic
                options.isSynchronous = false
                PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: width, height: width), contentMode: .aspectFit, options: options) { (image, info) in
                    DispatchQueue.main.async {
                        cell.thumbnailImageView.image = image
                    }
                }
            
            cell.checkBtn.tag = indexPath.row
            cell.checkBtn.addTarget(self, action: #selector(selectedImage(_:)), for: .touchUpInside)
            
            if let index = self.selectedItem.firstIndex(of: [selectedCategory : indexPath.row]) {
                if galleryMode == .cover || galleryMode == .addToPublish || galleryMode == .updateToPublish  {
                  cell.checkBtn.setImage(UIImage(named: "icPhotoSelect"), for: .selected)
                }else{
                  cell.checkBtn.setImage(UIImage(named: "icPhotoSelectBack")!, for: .selected)
                  cell.checkBtn.setTitle("\(index + 1)", for: .selected) 
                }
                cell.checkBtn.isSelected = true
                cell.imageSelected(true)
            }else{
              cell.checkBtn.isSelected = false
              cell.imageSelected(false)
            }
          
            
           
            return cell
        }
       
    }
    
    
}
