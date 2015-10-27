React     = require 'react'
ReactDOM  = require 'react-dom'
VisualizationGraphComponent = require './../views/components/visualization-graph.cjsx'

class VisualizationGraphView extends Backbone.View
  
  initialize: ->
    console.log 'initialize GraphView'
    @collection.once 'sync', @onCollectionSync , @

  onCollectionSync: =>
    @collection.bind 'change', @onCollectionChange, @
    @render()

  onCollectionChange: (e) =>
    #console.log 'Collection has changed', e

  render: () ->
    console.log 'render GraphView'
    ReactDOM.render React.createElement(VisualizationGraphComponent, {data: @collection.models}), @$el.get(0)
    return this

module.exports = VisualizationGraphView