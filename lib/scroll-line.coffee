{CompositeDisposable} = require 'event-kit'
module.exports =
class ScrollLine

  constructor: (@margin, @markers, @marker, @scrollMarker) ->
    @domNode = document.createElement('div')
    @domNode.classList.add "scroll-marker"
    @domNode.style.marginTop = "#{@margin}px"
    @domNode.style.borderColor = atom.config.get('scroll-searcher.color').toHexString()
    @domNode.style.borderTopWidth = "#{atom.config.get('scroll-searcher.size') - 1}px"
    @subscriptions = new CompositeDisposable
    @subscriptions.add @marker.onDidDestroy(@destroy.bind(this))
    @subscriptions.add @marker.onDidChange(@change.bind(this))
    @subscriptions.add @scrollMarker.onDidDestroy(@completeDestruction.bind(this))
  # Tear down any state and detach
  destroy: =>
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
    console.log "here it was"
    @domNode.remove()
    @subscriptions.dispose()
    # editor = atom.workspace.getActiveTextEditor();
    # scrollHeight = @editor.getScrollHeight()
    # displayHeight = @editor.displayBuffer.height
    # lineHeight = @editor.displayBuffer.getLineHeightInPixels()
    # @domNode.style.marginTop = Math.round(((@domNode.style.marginTop)*lineHeight*displayHeight)/@scrollHeight)
    # console.log @domNode
  getElement: ->
    @domNode
