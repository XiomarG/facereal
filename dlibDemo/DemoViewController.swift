//
//  DemoViewController.swift
//  dlibDemo
//
//  Created by Xun Gong on 2017-11-04.
//  Copyright © 2017 clarke. All rights reserved.
//

import UIKit
import AVFoundation

class DemoViewController: UIViewController {
    @IBOutlet weak var preview: UIView!
    let sessionHandler = SessionHandler()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        sessionHandler.openSession()
        
        
        let layer = sessionHandler.layer
        layer.frame = preview.bounds
        
        preview.layer.addSublayer(layer)
        
        view.layoutIfNeeded()

    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
