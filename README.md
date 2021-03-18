# MedStory-Public
Some part from my project - MedStory App. 

The MedStory is the app for saving medical notes of users. The user can create a note with photo and save it on selected medical category. Then when it needed the user can easy find and see his notes. All data store on the Firebase Services.

Architecture: MVC.
Frameworks: UIKit, SnapKit, Firebase Auth, Firecloud, Firebase Storage, Vision, VisionKit.
Techniques: Singleton, Delegate, localization etc.

Presented files: 
1. MSCloudFirestoreManager - all operations with Firestore to saving and reading user notes.
2. MSFirebaseStorageManager - all operations with Firebase Storage to saving and reading user images.
3. MSNotesTableVC - TableViewController that manage the main view of app. The model for table loading from Firestore, depending of choose section.
4. MSNoteVC - ViewController that manage a note view. In this file I use UIGestureRecognizer, UIToolBar etc.
5. MSNoteScrollView - example of view. All UI created programmatically.

This is only several files from the project. If you are a HR, I can show the full project if you request me.
