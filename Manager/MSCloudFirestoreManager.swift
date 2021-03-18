//
//  MSCloudFirestoreManager.swift
//  MedStory
//
//  Created by Дарья Астапова on 25.02.21.
//

import Foundation
import Firebase

class MSCloudFirestoreManager {
    // MARK: - Variables
    // Singleton
    static let share = MSCloudFirestoreManager()
    
    // Link to Firestore to store data
    private let db = Firestore.firestore()
    private var userDocumentRef: DocumentReference? = nil
    
    // MARK: - Initializations
    private init() {
        if let currentUser = Auth.auth().currentUser {
            self.userDocumentRef = Firestore.firestore()
                .collection("users").document(currentUser.uid)
        }
    }
    
    // MARK: - Methods
    /// Saving name and uid when user registered
    func saveUserData(name: String, uid: String ) -> Bool? {
        var result: Bool = false
        
        self.db.collection("users").document(uid)
            .setData(["uid": uid, "name": name]) { (error) in
                result = error != nil ? false : true
            }
        
        return result
    }
    
    /// Return user name in completion handler
    func readUserData(completionHandler: @escaping ((String) -> Void)) {
        self.userDocumentRef?.getDocument(completion: { (document, error) in
            guard error == nil, let doc = document, let name = doc.data()?["name"] as? String else { return }
            completionHandler(name)
        })
    }
    
    /// Create the full path to store data on Firebase depending on selected section and push it
    @discardableResult
    func putDataToFirestore(with note: MSNote) -> DocumentReference? {
        let selectedCollectionRef = self.createSubsectionDocPath(with: note.section)
        
        // Set data
        guard let ref = selectedCollectionRef,
              let currentUser = Auth.auth().currentUser else { return nil }
        let noteCollectionRef = ref.collection("notes").document(note.fullDate)
        noteCollectionRef.setData([
            "uid": currentUser.uid,
            "date": note.date,
            "fullDate": note.fullDate,
            "section": note.section,
            "title": note.title,
            "description": note.description ?? "",
            "imageURL": note.imageURL ?? "",
            "textImage": note.imageText ?? ""
        ]) { err in
            guard let error = err else { return }
            print("Error adding document: \(error)")
        }
        
        return noteCollectionRef
    }
    
    /// Put array with user notes from Firebase in completion handler. Specify the section to pull only section notes. If section is nil, array will be contains all user notes.
    func getDataFromFirestore(section: String? = nil,
                              completionHandler: @escaping ([MSNote]) -> Void) {
        var array: [MSNote] = []
        
        //
        if let section = section {
            let selectedCollectionRef = self.createSubsectionDocPath(with: section)
            guard let ref = selectedCollectionRef else { return }
            let noteCollectionRef = ref.collection("notes")
            
            noteCollectionRef.order(by: "date", descending: true)
                .getDocuments { [weak self] (querySnapshot, err) in
                    if let err = err {
                        // TODO: - handle error
                        print("Error getting documents: \(err)")
                    } else {
                        for document in querySnapshot!.documents {
                            self?.parseDataToMSNote(with: document) { (note) in
                                array.append(note)
                            }
                        }
                        completionHandler(array)
                    }
                }
        } else {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            
            self.db.collectionGroup("notes")
                .whereField("uid", isEqualTo: uid).order(by: "date", descending: true)
                .getDocuments { [weak self] (querySnapshot, err) in
                    if let err = err {
                        // TODO: - handle error
                        print("Error getting documents: \(err)")
                    } else {
                        for document in querySnapshot!.documents {
                            self?.parseDataToMSNote(with: document) { (note) in
                                array.append(note)
                            }
                        }
                        completionHandler(array)
                    }
                }
        }
    }
    
    /// Remove note from Firestore.
    func removeNoteFromFirestore(note: MSNote) {
        let selectedCollectionRef = self.createSubsectionDocPath(with: note.section)
        guard let ref = selectedCollectionRef else { return }
        let noteCollectionRef = ref.collection("notes").document(note.fullDate)
        
        noteCollectionRef.delete { (error) in
            if let error = error {
                // TODO: handle error
                print("Error removing document: \(error)")
            } else {
                print("Document successfully removed!")
            }
        }
    }
    
    /// Parse document snapshot to MSNote type. Put MSNote object in completion handler.
    private func parseDataToMSNote(with document: QueryDocumentSnapshot,
                                   completionHandler: @escaping (MSNote) -> Void) {
        
        guard let _ = document.data()["uid"] as? String,
              let fullDate = document.data()["fullDate"] as? String,
              let date = document.data()["date"] as? String,
              let section = document.data()["section"] as? String,
              let title = document.data()["title"] as? String,
              let description = document.data()["description"] as? String,
              let imageURL = document.data()["imageURL"] as? String,
              let imageText = document.data()["textImage"] as? String
        else {
            Swift.debugPrint("Cannot parse data")
            return
        }
        
        let note = MSNote(fullDate: fullDate,
                          date: date,
                          section: section,
                          title: title,
                          description: description,
                          imageURL: imageURL,
                          imageText: imageText)
        
        completionHandler(note)
        Swift.debugPrint("Parse data from Firebase snapshot to note - ", note)
    }
    
    /// Return subsection collection path
    func createSubsectionDocPath(with section: String) -> DocumentReference? {
        let mainSectionCollectionPath = self.createMainCollectionPath(with: section)
        let subsectionsCollectionPath = mainSectionCollectionPath?.collection("subsections")
        
        switch section {
        case "procedures",
             "vaccinations":
            return subsectionsCollectionPath?.document(section)
        default:
            return subsectionsCollectionPath?.document(section)
        }
    }
    
    /// Return main section document path in Firebase
    private func createMainCollectionPath(with section: String) -> DocumentReference? {
        var selectedSectionRef: DocumentReference?
        
        guard let userRef = self.userDocumentRef else { return nil }
        let sectionsRef = userRef.collection("sections")
        
        // Create path with selected section
        switch section {
        case "stool",
             "blood",
             "urine",
             "mensAnalyzes",
             "gynecologistAnalyzes",
             "other analyzes":
            selectedSectionRef = sectionsRef.document("analyzes")
        case "DTherapist",
             "DSurgeon",
             "DOrthopedist",
             "orthodontist",
             "DXRay",
             "other dental":
            selectedSectionRef = sectionsRef.document("dentistry")
        case "allergist",
             "gastroenterologist",
             "hematologist",
             "hepatologist",
             "gynecologist",
             "dermatologist",
             "immunologist",
             "cardiologist",
             "cosmetologist",
             "mammologist",
             "neurologist",
             "nephrologist",
             "otolaryngologist",
             "ophthalmologist",
             "proctologist",
             "psychotherapist",
             "pulmanologist",
             "rheumatologist",
             "therapist",
             "traumatologist",
             "urologist",
             "phlebologist",
             "surgeon",
             "endocrinologist",
             "other specialists":
            selectedSectionRef = sectionsRef.document("specialists")
        case "bia",
             "helicobacterBreathTest",
             "capsuleEndoscopy",
             "cardiogram",
             "colonoscopy",
             "ct",
             "mri",
             "mammography",
             "xRay",
             "spirometry",
             "ultrasound",
             "tee",
             "holter",
             "abpm",
             "egd",
             "other examination":
            selectedSectionRef = sectionsRef.document("body examinations")
        case "procedures":
            selectedSectionRef = sectionsRef.document("procedures")
        case "vaccinations":
            selectedSectionRef = sectionsRef.document("vaccinations")
        default:
            Swift.debugPrint("Error creating section path with \(section)")
            return nil
        }
        return selectedSectionRef
    }
}
