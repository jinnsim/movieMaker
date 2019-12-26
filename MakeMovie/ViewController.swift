 
import UIKit

class ViewController: UIViewController {

    let imageview: UIImageView = {
       let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        PhotoHelper.shared.photoAccessForRead({
                   
               }) {
                 
               }
 
        self.view.addSubview(imageview)
        imageview.frame = self.view.bounds
        
        imageview.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showVc)))
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
     
        
    }
    
    @objc func showVc(){
        let vc = GalleryPhotosViewController.instantiate(galleryMode.contents)
             vc.modalPresentationStyle = .overFullScreen
             self.present(vc, animated: true)
    }

}

