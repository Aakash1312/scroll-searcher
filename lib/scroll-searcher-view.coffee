{CompositeDisposable} = require 'event-kit'
module.exports =
class ScrollSearch

  constructor: (@main) ->
    # This class defines HTML container for scrollbar markers
    @domNode = document.createElement('div')
    @domNode.classList.add "scroll-searcher"
    @subscriptions = new CompositeDisposable
    # Event subscriptions
    @subscriptions.add @main.onDidDeactivate(@destroy.bind(this))
    @subscriptions.add @main.onDidHide(@hide.bind(this))
    @subscriptions.add @main.onDidShow(@show.bind(this))
  destroy: =>
    @domNode.remove()
    @subscriptions.dispose()

  getElement: ->
    @domNode

  hide: ->
    @domNode.style.visibility = "hidden"

  show: ->
    @domNode.style.visibility = "visible"
