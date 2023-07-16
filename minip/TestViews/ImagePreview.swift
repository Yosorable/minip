//
//  ImagePreview.swift
//  minip
//
//  Created by ByteDance on 2023/7/7.
//

import UIKit
import HXPhotoPicker
import SwiftUI
import Kingfisher


class ImagePreviewController: UIViewController {
    private var imageScrollView: ImageScrollView!
    
    override func viewDidLoad() {
        let button = UIButton(type: .system)
        button.frame = CGRect(x: 100, y: 200, width: 200, height: 50)
        button.setTitle("点击我", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .blue
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        
        view.addSubview(button)
        
                
//        imageScrollView = ImageScrollView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
//        view.addSubview(imageScrollView)
//        
//        imageScrollView.imageView.kf.setImage(with: URL(string: "https://t7.baidu.com/it/u=1054961783,3270956628&fm=193&f=GIF")) {[weak self] _ in
//            self?.imageScrollView.display()
//        }
        
    }
    
    @objc func buttonTapped() {
        print("按钮被点击了！")
        presentPickerController()
    }
    
    func presentPickerController() {
        // 设置与微信主题一致的配置
        var config = PickerConfiguration.default
        config.modalPresentationStyle = .fullScreen
        
        do {
            Photo.picker(
                config
            ) { result, pickerController in
                // 选择完成的回调
                // result 选择结果
                //  .photoAssets 当前选择的数据
                //  .isOriginal 是否选中了原图
                // photoPickerController 对应的照片选择控制器
            } cancel: { pickerController in
                // 取消的回调
                // photoPickerController 对应的照片选择控制器
            }
        } catch let error {
            print("\(error)")
        }
        
    }
}



struct ImagePreviewView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ImagePreviewController {
        return ImagePreviewController()
    }
    
    func updateUIViewController(_ uiViewController: ImagePreviewController, context: Context) {
    }
}


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
