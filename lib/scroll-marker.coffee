ScrollLine = require './scroll-line'
ScrollSearch = require './scroll-searcher-view'
{CompositeDisposable, Emitter} = require 'event-kit'
module.exports =
class ScrollMarker
  editor: null
  model : null
  scrollHeight: null
  constructor: (argModel,@main) ->
    @markers = {}
    @subscriptions = new CompositeDisposable
    @emitter = new Emitter
    @model = argModel
    @editor = atom.workspace.getActiveTextEditor()

  onDidDestroy: (callback) ->
    @emitter.on 'did-destroy', callback

  onDidUpdateMarkers: (callback) ->
    @emitter.on 'did-update-markers', callback

  destroy: ->
    @markers = {}
    @subscriptions.dispose()
    @emitter.emit 'did-destroy'

  updateModel: (argModel) =>
    @model = argModel
    @subscriptions.dispose()
    @subscriptions = new CompositeDisposable
    @subscriptions.add @model.mainModule.findModel.resultsMarkerLayer.onDidCreateMarker(@createMarker.bind(this))

  createMarker: (marker) =>
    @editor = atom.workspace.getActiveTextEditor()
    newScrollHeight = @editor.getScrollHeight()
    if newScrollHeight != @scrollHeight
      @updateMarkers()
      return
    displayHeight = @editor.displayBuffer.height
    lineHeight = @editor.displayBuffer.getLineHeightInPixels()
    row = marker.getBufferRange().start.row
    scrollMarker = Math.round((row*lineHeight*displayHeight)/@scrollHeight)
    if not @markers[scrollMarker]
      @markers[scrollMarker] = 1
    else
      @markers[scrollMarker] = @markers[scrollMarker] + 1
    @scrollView = atom.views.getView(@editor).rootElement?.querySelector('.scroll-searcher')
    if @scrollView
      lineClass = new ScrollLine(scrollMarker, @markers,marker, this)
      line = lineClass.getElement()
      @scrollView.appendChild(line)
    else
      @scrollClass = new ScrollSearch(@main)
      @scrollView = @scrollClass.getElement()
      @editorView = atom.views.getView(@editor).component.rootElement?.firstChild
      @editorView.appendChild(@scrollClass.getElement())
      verticalScrollbar = atom.views.getView(@editor).component.rootElement?.querySelector('.vertical-scrollbar')
      verticalScrollbar.style.opacity = "0.65"
      lineClass = new ScrollLine(scrollMarker, @markers,marker, this)
      line = lineClass.getElement()
      @scrollView.appendChild(line)

  updateMarkers: =>
    @emitter.emit 'did-destroy'
    @editor = atom.workspace.getActiveTextEditor()
    @markers = {}
    updatedMarkers = @model.mainModule.findModel.resultsMarkerLayer.findMarkers({class: 'find-result'})
    @scrollHeight = @editor.getScrollHeight()
    displayHeight = @editor.displayBuffer.height
    lineHeight = @editor.displayBuffer.getLineHeightInPixels()
    @scrollView = atom.views.getView(@editor).rootElement?.querySelector('.scroll-searcher')
    # @scrollView.innerHTML = ''
    for marker in updatedMarkers
      row = marker.getBufferRange().start.row
      scrollMarker = Math.round((row*lineHeight*displayHeight)/@scrollHeight)
      if @markers[scrollMarker]
        @markers[scrollMarker] = @markers[scrollMarker] + 1
      else
        @markers[scrollMarker] = 1;
      lineClass = new ScrollLine(scrollMarker, @markers,marker,this)
      line = lineClass.getElement()
      if @scrollView
        @scrollView.appendChild(line)
      else
        @scrollClass = new ScrollSearch(@main)
        @scrollView = @scrollClass.getElement()
        @editorView = atom.views.getView(@editor).component.rootElement?.firstChild
        verticalScrollbar = atom.views.getView(@editor).component.rootElement?.querySelector('.vertical-scrollbar')
        verticalScrollbar.style.opacity = "0.65"
        @editorView.appendChild(@scrollClass.getElement())
        @scrollView.appendChild(line)
    @emitter.emit 'did-update-markers'
