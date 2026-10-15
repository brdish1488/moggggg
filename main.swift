import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = GameController()
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
}

final class GameController: UIViewController {
    private let titleLabel = UILabel()
    private let statsLabel = UILabel()
    private let hintLabel = UILabel()
    private let startButton = UIButton(type: .system)
    private let target = UIButton(type: .custom)
    private let arena = UIView()
    private var timer: Timer?
    private var deadline: TimeInterval = 0
    private var score = 0
    private var playing = false
    private var best: Int { get { UserDefaults.standard.integer(forKey: "bestScore") } set { UserDefaults.standard.set(newValue, forKey: "bestScore") } }
    private let ink = UIColor(red: 0.92, green: 0.96, blue: 1, alpha: 1)
    private let accent = UIColor(red: 0.43, green: 0.94, blue: 0.71, alpha: 1)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.04, green: 0.07, blue: 0.13, alpha: 1)
        titleLabel.text = "ЛОВИ КРУГ"
        titleLabel.font = .systemFont(ofSize: 30, weight: .black)
        titleLabel.textColor = ink
        statsLabel.textColor = accent
        statsLabel.font = .monospacedDigitSystemFont(ofSize: 17, weight: .bold)
        statsLabel.numberOfLines = 2
        hintLabel.textColor = UIColor(white: 0.7, alpha: 1)
        hintLabel.font = .systemFont(ofSize: 15)
        hintLabel.textAlignment = .center
        hintLabel.numberOfLines = 3
        hintLabel.text = "Нажимай на круги. У тебя 30 секунд.\nКаждое попадание — одно очко."
        arena.backgroundColor = UIColor(white: 1, alpha: 0.04)
        arena.layer.cornerRadius = 24
        arena.clipsToBounds = true
        startButton.backgroundColor = accent
        startButton.setTitleColor(view.backgroundColor, for: .normal)
        startButton.titleLabel?.font = .systemFont(ofSize: 19, weight: .bold)
        startButton.layer.cornerRadius = 18
        startButton.setTitle("Начать игру", for: .normal)
        startButton.addTarget(self, action: #selector(startGame), for: .touchUpInside)
        target.backgroundColor = accent
        target.setTitle("+1", for: .normal)
        target.setTitleColor(view.backgroundColor, for: .normal)
        target.titleLabel?.font = .systemFont(ofSize: 22, weight: .heavy)
        target.accessibilityLabel = "Поймать круг"
        target.addTarget(self, action: #selector(hit), for: .touchDown)
        target.isHidden = true
        [titleLabel, statsLabel, arena, hintLabel, startButton].forEach { view.addSubview($0) }
        arena.addSubview(target)
        NotificationCenter.default.addObserver(self, selector: #selector(interrupted), name: UIApplication.willResignActiveNotification, object: nil)
        updateStats(seconds: 30)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let safe = view.safeAreaInsets
        let width = view.bounds.width - 40
        titleLabel.frame = CGRect(x: 20, y: safe.top + 18, width: width, height: 40)
        statsLabel.frame = CGRect(x: 20, y: titleLabel.frame.maxY + 10, width: width, height: 52)
        let buttonY = view.bounds.height - safe.bottom - 76
        startButton.frame = CGRect(x: 20, y: buttonY, width: width, height: 56)
        hintLabel.frame = CGRect(x: 20, y: buttonY - 72, width: width, height: 60)
        let arenaY = statsLabel.frame.maxY + 16
        arena.frame = CGRect(x: 20, y: arenaY, width: width, height: max(80, hintLabel.frame.minY - arenaY - 16))
        if playing && !arena.bounds.contains(target.frame) { moveTarget() }
    }

    private func updateStats(seconds: Int) {
        statsLabel.text = "ОЧКИ: \(score)     ВРЕМЯ: \(seconds)\nРЕКОРД: \(best)"
    }
    @objc private func startGame() {
        timer?.invalidate()
        score = 0
        playing = true
        deadline = ProcessInfo.processInfo.systemUptime + 30
        startButton.setTitle("Начать заново", for: .normal)
        hintLabel.text = "Лови зелёный круг!"
        target.isHidden = false
        updateStats(seconds: 30)
        view.layoutIfNeeded()
        moveTarget()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in self?.tick() }
    }
    private func tick() {
        let remaining = max(0, Int(ceil(deadline - ProcessInfo.processInfo.systemUptime)))
        updateStats(seconds: remaining)
        if remaining == 0 { finish() }
    }
    @objc private func hit() {
        guard playing else { return }
        guard ProcessInfo.processInfo.systemUptime < deadline else { finish(); return }
        score += 1
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        updateStats(seconds: max(0, Int(ceil(deadline - ProcessInfo.processInfo.systemUptime))))
        moveTarget()
    }
    private func moveTarget() {
        let diameter = min(max(54, 88 - CGFloat(score)), min(arena.bounds.width, arena.bounds.height) - 16)
        guard diameter > 0 else { return }
        let maxX = max(8, arena.bounds.width - diameter - 8)
        let maxY = max(8, arena.bounds.height - diameter - 8)
        target.frame = CGRect(x: CGFloat.random(in: 8...maxX), y: CGFloat.random(in: 8...maxY), width: diameter, height: diameter)
        target.layer.cornerRadius = diameter / 2
    }
    private func finish() {
        guard playing else { return }
        playing = false
        timer?.invalidate()
        timer = nil
        target.isHidden = true
        let record = score > best
        best = max(best, score)
        updateStats(seconds: 0)
        hintLabel.text = record ? "Новый рекорд: \(score)! 🎉" : "Твой результат: \(score). Попробуешь ещё?"
        startButton.setTitle("Играть ещё", for: .normal)
    }
    @objc private func interrupted() { if playing { finish() } }
    deinit { timer?.invalidate(); NotificationCenter.default.removeObserver(self) }
}
