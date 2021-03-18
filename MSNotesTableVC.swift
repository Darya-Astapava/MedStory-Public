//
//  MSNotesTableVC.swift
//  MedStory
//
//  Created by Дарья Астапова on 22.01.21.
//

import UIKit
import VisionKit
import Vision
import SnapKit
import FirebaseUI

class MSNotesTableVC: UITableViewController, UploadNotesTableVCDelegate {
    // MARK: - Variables
    private var model: [MSNote]? = nil {
        didSet {
            self.tableView.reloadData()
            self.showImageIfTableIsEmpty()
        }
    }
    
    private var section: String? = nil
    
    // MARK: - GUI Variables
    // Background image to empty table.
    private lazy var tableBackgroundImage = MSEmptyTableUIView()
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupNavigationBar()
        MSFirebaseStorageManager.share.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationController?.setToolbarHidden(true, animated: true)
        if self.title == nil {
            self.title = NSLocalizedString("Recent", comment: "")
        }
        
        self.createModel()
        self.setupTableView()
        MSTabBarController.shareTabBar.showAddButton(true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    // MARK: - TableView Data Source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        guard let model = self.model else { return 0 }
        return model.count
    }
    
    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(
            withIdentifier: MSDocumentTableViewCell.reuseIdentifier,
            for: indexPath)
        if let cell = cell as? MSDocumentTableViewCell {
            if let model = self.model {
                let document = model[indexPath.row]
                
                MSFirebaseStorageManager.share.createFullImagePathFromStorage(
                    ref: document.imageURL ?? "") { (imageRef) in
                    cell.set(title: document.title,
                             section: NSLocalizedString(document.section, comment: ""),
                             date: document.date)
                    MSFirebaseStorageManager.share
                        .setImageToImageView(to: cell.documentImageView, with: document)
                }
            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        if let model = self.model {
            let document = model[indexPath.row]
            
            let vc = MSNoteVC()
            vc.setNote(with: document)
            self.navigationController?.pushViewController(vc,
                                                          animated: true)
        }
    }
    
    // Swipe gestures to open menu and remove cells
    override func tableView(_ tableView: UITableView,
                            commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete:
            Swift.debugPrint("delete")
            self.tableView.performBatchUpdates({
                guard let model = self.model else { return }
                
                MSFirebaseStorageManager.share.removeImageFromStorage(
                    ref: model[indexPath.row].imageURL)
                MSCloudFirestoreManager.share.removeNoteFromFirestore(
                    note: model[indexPath.row])
                self.model?.remove(at: indexPath.row)
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
                self.tableView.reloadData()
            }, completion: { (isSuccess) in
                Swift.debugPrint(isSuccess ? "Row was deleted"
                                    : "Couldn't delete this row")
            })
        default:
            break
        }
    }
    
    // MARK: - Methods
    func setTitle(with section: String) {
        self.title = NSLocalizedString(section, comment: "")
        self.section = section
    }
    
    private func createModel() {
        MSCloudFirestoreManager.share
            .getDataFromFirestore(section: self.section) { [weak self] (model) in
                self?.model = model
                self?.tableView.reloadData()
            }
    }
    
    /// Shows background image when the table is empty.
    private func showImageIfTableIsEmpty() {
        if let model = self.model, !model.isEmpty {
            self.tableView.backgroundView = .none
        } else {
            self.tableView.backgroundView = self.tableBackgroundImage
        }
    }
    
    /// Create additional profile
    private func addProfileHandler(action: UIAction) {
        print("addProfileHandler ", action)
        // TODO: Create a second user profile.
    }
    
    private func setupNavigationBar() {
        self.navigationController?.setNavigationBarHidden(false,
                                                          animated: false)
        self.setupBarButtonMenu()
    }
    
    private func setupBarButtonMenu() {
        let rightBarButton = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis.circle"),
            style: .plain,
            target: self,
            action: nil)
        self.navigationItem.rightBarButtonItem = rightBarButton
        
        let menu = UIMenu(title: "",
                          children: [
                            UIAction(title: NSLocalizedString("Settings", comment: ""),
                                     image: UIImage(systemName: "gearshape"),
                                     handler: self.settingsHandler(action:)),
                            UIAction(title: NSLocalizedString("Add profile", comment: ""),
                                     image: UIImage(systemName: "person.badge.plus"),
                                     handler: self.addProfileHandler(action:))
                          ])
        if #available(iOS 14.0, *) {
            rightBarButton.menu = menu
        } else {
            print("The system version is older than ios 14")
        }
    }
    
    private func setupTableView() {
        self.tableView.register(MSDocumentTableViewCell.self,
                                forCellReuseIdentifier: "DocumentCell")
        self.tableView.tableFooterView = UIView()
        self.showImageIfTableIsEmpty()
    }
    
    /// Open SettingsVC
    private func settingsHandler(action: UIAction) {
        print("settingsHandler ", action)
        let settingsVC = MSSettingsVC()
        self.navigationController?.pushViewController(settingsVC,
                                                      animated: true)
    }
    
    /// Required method
    func uploadTable() {
        self.createModel()
        Swift.debugPrint("Delegate worked and the table should have been updated")
    }
}

