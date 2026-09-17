import SwiftUI
import UserNotifications
import AVFoundation
import Combine
import MediaPlayer


class AlarmManager {
    static let shared = AlarmManager()
    private var audioPlayer: AVAudioPlayer?
    private var volumeTimer: AnyCancellable?
    
    func startAlarm() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
        try? AVAudioSession.sharedInstance().setActive(true)
        
        guard let url = URL(string: "/System/Library/Audio/UISounds/alarm.caf") else { return }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.volume = 1.0
            audioPlayer?.play()
            
            forceMaxVolume()
            volumeTimer = Timer.publish(every: 1.0, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in self?.forceMaxVolume() }
        } catch {
            print("音の再生に失敗しました")
        }
    }
    
    func stopAlarm() {
        audioPlayer?.stop()
        volumeTimer?.cancel()
        volumeTimer = nil
    }
    
    private func forceMaxVolume() {
        audioPlayer?.volume = 1.0
        let volumeView = MPVolumeView()
        if let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider {
            DispatchQueue.main.async { slider.value = 1.0 }
        }
    }
}

extension Foundation.NSNotification.Name {
    static let deviceDidShake = NSNotification.Name("deviceDidShake")
}

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: .deviceDidShake, object: nil)
        }
    }
}



extension View {
    func onShake(perform action: @escaping () -> Void) -> some View {
        self.modifier(ShakeDetector(action: action))
    }
}


