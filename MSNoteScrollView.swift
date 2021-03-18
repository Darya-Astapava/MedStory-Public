//
//  MSNoteWithPhotoScrollView.swift
//  MedStory
//
//  Created by Дарья Астапова on 14.02.21.
//

import UIKit
import SnapKit

class MSNoteScrollView: UIScrollView {
    // MARK: - Properties
    private lazy var edgeInsets = UIEdgeInsets(top: 10,
                                               left: 20,
                                               bottom: 10,
                                               right: 20)
    private lazy var contentOffsets = CGFloat(10)
    
    private lazy var hasImage: Bool = false
    var tapImage: (() -> Void)?
    
    // MARK: - GUI Variables
    private lazy var contentView: UIView = {
        let view = UIView()
        
        view.backgroundColor = .white
        
        return view
    }()
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .systemGray5
        imageView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self,
                                         action: #selector(self.tappedImage))
        imageView.addGestureRecognizer(tap)
        
        return imageView
    }()
    
    private lazy var dateLabel: UILabel = {
        let label = UILabel()
        
        label.numberOfLines = 1
        label.font = .systemFont(ofSize: 17)
        label.textColor = .gray
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        
        return label
    }()
    
    private lazy var categoryLabel: UILabel = {
        let label = UILabel()
        
        label.numberOfLines = 2
        label.font = .systemFont(ofSize: 17)
        label.textColor = .gray
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        return label
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        
        label.font = .boldSystemFont(ofSize: 25)
        label.numberOfLines = 0
        label.textAlignment = .left
        
        return label
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 17)
        
        return label
    }()
    
    // MARK: - Initializations
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.initView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initView() {
        self.addSubview(self.contentView)
        
        self.contentView.addSubviews([self.titleLabel,
                                      self.dateLabel,
                                      self.categoryLabel,
                                      self.imageView,
                                      self.descriptionLabel])
        self.constraints()
    }
    
    // MARK: - Constraints
    private func constraints() {
        self.contentView.snp.updateConstraints { (make) in
            make.size.edges.equalToSuperview()
        }
        
        self.imageView.snp.updateConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(self.imageView.snp.width)
        }
        
        self.dateLabel.snp.updateConstraints { (make) in make.top.equalTo(self.imageView.snp.bottom).offset(self.contentOffsets)
            make.right.equalToSuperview().inset(self.edgeInsets)
        }
        
        self.categoryLabel.snp.updateConstraints { (make) in
            make.top.equalTo(self.imageView.snp.bottom).offset(self.contentOffsets)
            make.left.equalToSuperview().inset(self.edgeInsets)
            make.right.equalTo(self.dateLabel.snp.left).offset(self.contentOffsets).priority(.high)
        }
        
        self.titleLabel.snp.updateConstraints { (make) in
            make.top.equalTo(self.categoryLabel.snp.bottom).offset(self.contentOffsets)
            make.left.right.equalToSuperview().inset(self.edgeInsets)
        }
        
        self.descriptionLabel.snp.updateConstraints { (make) in
            make.top.equalTo(self.titleLabel.snp.bottom).offset(self.contentOffsets)
            make.left.right.equalToSuperview().inset(self.edgeInsets)
        }
    }
    
    // MARK: - Methods
    func setData(title: String,
                 date: String,
                 section: String,
                 description: String?) {
        self.dateLabel.text = date
        self.categoryLabel.text = NSLocalizedString(section, comment: "")
        self.titleLabel.text = title == NSLocalizedString(section, comment: "") ? "" : title
        
        guard let text = description else { return }
        self.descriptionLabel.text = text
        
        setNeedsUpdateConstraints()
    }
    
    @objc func tappedImage() {
        guard self.imageView.image != UIImage(named: "emptyImage")  else { return }
        self.tapImage?()
    }
}
