_ = require 'underscore-plus'
{$} = require 'atom-space-pen-views'
describe 'Main', ->
  [workspaceElement, editorView, editor, activationPromise,scrollActivationPromise, scrollMarker, findViews] = []

  beforeEach ->


    waitsForPromise ->
      atom.workspace.open('sample.js')

    runs ->
      workspaceElement = atom.views.getView(atom.workspace)
      jasmine.attachToDOM(workspaceElement)
      editor = atom.workspace.getActiveTextEditor()
      editorView = atom.views.getView(editor)
      activationPromise = atom.packages.activatePackage("find-and-replace").then ({mainModule}) ->
        mainModule.createViews()
        findViews = mainModule
      scrollActivationPromise = atom.packages.activatePackage("scroll-searcher").then ({mainModule}) ->
        scrollMarker = mainModule.scrollMarker

  describe "when find-and-replace is activated", ->
    beforeEach ->
      atom.commands.dispatch editorView, 'find-and-replace:show'
      waitsForPromise ->
        activationPromise

    describe "when scroll-searcher is toggled", ->
      beforeEach ->
        atom.commands.dispatch editorView, 'scroll-searcher:toggle'

        waitsForPromise ->
          scrollActivationPromise
      it "attaches scroll-searcher to the root view", ->
        expect(editorView.rootElement.querySelector('.scroll-searcher')).toExist()
      it "destroys scroll-searchers when toggled twice", ->
        atom.commands.dispatch editorView, 'scroll-searcher:toggle'
        expect(editorView.rootElement.querySelector('.scroll-searcher')).not.toExist()

      it "updates scroll markers when window height is changed", ->
        editor = atom.workspace.getActiveTextEditor()
        editor.setHeight(400)
        spy = jasmine.createSpy('updateMarkers')
        scrollMarker.onDidUpdateMarkers(spy)
        editor.setHeight(200)
        expect(spy).toHaveBeenCalled()
      describe "when editor is filled", ->
        beforeEach ->
          editor.setText """
            aaa aaa bbb
            aaabb ccccc
            Aaa ddd ccc
          """
          findViews.findModel.search "aaa"
        it 'creates scroll-markers appropriately', ->
          expect(scrollMarker.markers).toEqual {
              0 : 2,
              24 : 1,
              48 : 1
          }
        it 'creates scroll-marker when find-and-replace marker is created', ->
          editor.setCursorBufferPosition([2, 11])
          editor.insertNewline()
          advanceClock(editor.buffer.stoppedChangingDelay)
          editor.setCursorBufferPosition([3, 0])
          editor.insertText("aaa")
          advanceClock(editor.buffer.stoppedChangingDelay)
          expect(scrollMarker.markers).toEqual {
              0 : 2,
              24 : 1,
              48 : 1,
              72 : 1
          }
        it 'decrements scroll-marker when find-and-replace marker is destroyed', ->
          editor.setCursorBufferPosition([0, 1])
          editor.insertText(".")
          advanceClock(editor.buffer.stoppedChangingDelay)
          expect(scrollMarker.markers).toEqual {
              0 : 1,
              24 : 1,
              48 : 1
          }
        it 'increments scroll-marker when find-and-replace marker is created in a row already containing find-and-replace markers', ->
          editor.setCursorBufferPosition([2, 0])
          editor.insertText("aaa")
          advanceClock(editor.buffer.stoppedChangingDelay)
          expect(scrollMarker.markers).toEqual {
              0 : 2,
              24 : 1,
              48 : 2,
          }
        it 'destroys scroll-marker when all find-and-replace markers are destroyed in a row', ->
          editor.setCursorBufferPosition([1, 1])
          editor.insertText(".")
          advanceClock(editor.buffer.stoppedChangingDelay)
          expect(scrollMarker.markers).toEqual {
              0 : 2,
              48 : 1
          }

        it 'changes scroll-markers when find-and-replace marker is changed', ->
          editor.setCursorBufferPosition([1, 0])
          editor.insertNewline()
          advanceClock(editor.buffer.stoppedChangingDelay)
          expect(scrollMarker.markers).toEqual {
              0 : 2,
              48 : 1,
              72 : 1
          }

        it 'creates appropriate scroll-markers when search is case sensitive', ->
          findViews.findModel.search "aaa",
            caseSensitive: true
          expect(scrollMarker.markers).toEqual {
              0 : 2,
              24 : 1
          }
        it 'creates appropriate scroll-markers when regex is used', ->
          findViews.findModel.search "b+",
            useRegex: true
          expect(scrollMarker.markers).toEqual {
              0 : 1,
              24 : 1
          }
        it 'creates appropriate scroll-markers when whole word is searched', ->
          findViews.findModel.search "aaa",
            wholeWord: true
          expect(scrollMarker.markers).toEqual {
              0 : 2,
              48 : 1
          }

        it 'updates scroll-markers when scroll height is changed', ->
          scrollHeight = editor.getScrollHeight()
          while true
            preScrollHeight = editor.getScrollHeight()
            if preScrollHeight > scrollHeight
              break
            editor.insertNewline()
            advanceClock(editor.buffer.stoppedChangingDelay)
          spy = jasmine.createSpy('updateMarkers')
          scrollMarker.onDidUpdateMarkers(spy)
          editor.insertNewline()
          advanceClock(editor.buffer.stoppedChangingDelay)
          expect(spy).toHaveBeenCalled()

      describe "when new editor is opened", ->
        beforeEach ->
          waitsForPromise ->
            atom.workspace.open('sample2.js')
        it "attaches scroll-searcher to the root view when new editor is opened", ->
          editors = atom.workspace.getTextEditors()
          for editor in editors
            ev = atom.views.getView(editor)
            expect(ev.rootElement.querySelector('.scroll-searcher')).toExist()
        it "updates scroll markers when next editor is activated", ->
          spy = jasmine.createSpy('updateMarkers')
          scrollMarker.onDidUpdateMarkers(spy)
          atom.commands.dispatch editorView, 'pane:show-next-item'
          expect(spy).toHaveBeenCalled()
  describe "when find-and-replace is not toggled", ->
    describe "when scroll-searcher is toggled", ->
      beforeEach ->
        atom.commands.dispatch editorView, 'scroll-searcher:toggle'

        waitsForPromise ->
          scrollActivationPromise
      it "does not attach scroll-searchers to root view", ->
        expect(editorView.rootElement.querySelector('.scroll-searcher')).not.toExist()

      it "attaches scroll-searchers to root view when find-and-replace is toggled", ->
        atom.commands.dispatch editorView, 'find-and-replace:show'
        waitsForPromise ->
          activationPromise
        runs ->
          expect(editorView.rootElement.querySelector('.scroll-searcher')).toExist()
