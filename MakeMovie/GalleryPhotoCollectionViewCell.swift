 

import UIKit

class GalleryPhotoCollectionViewCell: UICollectionViewCell {
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
    
    let albumLable: UILabel = {
       let label = UILabel()
           label.translatesAutoresizingMaskIntoConstraints = false
           label.textAlignment = .left
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .white
        settingView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension GalleryPhotoCollectionViewCell{
    func settingView(){
        self.addSubview(thumbnailImageView)
        thumbnailImageView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: 0).isActive = true
        thumbnailImageView.topAnchor.constraint(equalTo: self.topAnchor, constant: 0).isActive = true
        thumbnailImageView.widthAnchor.constraint(equalToConstant: 100 * ratio).isActive = true
        thumbnailImageView.heightAnchor.constraint(equalToConstant: 100 * ratio).isActive = true
        
        self.addSubview(albumLable)
        albumLable.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 14 * ratio).isActive = true
        albumLable.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -15 * ratio).isActive = true
        
    }
}
