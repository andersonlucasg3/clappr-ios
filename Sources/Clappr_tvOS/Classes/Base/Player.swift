import AVKit

@objcMembers
open class Player: AVPlayerViewController {
    open var playbackEventsToListen: [String] = []
    private var playbackEventsListenIds: [String] = []
    private(set) var core: Core?
    static var hasAlreadyRegisteredPlaybacks = false
    private let baseObject = BaseObject()

    override open func viewDidLoad() {
        super.viewDidLoad()
        core?.parentView = view

        if isMediaControlEnabled {
            core?.parentView = contentOverlayView
            core?.parentController = self
        }

        core?.trigger(.didAttachView)

        NotificationCenter.default.addObserver(self, selector: #selector(Player.willEnterForeground), name:
            UIApplication.willEnterForegroundNotification, object: nil)

        core?.render()
    }

    open var isMediaControlEnabled: Bool {
        return core?.options[kMediaControl] as? Bool ?? false
    }

    @objc private func willEnterForeground() {
        if let playback = activePlayback as? AVFoundationPlayback, !isMediaControlEnabled {
            Logger.logDebug("forced play after return from background", scope: "Player")
            playback.play()
        }
    }

    public var focusEnvironments: [UIView] {
        return contentOverlayView?.subviews.first?.subviews ?? []
    }

    open override func shouldUpdateFocus(in context: UIFocusUpdateContext) -> Bool {
        return context.nextFocusedView is UIButton
    }

    open var activeContainer: Container? {
        return core?.activeContainer
    }

    open var activePlayback: Playback? {
        return core?.activePlayback
    }

    open var isFullscreen: Bool {
        guard let core = core else {
            return false
        }

        return core.isFullscreen
    }

    open var state: PlaybackState {
        return activePlayback?.state ?? .none
    }

    open var duration: Double {
        return activePlayback?.duration ?? 0
    }

    open var position: Double {
        return activePlayback?.position ?? 0
    }

    open var subtitles: [MediaOption]? {
        return activePlayback?.subtitles
    }

    open var audioSources: [MediaOption]? {
        return activePlayback?.audioSources
    }

    open var selectedSubtitle: MediaOption? {
        get {
            return activePlayback?.selectedSubtitle
        }
        set {
            activePlayback?.selectedSubtitle = newValue
        }
    }

    open var selectedAudioSource: MediaOption? {
        get {
            return activePlayback?.selectedAudioSource
        }
        set {
            activePlayback?.selectedAudioSource = newValue
        }
    }

    public init(options: Options = [:], externalPlugins: [Plugin.Type] = []) {
        super.init(nibName: nil, bundle: nil)

        Player.register(playbacks: [])
        Player.register(plugins: externalPlugins)

        Logger.logInfo("loading with \(options)", scope: "Clappr")

        playbackEventsToListen.append(contentsOf:
            [Event.ready.rawValue, Event.error.rawValue,
             Event.playing.rawValue, Event.didComplete.rawValue,
             Event.didPause.rawValue, Event.stalling.rawValue,
             Event.didStop.rawValue, Event.didUpdateBuffer.rawValue,
             Event.willPlay.rawValue, Event.didUpdatePosition.rawValue,
             Event.willPause.rawValue, Event.willStop.rawValue,
             Event.willSeek.rawValue, Event.didUpdateAirPlayStatus.rawValue,
             Event.didSeek.rawValue, Event.didFindSubtitle.rawValue,
             Event.didFindAudio.rawValue, Event.didSelectSubtitle.rawValue,
             Event.didSelectAudio.rawValue, Event.didUpdateBitrate.rawValue
            ]
        )

        setCore(with: options)

        bindCoreEvents()
        bindPlaybackEvents()
        
        core?.load()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setCore(with options: Options) {
        core = CoreFactory.create(with: options)
    }

    private func bindCoreEvents() {
        core?.on(Event.willChangeActivePlayback.rawValue) { [weak self] _ in self?.unbindPlaybackEvents() }
        core?.on(Event.didChangeActivePlayback.rawValue) { [weak self] _ in self?.bindPlaybackEvents() }
        core?.on(Event.didEnterFullscreen.rawValue) { [weak self] (info: EventUserInfo) in self?.forward(.requestFullscreen, userInfo: info) }
        core?.on(Event.didExitFullscreen.rawValue) { [weak self] (info: EventUserInfo) in self?.forward(.exitFullscreen, userInfo: info) }
    }

    open func load(_ source: String, mimeType: String? = nil) {
        guard let core = core else { return }
        let newOptions = core.options.merging([kSourceUrl: source, kMimeType: mimeType as Any], uniquingKeysWith: { _, second in second })
        configure(options: newOptions)
        play()
    }

    open func configure(options: Options) {
        core?.options = options
        core?.load()
    }

    open func play() {
        activePlayback?.play()
    }

    open func pause() {
        activePlayback?.pause()
    }

    open func stop() {
        activePlayback?.stop()
    }

    open func seek(_ timeInterval: TimeInterval) {
        activePlayback?.seek(timeInterval)
    }

    open func mute(enabled: Bool) {
        activePlayback?.mute(enabled)
    }

    open func setFullscreen(_ fullscreen: Bool) {
        core?.setFullscreen(fullscreen)
    }

    open var options: Options? {
        return core?.options
    }

    open func getPlugin(name: String) -> Plugin? {
        var plugins: [Plugin] = core?.plugins ?? []
        let containerPlugins: [Plugin] = activeContainer?.plugins ?? []

        plugins.append(contentsOf: containerPlugins)

        return plugins.first(where: { $0.pluginName == name })
    }

    @discardableResult
    open func on(_ event: Event, callback: @escaping EventCallback) -> String {
        return baseObject.on(event.rawValue, callback: callback)
    }

    @discardableResult
    public func on(_ eventName: String, callback: @escaping EventCallback) -> String {
        return baseObject.on(eventName, callback: callback)
    }

    open func trigger(_ eventName: String) {
        baseObject.trigger(eventName)
    }

    open func trigger(_ eventName: String, userInfo: EventUserInfo) {
        baseObject.trigger(eventName, userInfo: userInfo)
    }

    @discardableResult
    open func listenTo<T: EventProtocol>(_ contextObject: T, eventName: String, callback: @escaping EventCallback) -> String {
        return baseObject.listenTo(contextObject, eventName: eventName, callback: callback)
    }

    private func bindPlaybackEvents() {
        if let playback = core?.activePlayback {
            for event in playbackEventsToListen {
                let listenId = baseObject.listenTo(
                    playback, eventName: event,
                    callback: { [weak self] (info: EventUserInfo) in
                        self?.baseObject.trigger(event, userInfo: info)
                })

                playbackEventsListenIds.append(listenId)
            }

            let listenId = baseObject.listenToOnce(playback, eventName: Event.playing.rawValue, callback: { [weak self] _ in self?.bindPlayer(playback: playback) })
            playbackEventsListenIds.append(listenId)
        }
    }

    private func bindPlayer(playback: Playback?) {
        if let avFoundationPlayback = (playback as? AVFoundationPlayback), let player = avFoundationPlayback.player {
            self.player = player
            delegate = avFoundationPlayback
        }
    }

    private func unbindPlaybackEvents() {
        for eventId in playbackEventsListenIds {
            baseObject.stopListening(eventId)
        }

        playbackEventsListenIds.removeAll()
    }

    open class func register(playbacks: [Playback.Type]) {
        if !hasAlreadyRegisteredPlaybacks {
            Loader.shared.register(playbacks: [AVFoundationPlayback.self])
            hasAlreadyRegisteredPlaybacks = true
        }
        Loader.shared.register(playbacks: playbacks)
    }

    private class func register(plugins: [Plugin.Type]) {
        Loader.shared.register(plugins: plugins)
    }

    private func forward(_ event: Event, userInfo: EventUserInfo) {
        baseObject.trigger(event.rawValue, userInfo: userInfo)
    }

    open func destroy() {
        Logger.logDebug("destroying", scope: "Player")
        baseObject.stopListening()
        Logger.logDebug("destroying core", scope: "Player")
        core?.destroy()
        Logger.logDebug("destroying viewController", scope: "Player")
        destroyViewController()
        Logger.logDebug("destroyed", scope: "Player")
    }

    private func destroyViewController() {
        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }

    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if presentedViewController == nil {
            destroy()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension Player {
    private var isPaused: Bool {
        return activePlayback?.state == .paused
    }

    private var isPlaying: Bool {
        return activePlayback?.state == .playing
    }

    open override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if presses.containsAny(pressTypes: [.select, .playPause]) && isPaused {
            activePlayback?.trigger(.willPlay)
        }
        
        super.pressesBegan(presses, with: event)
    }
}

extension Set where Element == UIPress {
    func containsAny(pressTypes: [UIPress.PressType]) -> Bool {
        return self.contains { pressTypes.contains($0.type) }
    }
}
