//
//  MSNoteVC.swift
//  MedStory
//
//  Created by Дарья Астапова on 26.01.21.
//

import UIKit
import SnapKit

class MSNoteVC: UIViewController {
    // MARK: - Properities
    private lazy var note: MSNote? = nil
    
    // MARK: - GUI Variables
    private lazy var mainView: MSNoteScrollView = {
        let view = MSNoteScrollView()
        
        view.showsVerticalScrollIndicator = false
        view.tapImage = { [weak self] in
            self?.showPhotoScrollView()
        }
        
        return view
    }()
    
    private lazy var editButton = UIBarButtonItem(
        barButtonSystemItem: .edit,
        target: self,
        action: #selector(self.pressEditButton))
    
    private var photoScrollView: MSPhotoScrollView = {
        let view = MSPhotoScrollView(frame: UIScreen.main.bounds)
        
        view.backgroundColor = .black
        view.isUserInteractionEnabled = true
        
        return view
    }()
    
    private lazy var tapGesture: UITapGestureRecognizer = {
       let tap = UITapGestureRecognizer(target: self,
                                       action: #selector(tappedScrollView))
        tap.numberOfTapsRequired = 1
        tap.require(toFail: self.photoScrollView.zoomingTap)
        
        return tap
    }()
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .white
        self.view.addSubview(self.mainView)
        self.constraints()
        self.setupToolBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.prefersLargeTitles = false
        self.tabBarController?.tabBar.isHidden = true
        MSTabBarController.shareTabBar.showAddButton(false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.tabBarController?.tabBar.isHidden = false
    }
    
    // MARK: - Actions
    /// Transit to MSAddNoteVC
    @objc private func pressEditButton() {
        let vc = MSAddNoteVC()
        guard let data = self.note else { return }
        vc.title = data.title
        
        vc.setNoteDataToEdit(note: data)
        self.navigationController?.show(vc, sender: nil)
    }
    
    /// Shows full screen image view without navigation and tool bars. Using pinch and pan gesture.
    private func showPhotoScrollView() {
        self.view.addSubview(self.photoScrollView)
        
        self.photoScrollView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        self.photoScrollView.addGestureRecognizer(self.tapGesture)
        
        self.loadImage(to: self.photoScrollView.imageZoomView)
        
        MSTabBarController.shareTabBar.showAddButton(false)
        self.navigationController?.isNavigationBarHidden = true
        self.navigationController?.isToolbarHidden = true
    }
    
    /// Hide full screen image view when user tapped it. Shows navigation and tool bars again.
    @objc private func tappedScrollView() {
        self.navigationController?.isNavigationBarHidden = false
        self.navigationController?.isToolbarHidden = false
        self.photoScrollView.removeFromSuperview()
    }
    
    // MARK: - Setter
    /// Call on the previous view controller and set note data.
    func setNote(with note: MSNote) {
        self.note = note
        
        self.mainView.setData(title: note.title,
                              date: note.date.reverseDateString(),
                              section: note.section,
                              description: note.description)
        self.loadImage(to: self.mainView.imageView)
    }
    
    // MARK: - Methods
    private func setupToolBar() {
        let toolbar = UIToolbar()
        
        let tabHeight = self.tabBarController?.tabBar.frame.height
        
        guard let height = tabHeight else { return }
        toolbar.frame = CGRect(x: 0,
                               y: self.view.bounds.height - height,
                               width: self.view.bounds.width,
                               height: height)
        
        toolbar.setItems([UIBarButtonItem(systemItem: .flexibleSpace),
                          self.editButton],
                         animated: true)
        
        self.view.addSubview(toolbar)
        
        toolbar.snp.updateConstraints { (make) in
            make.left.right.bottom.equalTo(self.view.safeAreaLayoutGuide)
        }
    }
    
    /// Set an image from Firebase Storage, using  a reference from note, in the image view.
    private func loadImage(to imageView: UIImageView) {
        guard let note = self.note else { return }
        MSFirebaseStorageManager.share.setImageToImageView(to: imageView, with: note)
    }
    
    // MARK: - Constraints
    private func constraints() {
        self.mainView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
}
