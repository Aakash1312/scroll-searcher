{CompositeDisposable} = require 'event-kit'
module.exports =
class ScrollSearch

  constructor: (scrollMarker, @main) ->
    @scrollSearchers = scrollMarker
    @domNode = document.createElement('div')
    @domNode.classList.add "scroll-searcher"
    @subscriptions = new CompositeDisposable
    @subscriptions.add @main.onDidDeactivate(@destroy.bind(this))

  destroy: =>
    @domNode.remove()
    @subscriptions.dispose()

  getElement: ->
    @domNode
