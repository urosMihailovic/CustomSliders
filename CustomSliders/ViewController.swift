import UIKit
import ReactiveCocoa

class ViewController: UIViewController {

    @IBOutlet weak var slider: RestrictedRangeSlider!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        slider.reactive.values
            .observeValues { value in
                print(" Current value: \(value.rounded()) ")
        }
    }

}

