//
//  MSFirebaseStorageManager.swift
//  MedStory
//
//  Created by Дарья Астапова on 25.02.21.
//

import Foundation
import Firebase

struct MSFirebaseStorageManager {
    // MARK: - Variables
    // Singleton
    static var share = MSFirebaseStorageManager()
    
    weak var delegate: UploadNotesTableVCDelegate?
    
    // Link to Firebase Storage to store images
    let storage = Storage.storage()
    lazy var storageRef = storage.reference()
    lazy var usersRef = self.storageRef.child("users")
    
    // MARK: - Initializations
    private init() { }
    
    // MARK: - Methods
    /// Store image in Firebase Storage and put reference in completion handler.
    func pushImageToStorage(image: UIImage,
                           imageID: String,
                           completionHandler: ((String) -> Void)?,
                           errorHandler: ((Error?) -> Void)?) {
        // Check user authorization
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        // Convert the image to jpeg data
        let data = image.jpegData(compressionQuality: 0.3)
        
        // Create the final image id
        let clearImageId = imageID.filter("0123456789.".contains)
        
        // Create a reference
        let imageRef = uid + "/" + clearImageId
        let fullRef = MSFirebaseStorageManager.share.usersRef.child(imageRef)
        
        guard let imageData = data else {
            print ("Error with image.pngData()")
            return }
        
        // Start loading
        let _ = fullRef.putData(imageData,
                                         metadata: nil) { (metadata, error) in
            if let error = error {
                errorHandler?(error)
            } else {
                completionHandler?(imageRef)
                self.delegate?.uploadTable()
            }
        }
    }
    
    // TODO: - remove this method safely
    /// Put full image path from Firebase Storage in completion handler.
    func createFullImagePathFromStorage(ref: String, completionHandler: @escaping (StorageReference) -> Void) {
            // Get image from storage
            let path = MSFirebaseStorageManager.share.usersRef.child(ref)
        completionHandler(path)
    }
    
    /// Set image from note into the image view using reference. Don't put the image into the image view, only shows.
    func setImageToImageView(to imageView: UIImageView, with note: MSNote) {
        if let imageRef = note.imageURL {
            Swift.debugPrint("setting image to image view with reference \(imageRef)")
            let fullImageRef = MSFirebaseStorageManager.share.usersRef.child(imageRef)
            imageView.sd_setImage(with: fullImageRef,
                                  placeholderImage: UIImage(named: "emptyImage"))
        } else {
            Swift.debugPrint("note has not image")
        }
    }
    
    func removeImageFromStorage(ref: String?) {
        guard let ref = ref else { return }
        let path = MSFirebaseStorageManager.share.usersRef.child(ref)
        path.delete { (error) in
               // TODO: - handle error
        }
    }
}

protocol UploadNotesTableVCDelegate: class {
    func uploadTable() -> Void
}

// TODO: - Перенести из DocumentCameraVC процесс распознования текста. Передать распознанный текст вместе со всеми данными в Cloud Firestore. Применить процесс распознования текста к выбранным из галереи изображениям. Распозновать текст при нажатии на save, чтобы не тратить ресурсы в случае если пользователь отменит сохранение заметки. Скорее всего сделать это в модели MSNote, а не в контроллере.
