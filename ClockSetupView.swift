import SwiftUI
import Combine
struct ClockSetupView: View {
    @Binding var currentTime: Date
    @Binding var alarmTime: Date
    @Binding var isWaiting: Bool
    @Binding var comboRequired: Int
    var isRinging: Bool
    let timerTickAction: (Date) -> Void
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 10) {
            Text(currentTime, style: .time)
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .onReceive(timer) { input in timerTickAction(input) }
            
            if !isRinging {
                HStack {
                    Text("⛓️ 連続クリア試練:").font(.subheadline).bold()
                    Spacer()
                    Picker("", selection: $comboRequired) {
                        Text("1回").tag(1)
                        Text("3連撃").tag(3)
                        Text("5連撃").tag(5)
                    }
                    .pickerStyle(.segmented).frame(width: 180)
                }.padding(.horizontal)
                
                HStack {
                    Image(systemName: "bell.fill").foregroundColor(isWaiting ? .orange : .gray)
                    DatePicker("", selection: $alarmTime, displayedComponents: .hourAndMinute)
                        .labelsHidden().datePickerStyle(.wheel).frame(height: 100).disabled(isWaiting)
                }.padding(.horizontal).background(Color(.systemGray6)).cornerRadius(12)
                
                Button(action: { isWaiting.toggle() }) {
                    Text(isWaiting ? "目覚ましを解除する" : "この時間でお題をセット！")
                        .font(.headline).foregroundColor(.white).frame(maxWidth: .infinity, minHeight: 44)
                        .background(isWaiting ? Color.red : Color.blue).cornerRadius(10)
                }.padding(.horizontal)
            }
        }.padding(.top)
    }
}


struct DefaultIdleView: View {
    let clearRecord: String
    
    var loginStreak: Int { UserDefaults.standard.integer(forKey: "LoginStreak") }
    var historyRecords: [String] { UserDefaults.standard.stringArray(forKey: "ClearTimeHistory") ?? [] }
    
    var awakeningRank: (title: String, color: Color, emoji: String) {
        if clearRecord == "記録なし" { return ("未測定", .gray, "💤") }
        let secondsString = clearRecord.components(separatedBy: " 秒").first ?? ""
        let components = secondsString.components(separatedBy: ":")
        var totalSeconds: Int = 60
        if (components.count == 2){
            totalSeconds = 3
        }
        //        let totalSeconds = components.count == 2 ? (Double(components[0]) * 60) + Double(components[1])! : Double(secondsString) ?? 999
        
        switch totalSeconds {
        case ..<15:   return ("超・神速覚醒", .purple, "⚡️")
        case 15..<30:  return ("天才スイーパー", .blue, "🎯")
        case 30..<60:  return ("標準お目覚め", .green, "🏃‍♂️")
        default:       return ("二度寝の住人", .orange, "🐢")
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            VStack(spacing: 6) {
                Text("⏰ 待機中...").font(.title2).bold().foregroundColor(.gray)
                Text("時間になると、ランダムでお題が始まります。").font(.caption).foregroundColor(.gray).multilineTextAlignment(.center)
            }
            if loginStreak > 0 {
                HStack(spacing: 8) {
                    Text("🔥")
                    Text("\(loginStreak) 日連続お目覚め中！").font(.subheadline).bold().foregroundColor(.orange)
                }.padding(.horizontal, 16).padding(.vertical, 8).background(Color.orange.opacity(0.12)).cornerRadius(12)
            }
            StatusCardView(awakeningRank: awakeningRank, clearRecord: clearRecord)
            HistoryListView(historyRecords: historyRecords)
            Spacer()
        }.padding(.horizontal)
    }
}


struct StatusCardView: View {
    let awakeningRank: (title: String, color: Color, emoji: String)
    let clearRecord: String
    
    var body: some View {
        VStack(spacing: 12) {
            Text("📊 現在のステータス").font(.caption).bold().foregroundColor(.secondary)
            HStack(spacing: 15) {
                HStack {
                    Text(awakeningRank.emoji)
                    Text(awakeningRank.title).font(.subheadline).bold()
                }
                .padding(.horizontal, 12).padding(.vertical, 6).background(awakeningRank.color.opacity(0.15)).foregroundColor(awakeningRank.color).cornerRadius(20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("前回の脱出タイム").font(.caption2).foregroundColor(.gray)
                    Text(clearRecord).font(.body).bold().foregroundColor(.primary)
                }
            }
        }.padding().frame(maxWidth: .infinity).background(Color(.systemGray6)).cornerRadius(12)
    }
}


struct HistoryListView: View {
    let historyRecords: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("📈 直近のお目覚めログ").font(.caption).bold().foregroundColor(.secondary)
            if historyRecords.isEmpty {
                Text("ログがありません。明日から頑張りましょう！").font(.caption2).foregroundColor(.gray).padding().frame(maxWidth: .infinity).background(Color(.systemGray6).opacity(0.5)).cornerRadius(10)
            } else {
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(Array(historyRecords.enumerated()), id: \.offset) { index, record in
                            HStack {
                                Text("\(index + 1)回前").font(.caption2).foregroundColor(.gray)
                                Circle().fill(record.contains("秒") && (Double(record.components(separatedBy: " 秒").first ?? "99") ?? 99) < 20 ? Color.green : Color.orange).frame(width: 8, height: 8)
                                Spacer()
                                Text(record).font(.caption).monospaced().bold()
                            }.padding(.horizontal, 12).padding(.vertical, 8).background(Color(.systemGray6)).cornerRadius(8)
                        }
                    }
                }.frame(height: 110)
            }
        }
    }
}


struct Hold15sMissionView: View {
    @State private var holdSeconds: Double = 15.0
    @State private var isPressing = false
    let holdTimer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    let triggerClear: () -> Void
    
    var body: some View {
        VStack(spacing: 25) {
            Text(String(format: "残り %.1f 秒", holdSeconds)).font(.system(size: 40, weight: .bold, design: .monospaced)).foregroundColor(isPressing ? .green : .red)
            ZStack(alignment: .leading) {
                Capsule().fill(Color(.systemGray5)).frame(width: 260, height: 12)
                Capsule().fill(Color.purple).frame(width: 260 * (1.0 - (holdSeconds / 15.0)), height: 12)
            }.animation(.linear(duration: 0.1), value: holdSeconds)
            
            Button(action: {}) {
                Text(isPressing ? "そのままキープ！" : "ここを15秒間 長押し").font(.headline).foregroundColor(.white).frame(width: 260, height: 80).background(isPressing ? Color.green : Color.purple).cornerRadius(15)
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        isPressing = true
                    }
                    .onEnded { _ in
                        isPressing = false
                        holdSeconds = 15.0
                    }
            )
            .onReceive(holdTimer) { _ in
                guard isPressing else { return }

                holdSeconds -= 0.1

                if holdSeconds <= 0 {
                    holdSeconds = 0
                    isPressing = false
                    triggerClear()
                }
            }

            
            Text("途中で指を離すと最初からやり直し").font(.caption).foregroundColor(.gray)
        }.onAppear { holdSeconds = 15.0; isPressing = false }
    }
}


struct Toggles24MissionView: View {
    @Binding var toggleStates: [Bool]
    let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)
    let triggerClear: () -> Void
    
    var body: some View {
        VStack(spacing: 15) {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(0..<24, id: \.self) { i in
                    VStack(spacing: 4) {
                        Text("\(i + 1)").font(.caption2).foregroundColor(.gray)
                        Toggle("", isOn: $toggleStates[i]).labelsHidden()
                            .onChange(of: toggleStates[i]) { _, _ in
                                if toggleStates.allSatisfy({ $0 == true }) { triggerClear() }
                            }
                    }.padding(4).background(Color(.systemGray6)).cornerRadius(8)
                }
            }.padding(.horizontal)
            Text("すべてのスイッチを緑色にしてください").font(.caption).foregroundColor(.gray)
        }
    }
}


struct ActiveMissionView: View {
    let currentMission: MissionType
    @Binding var shakeCount: Int
    @Binding var tap100Count: Int
    @Binding var textInput: String
    @Binding var quizInput: String
    @Binding var sliderValue: Double
    @Binding var isSliderAtMax: Bool
    @Binding var sliderSuccessCount: Int
    @Binding var timeRemaining: Int
    @Binding var toggleStates: [Bool]
    
    let triggerClear: () -> Void
    let triggerLuckFail: () -> Void
    
    var body: some View {
        switch currentMission {
        case .shake:
            VStack { Text("\(shakeCount) / 100").font(.system(size: 64, weight: .black, design: .monospaced)); Text("振ってください！") }
                .onShake { if shakeCount < 100 { shakeCount += 1; if shakeCount >= 100 { triggerClear() } } }
        case .tap100:
            Button(action: { tap100Count += 1; if tap100Count >= 100 { triggerClear() } }) { Text("\(tap100Count) / 100").font(.system(size: 70, weight: .bold)).frame(width: 300, height: 300).background(Color.orange).foregroundColor(.white).clipShape(Circle()) }
        case .hold15s:
            Hold15sMissionView(triggerClear: triggerClear)
        case .waitOneMinute:
            VStack(spacing: 20) { Text("\(timeRemaining)").font(.system(size: 80, weight: .black, design: .monospaced)).foregroundColor(.red); Text("秒間、画面を見つめるとアラームが止まります").font(.subheadline).foregroundColor(.gray) }
        case .typeLongText:
            VStack(spacing: 15) { Text("以下の文字を正確に写せ:").font(.subheadline); Text("マイルームノソウジヲシマス").font(.title3).bold().foregroundColor(.blue); TextField("全角カタカナで入力", text: $textInput).textFieldStyle(.roundedBorder).frame(width: 250).multilineTextAlignment(.center)
                Button("送信する") { if textInput == "マイルームノソウジヲシマス" { triggerClear() } }.buttonStyle(.borderedProminent) }
        case .findLuck9:
            VStack(spacing: 15) { Text("アタリは1つだけ（間違えると全リセット）").font(.caption).foregroundColor(.gray)
                Grid(horizontalSpacing: 15, verticalSpacing: 15) { GridRow { Button("ハズレ") { triggerLuckFail() }; Button("ハズレ") { triggerLuckFail() }; Button("ハズレ") { triggerLuckFail() } }; GridRow { Button("ハズレ") { triggerLuckFail() }; Button("ハズル") { triggerClear() }.tint(.blue); Button("ハズレ") { triggerLuckFail() } }; GridRow { Button("ハズレ") { triggerLuckFail() }; Button("ハズレ") { triggerLuckFail() }; Button("ハズレ") { triggerLuckFail() } } }.buttonStyle(.borderedProminent) }
        case .dinnerQuiz:
            VStack(spacing: 15) {
                Text("「昨日、一昨日の晩ご飯」を\n文字数10文字以上で入力せよ！").font(.headline).multilineTextAlignment(.center); TextField("メニューを入力してください", text: $quizInput).textFieldStyle(.roundedBorder).frame(width: 280)
                Button("思い出しました") { if quizInput.count >= 10 { triggerClear() } }.buttonStyle(.borderedProminent) }
        case .toggles24:
            Toggles24MissionView(toggleStates: $toggleStates, triggerClear: triggerClear)
        case .slider5Times:
            VStack(spacing: 20) { Text("往復成功: \(sliderSuccessCount) / 5 回").font(.title2).bold(); Slider(value: $sliderValue, in: 0...100).padding(.horizontal, 40).onChange(of: sliderValue) { _, nv in if nv >= 98 && !isSliderAtMax { isSliderAtMax = true; sliderSuccessCount += 1; if sliderSuccessCount >= 5 { triggerClear() } } else if nv <= 5 { isSliderAtMax = false } }
                Text("右端まで持って行ったら左端に戻す！").font(.caption).foregroundColor(.gray) }
        }
    }
}




