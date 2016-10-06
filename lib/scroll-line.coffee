{CompositeDisposable} = require 'event-kit'
module.exports =
class ScrollLine

  constructor: (@margin, @markers, @marker, @scrollMarker) ->
    @domNode = document.createElement('div')
    @domNode.classList.add "scroll-marker"
    # Set the top margin, border color and border width of the scroll-bar markers according to the configuration settings
    @domNode.style.marginTop = "#{@margin}px"
    @domNode.style.borderColor = atom.config.get('scroll-searcher.color').toHexString()
    @domNode.style.borderTopWidth = "#{atom.config.get('scroll-searcher.size') - 1}px"
    # Add event subscriptions to observe changes in editor window
    @subscriptions = new CompositeDisposable
    @subscriptions.add @marker.onDidDestroy(@destroy.bind(this))
    @subscriptions.add @marker.onDidChange(@change.bind(this))
    @subscriptions.add @scrollMarker.onDidDestroy(@completeDestruction.bind(this))

  destroy: =>
    # Remove domnode and dispose off subscriptions
    @domNode.remove()
    @subscriptions.dispose()
    @markers[@margin] = @markers[@margin] - 1
    if @markers[@margin] == 0
      delete @markers[@margin]
  change: =>
    @domNode.remove()
    @subscriptions.dispose()
    @markers[@margin] = @markers[@margin] - 1
    if @markers[@margin] == 0
      delete @markers[@margin]
    if not @marker.isDestroyed()
      @scrollMarker.createMarker(@marker)

  completeDestruction: =>
    @domNode.remove()
    @subscriptions.dispose()
  getElement: ->
    @domNode
