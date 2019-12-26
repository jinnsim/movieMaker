 
import CoreFoundation
import Foundation

enum galleryLiense: String{
  case WEB
  case DWNLD
  case GALLERY
}
struct GalleryPublish   {
 
    var album: [AlbumModel]?
    var colverImage: [Int:Int]?
    var title: String?
    var subtitle: String?
    var tags: [String]?
    var position: String?
    var name: String?
    var selectedItem: [[Int:Int]]?
 
    var metaInfo:[Int:GalleryMetaInfo]  = [:]
  
}

struct GalleryPublishTemp: Codable   {
 
    var colverImage: [Int:Int]?
    var title: String?
    var subtitle: String?
    var tags: [String]?
    var position: String?
    var name: String?
    var selectedItem: [[Int:Int]]?
    
    var metaInfo:[Int:GalleryMetaInfo]  = [:]
    
}
struct GalleryMetaInfo: Codable {
    var title: String?
    var description: String?
    var licenseInfo: [String: String]  = [:]
    var premiumInfo: GalleryPremiumInfo?
}

struct GalleryPremiumInfo: Codable {
    var camera_model: String? = nil
    var lens_model: String? = nil
    var aperture: String? = nil
    var shutter_speed: String? = nil
    var exposure: String? = nil
    var contrast: String? = nil
    var tone_highlight: String? = nil
    var tone_shadow: String? = nil
    var white_balance_temp: String? = nil
    var white_balance_tint: String? = nil
    var saturation: String? = nil
    var sharpness: String? = nil
    var fade: String? = nil
    var vignette: String? = nil
    var border: String? = nil
    var location_name: String? = nil
    var latitude: String? = nil
    var longitude: String? = nil
    var time_of_photoshoot: String? = nil
    var map_image: String? = nil
}

struct Artworks: Codable {
    var arrangement: String = ""
    var title: String = ""
    var description: String = ""
    var artwork_content_hash: String = ""
    var artwork_extension:String = "jpg"
    var media_type: String = "IMAGE"
    var sales_policy: String = ""
    var premium_info: String = ""
}

