    //
//  ViewController.swift
//  IsolatedWordRecognitionVolleyball
//
//  Created by Ivan Trajanovski on 2020. 11. 26..
//

    import UIKit
    import AVKit
    import SoundAnalysis

    class ViewController: UIViewController {

        private let audioEngine = AVAudioEngine()
        //private var soundClassifier = Volleyball_CoreML()
        private var soundClassifier: Volleyball_CoreML = try! Volleyball_CoreML(configuration: MLModelConfiguration.init())

        var inputFormat: AVAudioFormat!
        var analyzer: SNAudioStreamAnalyzer!
        var resultsObserver = ResultsObserver()
        let analysisQueue = DispatchQueue(label: "com.custom.AnalysisQueue")
        
         let transcribedText:UILabel = {
            let view = UILabel()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.contentMode = .center
            view.textAlignment = .center
            view.numberOfLines = 0
            //view.font = UIFont(name:"Asap-Regular",size: 25)
            view.font = UIFont.boldSystemFont(ofSize: 16)
            view.textColor = UIColor(hue: 0.5361, saturation: 1, brightness: 0.82, alpha: 1.0) /* #00a4d3 */
            return view
        }()
        
        let placeholderText:UILabel = {
            let view = UILabel()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.contentMode = .center
            view.textAlignment = .center
            view.numberOfLines = 0
            view.text = "IWRV"
            //view.font = UIFont(name:"Asap-Bold",size: 25)
            UIFont.boldSystemFont(ofSize: 16)
            view.textColor = UIColor(hue: 0.5361, saturation: 1, brightness: 0.82, alpha: 1.0) /* #00a4d3 */
            return view
        }()
        
        override func viewDidLoad() {
            super.viewDidLoad()
            // Do any additional setup after loading the view.
            
            resultsObserver.delegate = self
            inputFormat = audioEngine.inputNode.inputFormat(forBus: 0)
            analyzer = SNAudioStreamAnalyzer(format: inputFormat)
            
            buildUI()
        }
        
        override func viewDidAppear(_ animated: Bool) {
            startAudioEngine()
            
        }
        
        func buildUI()
        {
            self.view.addSubview(placeholderText)
            self.view.addSubview(transcribedText)

            NSLayoutConstraint.activate(
                [transcribedText.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                 transcribedText.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
                 transcribedText.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
                 transcribedText.heightAnchor.constraint(equalToConstant: 100),
                 transcribedText.centerXAnchor.constraint(equalTo: view.centerXAnchor)
                ]
            )
            
            NSLayoutConstraint.activate(
                [placeholderText.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
                 placeholderText.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
                 placeholderText.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
                 placeholderText.centerXAnchor.constraint(equalTo: view.centerXAnchor)
                ]
            )
        }
        
        private func startAudioEngine() {
            do {
                let request = try SNClassifySoundRequest(mlModel: soundClassifier.model)
                try analyzer.add(request, withObserver: resultsObserver)
            } catch {
                print("Unable to prepare request: \(error.localizedDescription)")
                return
            }
           
            audioEngine.inputNode.installTap(onBus: 0, bufferSize: 8000, format: inputFormat) { buffer, time in
                    self.analysisQueue.async {
                        self.analyzer.analyze(buffer, atAudioFramePosition: time.sampleTime)
                    }
            }
            
            do{
            try audioEngine.start()
            }catch( _){
                print("error in starting the Audio Engine")
            }
        }
    }

    protocol VolleyballClassifierDelegate {
        func displayPredictionResult(identifier: String, confidence: Double)
    }

    extension ViewController: VolleyballClassifierDelegate {
        func displayPredictionResult(identifier: String, confidence: Double) {
            DispatchQueue.main.async {
                self.transcribedText.text = ("Recognition: \(identifier)\nConfidence: \(confidence)")
            }
        }
    }


    class ResultsObserver: NSObject, SNResultsObserving {
        var delegate: VolleyballClassifierDelegate?
        func request(_ request: SNRequest, didProduce result: SNResult) {
            guard let result = result as? SNClassificationResult,
                let classification = result.classifications.first else { return }
            
            let confidence = classification.confidence * 100.0
            
            if confidence > 60 {
                delegate?.displayPredictionResult(identifier: classification.identifier, confidence: confidence)
            }
        }
    }

