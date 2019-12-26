 
import UIKit

class GalleryPhotoDetailCollectionViewCell: UICollectionViewCell {
    let ratio = UIScreen.main.bounds.size.width / 360
    let thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 11.0, *) {
            imageView.accessibilityIgnoresInvertColors = true
        }
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
 
    let checkBtn : UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.setImage(UIImage(named: "oval"), for: .normal)
        button.setImage(UIImage(named: "icPhotoSelect"), for: .selected)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.imageEdgeInsets = UIEdgeInsets(top: 7, left: 11, bottom: 11, right: 7)
        button.titleEdgeInsets = UIEdgeInsets(top: -2,left: -9,bottom: 2,right: 9)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13.5)
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white
        settingView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension GalleryPhotoDetailCollectionViewCell{
    func settingView(){
        self.addSubview(thumbnailImageView)
        thumbnailImageView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: 0).isActive = true
        thumbnailImageView.topAnchor.constraint(equalTo: self.topAnchor, constant: 0).isActive = true
        thumbnailImageView.widthAnchor.constraint(equalToConstant: 100 * ratio).isActive = true
        thumbnailImageView.heightAnchor.constraint(equalToConstant: 100 * ratio).isActive = true
        
        self.addSubview(checkBtn)
        checkBtn.rightAnchor.constraint(equalTo: self.rightAnchor, constant: 0).isActive = true
        checkBtn.topAnchor.constraint(equalTo: self.topAnchor, constant: 0).isActive = true
        checkBtn.widthAnchor.constraint(equalToConstant: 40).isActive = true
        checkBtn.heightAnchor.constraint(equalToConstant: 40).isActive = true
  
    }
    
    func imageSelected(_ val: Bool){
        self.thumbnailImageView.layer.borderColor = UIColor.black.cgColor
        self.thumbnailImageView.layer.borderWidth = val == true ? 3 : 0
    }
}
