ScrollSearch = require './scroll-searcher-view'
ScrollMarker = require './scroll-marker'
{CompositeDisposable, Emitter} = require 'event-kit'
{TextEditor} = require 'atom'

class Main
  editor: null
  subscriptions: null
  model: null
  scrollMarker: null
  previousHeight: null
  previousScrollHeight: null
  activated: false
  # configuration settings. It includes color, size and opacity of scroll searchers.
  config:
    color:
      type: 'color'
      default: '#4de5ff'
      title: 'Set the color of scroll-searchers'
      description: 'Pick a color for scroll-searchers from the color box'
    size:
      type: 'integer'
      default:1
      enum: [1, 2, 3]
      title: 'Set the size of scroll-searchers'
      description: 'Pick a size for scroll-searchers from the drop-down list'
    scrOpacity:
      type: 'integer'
      default: 65
      title: 'Scrollbar Opacity'
      minimum: 0
      maximum: 80
      description: 'Set the scrollbar opacity for better visibility'
    findAndReplace:
      type: 'boolean'
      default : false
      title: 'Retain markers on hiding find-and-replace bar'
      description : 'Set this property to true if you want to retain the markers after closing the find-and-replace pane'

  activate: (state) ->
    #Activate the package. The package is automatically activated once the text editor is opened
    @emitter = new Emitter
    @previousHeight = 0
    @subs = new CompositeDisposable
    @subscriptions = new CompositeDisposable
    @subs.add atom.commands.add 'atom-workspace',
      'scroll-searcher:toggle': => @toggle()
      'core:close': => @deactivate()
      'core:cancel': => @hide()
      'find-and-replace:show': => @show()
    @toggle()

  hide: =>
    # emits hide signal when find-and-replace bar is hidden
    if not atom.config.get('scroll-searcher.findAndReplace')
      if not @model.mainModule.findPanel.visible
        @emitter.emit 'did-hide'

  show: =>
    @emitter.emit 'did-show'

  deactivate: ->
    @subscriptions.dispose()
    @subs.dispose()
    if @scrollMarker
      @scrollMarker.destroy()
    @emitter.emit 'did-deacitvate'
    @activated = false

  isPackageActive: (findPackage) =>
    if findPackage.name == 'find-and-replace'
      @initializePackage()

  initializePackage: ->
    if @activated
      # Check for active find-and-replace package
      @model = atom.packages.getActivePackage('find-and-replace')
      if @model
        # Initiate an new scroll-marker class if an active find-and-replace model is found
        @scrollMarker = new ScrollMarker(@model,this)
        # Toggle with the view of find-and-replace
        atom.config.observe 'scroll-searcher.findAndReplace', (value) =>
          if value
            @show()
          else
            @hide()
      else
        return
      # Observe change in active text editor window
      @subscriptions.add atom.workspace.observePaneItems(@on)
      @subscriptions.add atom.workspace.observeActivePaneItem(@markOnEditorChange)

  toggle: ->
    if not @activated
      @activated = true
      @subscriptions = new CompositeDisposable
      @subscriptions.add atom.packages.onDidActivatePackage(@isPackageActive)
      @initializePackage()
    else
      @activated = false
      @subscriptions.dispose()
      if @scrollMarker?
        @scrollMarker.destroy()
      @emitter.emit 'did-deacitvate'

  onDidDeactivate: (callback) ->
    @emitter.on 'did-deacitvate', callback

  onDidShow: (callback) ->
    @emitter.on 'did-show', callback

  onDidHide: (callback) ->
    @emitter.on 'did-hide', callback

  # Change scroll searchers on change in height of editor
  markOnHeightUpdate: =>
    if @editor?
      if @editor instanceof TextEditor
        # If old height does not match new height than update markers
        if @editor.displayBuffer.height != @previousHeight
          @previousHeight = @editor.displayBuffer.height
          @scrollMarker.updateMarkers()
      else
        return

  # Update scroll-searchers if current editor window is switched with another
  markOnEditorChange: (editor) =>
    @editor = editor
    if @editor instanceof TextEditor
      @model = atom.packages.getActivePackage('find-and-replace')
      if @model
        @scrollMarker.updateModel(@model)
        @scrollMarker.updateMarkers()
        # Get the scrollbar domnode of new editor window
        @verticalScrollbar = atom.views.getView(editor).component.rootElement?.querySelector('.vertical-scrollbar')
        if @verticalScrollbar
          @verticalScrollbar.style.opacity = "0.#{atom.config.get('scroll-searcher.scrOpacity')}"
    else
      return

  on: (editor) =>
    if editor instanceof TextEditor
      # Initiate scroll-searcher class if it doesn't exist already
      if @scrollSearcherExists(editor)
        @subscriptions.add atom.views.getView(editor).component.presenter.onDidUpdateState(@markOnHeightUpdate.bind(this))
        scrollSearch = new ScrollSearch(this)
        @editorView = atom.views.getView(editor).component.rootElement?.firstChild
        @editorView.appendChild(scrollSearch.getElement())
        @verticalScrollbar = atom.views.getView(editor).component.rootElement?.querySelector('.vertical-scrollbar')
        @verticalScrollbar.style.opacity = "0.65"


  scrollSearcherExists: (editor) ->
    @scrollView = atom.views.getView(editor).rootElement?.querySelector('.scroll-searcher')
    if @scrollView?
      return false
    else
      return true

module.exports = new Main()
