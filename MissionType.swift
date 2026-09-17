enum MissionType: CaseIterable {
    case shake, tap100, waitOneMinute, typeLongText, findLuck9, dinnerQuiz, hold15s, toggles24, slider5Times
    
    var title: String {
        switch self {
        case .shake:             return "🔥 スマホを100回振れ！"
        case .tap100:            return "⚡️ 100回連打せよ！"
        case .waitOneMinute:     return "⏳ 1分間画面を見つめ続けよ！"
        case .typeLongText:      return "⌨️ 【精密】指定文字列を正確に入力せよ！"
        case .findLuck9:         return "🎯 【強運】9個から1つのアタリを探せ！"
        case .dinnerQuiz:        return "🧠 【記憶】脳を覚醒させて答えよ！"
        case .hold15s:           return "⏳ 【忍耐】15秒間指を離さず長押しせよ！"
        case .toggles24:         return "🎛️ 【絶望】24個のスイッチをすべてONにせよ！"
        case .slider5Times:      return "🚟 【反復】右端スライドを5回繰り返せ！"
        }
    }
}
