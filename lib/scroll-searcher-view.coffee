{CompositeDisposable} = require 'event-kit'
module.exports =
class ScrollSearch

  constructor: (@main) ->
    @domNode = document.createElement('div')
    @domNode.classList.add "scroll-searcher"
    @subscriptions = new CompositeDisposable
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
