//
//  ViewController.swift
//  SampleSwift
//
//  Created by Pallab Maiti on 19/06/23.
//

import UIKit
import MetricsReporter

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func onButtonTap(_ button: UIButton) {
//        (UIApplication.shared.delegate as? AppDelegate)?.client?.testCrash()
        for i in 1..<61 {
            if (i % 5 == 0) {
                let countMetric = Count(name: "test_count_\(i)", labels: ["key_\(i)": "value_\(i)"], value: i)
                (UIApplication.shared.delegate as? AppDelegate)?.client?.process(metric: countMetric)
            }
        }
        print("done")
    }
}

