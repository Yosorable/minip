//
//  ImagePreview.swift
//  minip
//
//  Created by ByteDance on 2023/7/7.
//

import UIKit
import SwiftUI
import Kingfisher

class ImageScrollView: UIScrollView, UIScrollViewDelegate {
     var imageView: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageView = UIImageView()
        addSubview(imageView)
        
        delegate = self
        // 设置相关的缩放属性
        minimumZoomScale = 1.0
        maximumZoomScale = 3.0
        
        // 设置 UIImageVIew 的自动布局技术
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: self.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func display(image: UIImage) {
        imageView.image = image
        imageView.sizeToFit()
        
        // 调整 UIScrollView 的缩放
        let scrollViewSize = self.bounds.size
        let imageSize = imageView.frame.size
        let widthScale = scrollViewSize.width / imageSize.width
        let heightScale = scrollViewSize.height / imageSize.height
        let minimumScale = min(widthScale, heightScale)
        self.minimumZoomScale = minimumScale

        self.zoomScale = minimumScale
        self.contentSize = imageSize
    }
    
    func display() {
        guard let image = imageView.image else {
            return
        }
        imageView.contentMode = .scaleAspectFit
        imageView.frame = CGRect(origin: .zero, size: image.size)
        
        let scrollViewSize = self.bounds.size
        let horizontalInset = max(0, (scrollViewSize.width - imageView.frame.width) / 2)
        let verticalInset = max(0, (scrollViewSize.height - imageView.frame.height) / 2)
        self.contentInset = UIEdgeInsets(top: verticalInset, left: horizontalInset, bottom: verticalInset, right: horizontalInset)
        
        self.minimumZoomScale = 1.0
        self.maximumZoomScale = 3.0
        self.zoomScale = 1.0
        
        self.contentSize = CGSize(width: imageView.frame.width + horizontalInset * 2, height: imageView.frame.height + verticalInset * 2)
    }
}
