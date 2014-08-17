AnalysisServer = require './analysis_server'
AnalysisView = require './views/analysis_view'
AnalysisDecorator = require './analysis_decorator'

{Model} = require 'theorist'
spawn = require('child_process').spawn
extname = require('path').extname

module.exports =
class AnalysisComponent extends Model
  subscriptions: []
  analysisStatusView: null
  analysisView: null
  analysisServer: null
  analysisDecorator: null

  enable: =>
    @subscriptions.push atom.project.on 'path-changed', @watchDartProject
    @watchDartProject()
    @createAnalysisStatusView()
    @createAnalysisView()
    @analysisDecorator = new AnalysisDecorator(this)


  disable: =>
    @cleanup()

  isDartProject: =>
    pubspec = atom.project.getRootDirectory().getFile('pubspec.yaml')
    pubspec.exists()

  watchDartProject: =>
    @cleanup()

    return unless @isDartProject()

    rootPath = atom.project.getPath()
    @analysisServer = new AnalysisServer(rootPath)
    @analysisServer.start atom.project.getPath()

    @analysisServer.on 'analysis', (result) =>
      @emit 'dart-tools:analysis', result

    @analysisServer.on 'refresh', (fullPath) =>
      @emit 'dart-tools:refresh', fullPath

  checkFile: (fullPath) =>
    if extname(fullPath) == '.dart'
      @analysisServer.check(fullPath)

  cleanup: =>
    subscription.off() for subscription in @subscriptions
    @subscriptions = []
    @watcher?.close()
    @analysisServer?.stop()
    @analysisStatusView?.detach()

  createAnalysisStatusView: =>
    return unless @isDartProject()
    atom.packages.once 'activated', =>
      {statusBar} = atom.workspaceView
      if statusBar?
        AnalysisStatusView = require './views/analysis_status_view'
        @analysisStatusView = new AnalysisStatusView(statusBar)
        @analysisStatusView.attach()

  createAnalysisView: =>
    atom.packages.once 'activated', =>
      @analysisView = new AnalysisView()
      @analysisView.attach()

  showProblems: =>
    console.log 'showing problems'
