import SwiftUI
import Combine

struct ContentView: View {
    @State private var currentMission: MissionType = .shake
    @State private var isRinging = false
    @State private var isWaiting = false
    @State private var currentTime = Date()
    @State private var alarmTime = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    @State private var shakeCount = 0
    @State private var tap100Count = 0
    @State private var textInput = ""
    @State private var quizInput = ""
    @State private var sliderValue: Double = 0.0
    @State private var sliderSuccessCount = 0
    @State private var isSliderAtMax = false
    @State private var toggleStates = Array(repeating: false, count: 24)
    @State private var timeRemaining = 60
    
    @State private var comboRequired = 3
    @State private var currentComboCount = 0
    @State private var alarmStartTime: Date?
    @State private var lastClearTime: String = UserDefaults.standard.string(forKey: "LastClearTime") ?? "記録なし"
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        VStack(spacing: 20) {
            ClockSetupView(currentTime: $currentTime, alarmTime: $alarmTime, isWaiting: $isWaiting, comboRequired: $comboRequired, isRinging: isRinging, timerTickAction: handleClockUpdate)
            Divider()
            if isRinging {
                Text("試練突破: \(currentComboCount) / \(comboRequired)").font(.headline).foregroundColor(.red).padding(.horizontal).padding(.vertical, 4).background(Color.red.opacity(0.1)).cornerRadius(8)
                Text(currentMission.title).font(.title2).bold().multilineTextAlignment(.center).padding(.horizontal)
                Spacer()
                ActiveMissionView(currentMission: currentMission, shakeCount: $shakeCount, tap100Count: $tap100Count, textInput: $textInput, quizInput: $quizInput, sliderValue: $sliderValue, isSliderAtMax: $isSliderAtMax, sliderSuccessCount: $sliderSuccessCount, timeRemaining: $timeRemaining, toggleStates: $toggleStates, triggerClear: handleMissionClear, triggerLuckFail: resetLuck)
                Spacer()
            } else { DefaultIdleView(clearRecord: lastClearTime) }
        }
        .padding().onAppear { UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in } }
        .onChange(of: scenePhase) { _, p in if isRinging && (p == .background || p == .inactive) { sendNotification() } }
    }
    
    private func handleClockUpdate(_ input: Date) {
        self.currentTime = input
        if isWaiting {
            let curr = Calendar.current.dateComponents([.hour, .minute], from: input)
            let alrm = Calendar.current.dateComponents([.hour, .minute], from: alarmTime)
            if curr.hour == alrm.hour && curr.minute == alrm.minute { startAlarmSequence() }
        }
        if isRinging && currentMission == .waitOneMinute && timeRemaining > 0 {
            timeRemaining -= 1; if timeRemaining <= 0 { handleMissionClear() }
        }
    }
    
    private func resetLuck() { currentComboCount = 0; nextMission() }
    
    private func handleMissionClear() {
        currentComboCount += 1
        if currentComboCount >= comboRequired {
            isRinging = false; AlarmManager.shared.stopAlarm(); saveStats()
        } else { nextMission() }
    }
    
    private func nextMission() {
        shakeCount = 0; tap100Count = 0; textInput = ""; quizInput = ""; sliderValue = 0.0; sliderSuccessCount = 0; isSliderAtMax = false; toggleStates = Array(repeating: false, count: 24); timeRemaining = 60
        var n = MissionType.allCases.randomElement() ?? .shake
        while n == currentMission { n = MissionType.allCases.randomElement() ?? .shake }; currentMission = n
    }
    
    private func startAlarmSequence() { isWaiting = false; isRinging = true; currentComboCount = 0; alarmStartTime = Date(); nextMission(); AlarmManager.shared.startAlarm() }
    
    private func saveStats() {
        guard let st = alarmStartTime else { return }
        let el = Date().timeIntervalSince(st)
        let f = DateComponentsFormatter(); f.allowedUnits = [.minute, .second]; f.unitsStyle = .positional
        if let ts = f.string(from: el) {
            let res = "\(ts) 秒 (\(comboRequired)連撃)"; lastClearTime = res; UserDefaults.standard.set(res, forKey: "LastClearTime")
            var h = UserDefaults.standard.stringArray(forKey: "ClearTimeHistory") ?? []; h.insert(res, at: 0)
            if h.count > 5 { h = Array(h.prefix(5)) }; UserDefaults.standard.set(h, forKey: "ClearTimeHistory")
            updateStreak()
        }
    }
    
    private func updateStreak() {
        let today = Calendar.current.startOfDay(for: Date())
        let lastD = UserDefaults.standard.object(forKey: "LastClearDate") as? Date
        var strk = UserDefaults.standard.integer(forKey: "LoginStreak")
        if let ld = lastD {
            let cmp = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: ld), to: today)
            if cmp.day == 1 { strk += 1 } else if cmp.day! > 1 { strk = 1 }
        } else { strk = 1 }
        UserDefaults.standard.set(strk, forKey: "LoginStreak"); UserDefaults.standard.set(Date(), forKey: "LastClearDate")
    }
    
    private func sendNotification() {
        let content = UNMutableNotificationContent(); content.title = "🚨 逃げるな！！！"; content.body = "クリアするまで試練は終わりません！今すぐ戻れ！"; content.sound = .defaultCritical
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "Es", content: content, trigger: UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)), withCompletionHandler: nil)
    }
}
