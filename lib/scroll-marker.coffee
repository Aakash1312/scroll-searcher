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
    # Check if current version of Atom supports find-and-replace API
    @hasApi = parseFloat(atom.packages.getLoadedPackage('find-and-replace').metadata.version) >= 0.194

  onDidDestroy: (callback) ->
    @emitter.on 'did-destroy', callback

  onDidUpdateMarkers: (callback) ->
    @emitter.on 'did-update-markers', callback

  destroy: ->
    @markers = {}
    @subscriptions.dispose()
    @emitter.emit 'did-destroy'

  updateModel: (argModel) =>
    # Update the find-and-replace model
    @model = argModel
    @subscriptions.dispose()
    @subscriptions = new CompositeDisposable
    @subscriptions.add @model.mainModule.findModel.resultsMarkerLayer.onDidCreateMarker(@createMarker.bind(this))


  # Create an new scroll-marker for every newly formed find-and-replace marker
  createMarker: (marker) =>
    @editor = atom.workspace.getActiveTextEditor()
    newScrollHeight = @editor.getScrollHeight()
    if newScrollHeight != @scrollHeight
      @updateMarkers()
      return
    displayHeight = @editor.displayBuffer.height
    lineHeight = @editor.displayBuffer.getLineHeightInPixels()
    row = marker.getScreenRange().start.row
    # Set the position of scroll-searcher according to configured settings
    if atom.config.get('scroll-searcher.size') is 1
      scrollMarker = Math.round((row*lineHeight*displayHeight)/@scrollHeight)
    else
      if atom.config.get('scroll-searcher.size') is 2
        scrollMarker = Math.floor((row*lineHeight*displayHeight)/@scrollHeight)
      else
        scrollMarker = Math.round((row*lineHeight*displayHeight)/@scrollHeight) - 1
    if not @markers[scrollMarker]
      @markers[scrollMarker] = 1
    else
      @markers[scrollMarker] = @markers[scrollMarker] + 1
    @scrollView = atom.views.getView(@editor).rootElement?.querySelector('.scroll-searcher')
    if @scrollView
      # Create a new scroll line with the position given by scrollMarker variable
      lineClass = new ScrollLine(scrollMarker, @markers,marker, this)
      line = lineClass.getElement()
      @scrollView.appendChild(line)
    else
      # If scroll-searcher class doesn't exist, then create a new class (This can be the case when a new editor window is opened or switched to)
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
    # emit destroy signal to delete previous scroll-searchers
    @emitter.emit 'did-destroy'
    @editor = atom.workspace.getActiveTextEditor()
    @markers = {}
    updatedMarkers = {}
    # Get the updated markers from find-and-replace results
    if(@hasApi)
      atom.packages.serviceHub.consume 'find-and-replace', '0.0.1', (fnr) =>
        if(fnr)
          @layer = fnr.resultsMarkerLayerForTextEditor(@editor);
          updatedMarkers = @layer.findMarkers();
          @scrollHeight = @editor.getScrollHeight()
          displayHeight = @editor.displayBuffer.height
          lineHeight = @editor.displayBuffer.getLineHeightInPixels()
          @scrollView = atom.views.getView(@editor).rootElement?.querySelector('.scroll-searcher')
          for marker in updatedMarkers
            row = marker.getScreenRange().start.row
            if atom.config.get('scroll-searcher.size') is 1
              scrollMarker = Math.round((row*lineHeight*displayHeight)/@scrollHeight)
            else
              if atom.config.get('scroll-searcher.size') is 2
                scrollMarker = Math.floor((row*lineHeight*displayHeight)/@scrollHeight)
              else
                scrollMarker = Math.round((row*lineHeight*displayHeight)/@scrollHeight) - 1

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
          # notify that markers have been updated
          @emitter.emit 'did-update-markers'
        else
          updatedMarkers = @model.mainModule.findModel.resultsMarkerLayer.findMarkers({class: 'find-result'})
          @scrollHeight = @editor.getScrollHeight()
          displayHeight = @editor.displayBuffer.height
          lineHeight = @editor.displayBuffer.getLineHeightInPixels()
          @scrollView = atom.views.getView(@editor).rootElement?.querySelector('.scroll-searcher')
          for marker in updatedMarkers
            row = marker.getScreenRange().start.row
            if atom.config.get('scroll-searcher.size') is 1
              scrollMarker = Math.round((row*lineHeight*displayHeight)/@scrollHeight)
            else
              if atom.config.get('scroll-searcher.size') is 2
                scrollMarker = Math.floor((row*lineHeight*displayHeight)/@scrollHeight)
              else
                scrollMarker = Math.round((row*lineHeight*displayHeight)/@scrollHeight) - 1

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
          # notify that markers have been updated
          @emitter.emit 'did-update-markers'
