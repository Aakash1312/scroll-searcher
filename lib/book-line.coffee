{CompositeDisposable} = require 'event-kit'
module.exports =
class BookLine

  constructor: (@margin,@scrollMarker) ->
    @domNode = document.createElement('div')
    @domNode.classList.add "scroll-marker"
    # Set the top margin, border color and border width of the scroll-bar markers according to the configuration settings
    @domNode.style.marginTop = "#{@margin}px"
    @domNode.style.borderColor = "#f00"
    @domNode.style.borderTopWidth = "0px"
    # Add event subscriptions to observe changes in editor window
    @subscriptions = new CompositeDisposable
    @subscriptions.add @scrollMarker.onDidDestroy(@completeDestruction.bind(this))

  completeDestruction: =>
    @domNode.remove()
    @subscriptions.dispose()
  getElement: ->
    @domNode
