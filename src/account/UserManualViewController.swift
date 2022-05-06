//
//  UserManualViewController.swift
//  Pirate
//
//  Created by wesley on 2020/11/20.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import UIKit

class UserManualViewController: UIViewController, UIScrollViewDelegate {

        var frame = CGRect.zero
        var imageNames = ["IOS_01","IOS_02","IOS_03","IOS_04","IOS_05","IOS_06"]
        @IBOutlet weak var pageControl: UIPageControl!
        @IBOutlet weak var scrollView: UIScrollView!
        
        
        override func viewDidLoad() {
                super.viewDidLoad()
                
                pageControl.numberOfPages = imageNames.count
                setupScreens()
                scrollView.delegate = self
        }
        
        func setupScreens() {
                
                let frameWidth = scrollView.frame.size.width
                
                for index in 0..<imageNames.count {
                        frame.origin.x = frameWidth * CGFloat(index) + 20
                        frame.size = scrollView.frame.size

                        let imgView = UIImageView(frame: frame)
                        imgView.contentMode = .scaleAspectFit
                        let image = UIImage(named: imageNames[index])
                        imgView.image = image
                        self.scrollView.addSubview(imgView)
                }
                
                scrollView.contentSize = CGSize(width: (frameWidth * CGFloat(imageNames.count)),
                                                height: scrollView.frame.size.height)
                scrollView.delegate = self
        }
        
        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
                let pageNumber = scrollView.contentOffset.x / scrollView.frame.size.width
                pageControl.currentPage = lroundf(Float(pageNumber))
        }
}
