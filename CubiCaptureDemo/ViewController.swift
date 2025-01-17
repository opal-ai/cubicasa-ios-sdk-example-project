//
//  ViewController.swift
//  CubiCaptureDemo
//
//  Created by Rauli Puuperä on 8.12.2020.
//

import UIKit

// Import the SDK
import CubiCapture

class ViewController: UIViewController {

    private var projectLocation: URL?

    @IBOutlet weak var playbackButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        playbackButton.isEnabled = false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    @IBAction func startPressed(_ sender: UIButton) {
        // Initiate CCCapture
        let ccCapture = CCCapture()
        ccCapture.delegateCapture = self
        ccCapture.options = [.speechRecognition, .meshVisualisation, .backgroundResume,
                             .azimuth, .storageWarnings]
        if #available(iOS 16, *) {
            let scanHost = ScanHostViewController()
            present(scanHost, animated: false) {
                scanHost.presentScanner(ccCapture)
            }
        } else {
            present(ccCapture, animated: true)
        }
    }

    @IBAction func playbackPressed(_ sender: Any) {
        guard let projectLocation = projectLocation else {
            return
        }
        do {
            let playbackVC = try CCScanPlaybackViewController(projectLocation: projectLocation)
            let navController = UINavigationController(rootViewController: playbackVC)
            playbackVC.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close,
                                                                          target: self,
                                                                          action: #selector(dismissPlayback))
            navController.modalPresentationStyle = .overFullScreen
            self.present(navController, animated: true, completion: nil)
        } catch {
            print("Error instantiating playback controller: \(error.localizedDescription)")
        }
    }

    @objc func dismissPlayback() {
        dismiss(animated: true, completion: nil)
    }

    private func endScan(_ controller: CCCapture) {
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }
    }
}

extension ViewController: CCCaptureDelegate {
    func dataZippedDelegationFunc(_ controller: CCCapture) {
        // The capture was completed succesfully
        print("Data zipped message received")
    }
    
    func zippedDataLocation(_ controller: CCCapture, location: URL) {
        // You can now upload the file in location to your server and use our server-to-server API to process the capture
        print("Location received \(location)")
        projectLocation = location
        playbackButton.isEnabled = true
    }
    
    func messenger(_ controller: CCCapture, errorCode: Int, message: String) {
        // This method is called whenever there is a change in the capture process
        print("Error code and message received \(errorCode) and \(message)")
        switch errorCode {
        case 0, 1, 2, 5, 7, 23, 24, 26, 27, 28, 32:
            // Positive
            break
        case 8, 9, 17, 21, 22, 29, 30, 31, 53, 72, 73, 74, 77, 78, 85, 86:
            // Worrysome
            break
        case 3, 13, 51, 54, 56, 57, 58, 59, 82, 83, 90:
            // Terminal, the SDK kill the scan with scanTrackingFailed
            break
        case 15, 18, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 70, 71, 75, 76, 80, 81:
            // Information
            break
        default:
            break
        }
    }
    
    func processReadyDelegationFunc(_ controller: CCCapture) {
        print("processReady")
        endScan(controller)
    }

    func scanTrackingFailed(_ controller: CCCapture) {
        print("tracking failed")
        endScan(controller)
    }
}

