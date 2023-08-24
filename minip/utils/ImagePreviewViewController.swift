//
//  ImagePreviewViewController.swift
//  minip
//
//  Created by ByteDance on 2023/7/15.
//

import UIKit
import Kingfisher
import Photos

class ImagePreviewViewController: UIViewController {
    var imageView: ZoomImageView!
    var imageURL: URL?
    
    init(imageURL: URL? = nil) {
        self.imageURL = imageURL
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        imageView = ZoomImageView()
        self.imageView.zoomMode = .fit
        imageView.frame = view.frame
        view.addSubview(imageView)
        
        imageView.showsVerticalScrollIndicator = true
        imageView.showsHorizontalScrollIndicator = true
        
        imageView.maximumZoomScale = 5
        if let url = imageURL {
            if url.scheme == "file" {
                imageView.image = UIImage(contentsOfFile: url.path)
            } else {
                imageView.setWebImage(url: url)
            }
        }
        view.backgroundColor = .black
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        self.view.addGestureRecognizer(tapGestureRecognizer)
            
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressed))
        self.view.addGestureRecognizer(longPressRecognizer)
    }
    
    @objc func tapped(sender: UITapGestureRecognizer){
        dismiss(animated: true)
    }

    @objc func longPressed(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            ShortShake()
            
            let alertController = UIAlertController(title: "Action", message: "Select one action", preferredStyle: .actionSheet)
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: "Save to album", style: .default, handler: { [weak self] action in
                guard let img = self?.imageView.image  else  {
                    ShowSimpleError(err: ErrorMsg(errorDescription: "Error image"))
                    return
                }
                PHPhotoLibrary.requestAuthorization { (status) in
                    if status == .authorized {
                        UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
                        DispatchQueue.main.async {
                            ShowSimpleSuccess()
                        }
                    } else {
                        DispatchQueue.main.async {
                            ShowSimpleError(err: ErrorMsg(errorDescription: "Cannot save to album, no permission or limitted"))
                        }
                    }
                }
            }))
            present(alertController, animated: true)
        }
    }
}

open class ZoomImageView : UIScrollView, UIScrollViewDelegate {
    
    public enum ZoomMode {
        case fit
        case fill
    }
    
    // MARK: - Properties
    
    public let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.allowsEdgeAntialiasing = true
        return imageView
    }()
    
    public func setWebImage(url: URL?) {
        imageView.kf.setImage(with: url, completionHandler: { [weak self] _ in
            self?.updateImageView()
            self?.scrollToCenter()
        })
    }
    
    public var zoomMode: ZoomMode = .fit {
        didSet {
            updateImageView()
            scrollToCenter()
        }
    }
    
    open var image: UIImage? {
        get {
            return imageView.image
        }
        set {
            let oldImage = imageView.image
            imageView.image = newValue
            
            if oldImage?.size != newValue?.size {
                oldSize = nil
                updateImageView()
            }
            scrollToCenter()
        }
    }
    
    open override var intrinsicContentSize: CGSize {
        return imageView.intrinsicContentSize
    }
    
    private var oldSize: CGSize?
    
    // MARK: - Initializers
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public init(image: UIImage) {
        super.init(frame: CGRect.zero)
        self.image = image
        setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    // MARK: - Functions
    
    open func scrollToCenter() {
        
        let centerOffset = CGPoint(
            x: contentSize.width > bounds.width ? (contentSize.width / 2) - (bounds.width / 2) : 0,
            y: contentSize.height > bounds.height ? (contentSize.height / 2) - (bounds.height / 2) : 0
        )
        
        contentOffset = centerOffset
    }
    
    open func setup() {
        
#if swift(>=3.2)
        if #available(iOS 11, *) {
            contentInsetAdjustmentBehavior = .never
        }
#endif
        
        backgroundColor = UIColor.clear
        delegate = self
        imageView.contentMode = .scaleAspectFill
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        addSubview(imageView)
        
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTapGesture)
    }
    
    open override func didMoveToSuperview() {
        super.didMoveToSuperview()
    }
    
    open override func layoutSubviews() {
        
        super.layoutSubviews()
        
        if imageView.image != nil && oldSize != bounds.size {
            
            updateImageView()
            oldSize = bounds.size
        }
        
        if imageView.frame.width <= bounds.width {
            imageView.center.x = bounds.width * 0.5
        }
        
        if imageView.frame.height <= bounds.height {
            imageView.center.y = bounds.height * 0.5
        }
    }
    
    open override func updateConstraints() {
        super.updateConstraints()
        updateImageView()
    }
    
    private func updateImageView() {
        
        func fitSize(aspectRatio: CGSize, boundingSize: CGSize) -> CGSize {
            
            let widthRatio = (boundingSize.width / aspectRatio.width)
            let heightRatio = (boundingSize.height / aspectRatio.height)
            
            var boundingSize = boundingSize
            
            if widthRatio < heightRatio {
                boundingSize.height = boundingSize.width / aspectRatio.width * aspectRatio.height
            }
            else if (heightRatio < widthRatio) {
                boundingSize.width = boundingSize.height / aspectRatio.height * aspectRatio.width
            }
            return CGSize(width: ceil(boundingSize.width), height: ceil(boundingSize.height))
        }
        
        func fillSize(aspectRatio: CGSize, minimumSize: CGSize) -> CGSize {
            let widthRatio = (minimumSize.width / aspectRatio.width)
            let heightRatio = (minimumSize.height / aspectRatio.height)
            
            var minimumSize = minimumSize
            
            if widthRatio > heightRatio {
                minimumSize.height = minimumSize.width / aspectRatio.width * aspectRatio.height
            }
            else if (heightRatio > widthRatio) {
                minimumSize.width = minimumSize.height / aspectRatio.height * aspectRatio.width
            }
            return CGSize(width: ceil(minimumSize.width), height: ceil(minimumSize.height))
        }
        
        guard let image = imageView.image else { return }
        
        var size: CGSize
        
        switch zoomMode {
        case .fit:
            size = fitSize(aspectRatio: image.size, boundingSize: bounds.size)
        case .fill:
            size = fillSize(aspectRatio: image.size, minimumSize: bounds.size)
        }
        
        size.height = round(size.height)
        size.width = round(size.width)
        
        zoomScale = 1
        //    maximumZoomScale = image.size.width / size.width
        imageView.bounds.size = size
        contentSize = size
        imageView.center = ZoomImageView.contentCenter(forBoundingSize: bounds.size, contentSize: contentSize)
    }
    
    @objc private func handleDoubleTap(_ gestureRecognizer: UITapGestureRecognizer) {
        if self.zoomScale == 1 {
            zoom(
                to: zoomRectFor(
                    scale: max(1, maximumZoomScale / 3),
                    with: gestureRecognizer.location(in: gestureRecognizer.view)),
                animated: true
            )
        } else {
            setZoomScale(1, animated: true)
        }
    }
    
    // This function is borrowed from: https://stackoverflow.com/questions/3967971/how-to-zoom-in-out-photo-on-double-tap-in-the-iphone-wwdc-2010-104-photoscroll
    private func zoomRectFor(scale: CGFloat, with center: CGPoint) -> CGRect {
        let center = imageView.convert(center, from: self)
        
        var zoomRect = CGRect()
        zoomRect.size.height = bounds.height / scale
        zoomRect.size.width = bounds.width / scale
        zoomRect.origin.x = center.x - zoomRect.width / 2.0
        zoomRect.origin.y = center.y - zoomRect.height / 2.0
        
        return zoomRect
    }
    
    // MARK: - UIScrollViewDelegate
    @objc dynamic public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        imageView.center = ZoomImageView.contentCenter(forBoundingSize: bounds.size, contentSize: contentSize)
    }
    
    @objc dynamic public func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        
    }
    
    @objc dynamic public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        
    }
    
    @objc dynamic public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    @inline(__always)
    private static func contentCenter(forBoundingSize boundingSize: CGSize, contentSize: CGSize) -> CGPoint {
        
        /// When the zoom scale changes i.e. the image is zoomed in or out, the hypothetical center
        /// of content view changes too. But the default Apple implementation is keeping the last center
        /// value which doesn't make much sense. If the image ratio is not matching the screen
        /// ratio, there will be some empty space horizontaly or verticaly. This needs to be calculated
        /// so that we can get the correct new center value. When these are added, edges of contentView
        /// are aligned in realtime and always aligned with corners of scrollview.
        let horizontalOffest = (boundingSize.width > contentSize.width) ? ((boundingSize.width - contentSize.width) * 0.5): 0.0
        let verticalOffset = (boundingSize.height > contentSize.height) ? ((boundingSize.height - contentSize.height) * 0.5): 0.0
        
        return CGPoint(x: contentSize.width * 0.5 + horizontalOffest,  y: contentSize.height * 0.5 + verticalOffset)
    }
}
