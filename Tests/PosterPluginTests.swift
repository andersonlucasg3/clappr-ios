import Quick
import Nimble
@testable import Clappr

class PosterPluginTests: QuickSpec {

    override func spec() {

        describe(".PosterPlugin") {
            var container: Container!
            let options = [
                kSourceUrl: "http://globo.com/video.mp4",
                kPosterUrl: "http://clappr.io/poster.png",
            ]

            context("when container has no options") {
                it("plugin is set to invisible") {
                    container = Container()
                    container.render()

                    let posterPlugin = self.getPosterPlugin(container)

                    expect(posterPlugin.isHidden).to(beTrue())
                }
            }

            context("when container doesnt have posterUrl option") {
                it("plugin is set to invisible") {
                    container = Container(options: ["anotherOption": true])
                    container.render()

                    let posterPlugin = self.getPosterPlugin(container)

                    expect(posterPlugin.isHidden).to(beTrue())
                }
            }

            context("when container has posterUrl option") {
                it("plugin is render") {
                    container = Container(options: options)
                    container.render()

                    let posterPlugin = self.getPosterPlugin(container)

                    expect(posterPlugin.superview) == container
                }

                it("Should be hidden if playback is a NoOp") {
                    container = Container(options: [kSourceUrl: "none", kPosterUrl: "http://clappr.io/poster.png"])
                    container.render()

                    let posterPlugin = self.getPosterPlugin(container)

                    expect(posterPlugin.isHidden).to(beTrue())
                }
            }

            context("State") {
                var posterPlugin: PosterPlugin!

                beforeEach {
                    container = Container(options: options)
                    container.render()
                    posterPlugin = self.getPosterPlugin(container)
                }

                context("when container trigger a play event") {
                    it("plugin is set to invisible") {
                        expect(posterPlugin.isHidden).to(beFalse())
                        container.playback?.trigger(Event.playing.rawValue)
                        expect(posterPlugin.isHidden).to(beTrue())
                    }
                }

                context("when container trigger a end event") {
                    it("plugin is set to visible") {
                        container.playback?.trigger(Event.playing.rawValue)
                        container.playback?.trigger(Event.didComplete.rawValue)

                        expect(posterPlugin.isHidden).to(beFalse())
                    }
                }
            }
        }
    }

    private func getPosterPlugin(_ container: Container) -> PosterPlugin {
        return container.plugins.filter({ $0.isKind(of: PosterPlugin.self) }).first as! PosterPlugin
    }
}
