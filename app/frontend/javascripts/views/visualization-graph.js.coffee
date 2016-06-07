Node                              = require './../models/node.js'
VisualizationGraphCanvasTest      = require './../views/visualization-graph-canvas-test.js'
VisualizationGraphConfiguration   = require './../views/visualization-graph-configuration.js'
VisualizationGraphNavigation      = require './../views/visualization-graph-navigation.js'
VisualizationGraphInfo            = require './../views/visualization-graph-info.js'
BootstrapSwitch                   = require 'bootstrap-switch'

class VisualizationGraph extends Backbone.View
  
  el:                               '.visualization-graph-component'
  visualizationGraphCanvas:         null
  visualizationGraphConfiguration:  null
  visualizationGraphNavigation:     null
  visualizationGraphInfo:           null

  initialize: ()->
    console.log 'initialize Graph', @collection

    # Setup Views
    #@visualizationGraphCanvas         = new VisualizationGraphCanvas {el: @$el, data: @getDataFromCollection(@collection.nodes.models, @collection.relations.models), parameters: @visualizationGraphConfiguration.parameters}
    @visualizationGraphCanvas         = new VisualizationGraphCanvasTest {el: @$el}
    @visualizationGraphConfiguration  = new VisualizationGraphConfiguration
    @visualizationGraphNavigation     = new VisualizationGraphNavigation
    @visualizationGraphInfo           = new VisualizationGraphInfo

    # Setup Configure Panel Show/Hide
    $('.visualization-graph-menu-actions .btn-configure').click @onPanelConfigureShow
    $('.visualization-graph-panel-configuration .close').click  @onPanelConfigureHide
    # Setup Share Panel Show/Hide
    $('.visualization-graph-menu-actions .btn-share').click     @onPanelShareShow
    $('#visualization-share .close').click                      @onPanelShareHide
   
  # Render method called from VisualizationEdit when all collections synced
  render: (edit, story) ->
    console.log 'render Graph', edit, story

    # Setup visualizationGraphConfiguration model
    @visualizationGraphConfiguration.model = @model
    @visualizationGraphConfiguration.render()

    # Setup visualizationGraphCanvas data if not a Story
    #unless story and !edit
    @visualizationGraphCanvas.setup      @getDataFromCollection(@collection.nodes.models, @collection.relations.models), @visualizationGraphConfiguration.parameters
    if story
      @visualizationGraphCanvas.setOffsetX 230 # translate left half the width of Story Info panel  
    @visualizationGraphCanvas.render()

    # Setup Events Listeners (only in edit mode)
    if !story and edit 
      # Setup Network Analysis modal switches
      $('#network-analysis-modal .switch').bootstrapSwitch()
      # Subscribe Collection Events (handle Table changes)
      @collection.nodes.bind 'add',                 @onNodesAdd, @
      @collection.nodes.bind 'change:name',         @onNodeChangeName, @
      @collection.nodes.bind 'change:node_type',    @onNodeChangeType, @
      @collection.nodes.bind 'change:description',  @onNodeChangeDescription, @
      @collection.nodes.bind 'change:visible',      @onNodeChangeVisible, @
      @collection.nodes.bind 'change:image',        @onNodeChangeImage, @
      @collection.nodes.bind 'remove',              @onNodesRemove, @
      @collection.relations.bind 'change:source_id',      @onRelationsChangeNode, @
      @collection.relations.bind 'change:target_id',      @onRelationsChangeNode, @
      @collection.relations.bind 'change:relation_type',  @onRelationsChangeType, @
      @collection.relations.bind 'change:direction',      @onRelationsChangeDirection, @
      @collection.relations.bind 'remove',                @onRelationsRemove, @
      # Subscribe Config Panel Events
      Backbone.on 'visualization.config.updateNodesColor',            @onUpdateNodesColor, @
      Backbone.on 'visualization.config.updateNodesColorColumn',      @onUpdateNodesColorColumn, @
      Backbone.on 'visualization.config.updateNodesSize',             @onUpdateNodesSize, @
      Backbone.on 'visualization.config.toogleNodesLabel',            @onToogleNodesLabel, @
      Backbone.on 'visualization.config.toogleNodesImage',            @onToogleNodesImage, @
      Backbone.on 'visualization.config.toogleNodesWithoutRelation',  @onToogleNodesWithoutRelation, @
      Backbone.on 'visualization.config.updateRelationsCurvature',    @onUpdateRelationsCurvature, @
      Backbone.on 'visualization.config.updateRelationsLineStyle',    @onUpdateRelationsLineStyle, @
      Backbone.on 'visualization.config.updateForceLayoutParam',      @onUpdateForceLayoutParam, @

    # Subscribe Canvas Events
    Backbone.on 'visualization.node.showInfo',    @onNodeShowInfo, @
    Backbone.on 'visualization.node.hideInfo',    @onNodeHideInfo, @
    # Subscribe Navigation Events
    Backbone.on 'visualization.navigation.zoomin',      @onZoomIn, @
    Backbone.on 'visualization.navigation.zoomout',     @onZoomOut, @
    Backbone.on 'visualization.navigation.fullscreen',  @onFullscreen, @
    

  resize: ->
    # update container height
    h = if $('body').hasClass('fullscreen') then $(window).height() else $(window).height() - 50 - 64 - 64
    @$el.height h
    if @visualizationGraphCanvas and @visualizationGraphCanvas.svg
      @visualizationGraphCanvas.resize()

  setOffsetY: (offset) ->
    if @visualizationGraphCanvas
      @visualizationGraphCanvas.setOffsetY offset

  
  getDataFromCollection: ( nodes, relations ) ->
    console.log 'getDataFromCollection', nodes, relations
    data =
      nodes:      nodes.map     (d) -> return d.attributes
      relations:  relations.map (d) -> return d.attributes
    # Fix relations source & target index (based on 1 instead of 0)
    data.relations.forEach (d) ->
      d.source = d.source_id-1
      d.target = d.target_id-1
    return data


  # Panel Events
  onPanelConfigureShow: =>
    $('html, body').animate { scrollTop: 0 }, 600
    @visualizationGraphConfiguration.$el.addClass 'active'
    @visualizationGraphCanvas.setOffsetX 200 # half the width of Panel Configuration

  onPanelConfigureHide: =>
    @visualizationGraphConfiguration.$el.removeClass 'active'
    @visualizationGraphCanvas.setOffsetX 0

  onPanelShareShow: ->
    $('#visualization-share').addClass 'active'

  onPanelShareHide: ->
    $('#visualization-share').removeClass 'active'


  # Collections Events
  onNodesAdd: (node) ->
    # We need to wait until sync event to get node id
    @collection.nodes.once 'sync', (model) =>
      console.log 'onNodesAdd', model.id, model
      @visualizationGraphCanvas.addNode model.attributes
    , @

  onNodeChangeName: (node) ->
    console.log 'onNodeChangeName', node.attributes.name
    # Update nodes labels
    @visualizationGraphCanvas.updateNodesLabels()
    # Update Panel Info name
    @updateGraphInfoNode node

  onNodeChangeType: (node) ->
    console.log 'onNodeChangeType', node.attributes.name
    @visualizationGraphCanvas.updateNodesType()
    @updateGraphInfoNode node

  onNodeChangeDescription: (node) ->
    console.log 'onNodeChangeDescription', node.attributes.description
    # Update Panel Info description
    @updateGraphInfoNode node

  onNodeChangeVisible: (node) ->
    console.log 'onNodeChangeVisibe', node
    if node.attributes.visible
      @visualizationGraphCanvas.showNode node.attributes
    else
      @visualizationGraphCanvas.hideNode node.attributes
      # Hide Panel Info if visible for current node
      if @visualizationGraphInfo.isVisible() and @visualizationGraphInfo.node.id == node.id
        @visualizationGraphInfo.hide()

  onNodeChangeImage: (node) ->
    console.log 'onNodeChangeImage', node
    @visualizationGraphCanvas.updateImages()
    @visualizationGraphCanvas.updateNodes()

  onNodeChangeCustomField: (node) ->
    # Update Panel Info description
    @updateGraphInfoNode node

  onNodesRemove: (node) ->
    console.log 'onNodesRemove', node.attributes.name
    @visualizationGraphCanvas.removeNode node.attributes
    # Hide Panel Info if visible for current node
    if @visualizationGraphInfo.isVisible() and @visualizationGraphInfo.node.id == node.id
      @visualizationGraphInfo.hide()

  onRelationsChangeNode: (relation) ->
    console.log 'onRelationsChange', relation
    # check if we have both source_id and target_id
    if relation.attributes.source_id and relation.attributes.target_id
      # Remove relation if exist in graph
      @visualizationGraphCanvas.removeVisibleRelationData relation.attributes
      # Add relation
      @visualizationGraphCanvas.addRelation relation.attributes

  onRelationsChangeType: (relation) ->
    console.log 'onRelationsChangeType', relation
    @visualizationGraphCanvas.updateRelationsLabelsData()

  onRelationsChangeDirection: (relation) ->
    @visualizationGraphCanvas.updateRelations()

  onRelationsRemove: (relation) ->
    @visualizationGraphCanvas.removeRelation relation.attributes
  
  # Canvas Events
  onNodeShowInfo: (e) ->
    console.log 'show info', e.node
    console.log 'show info model', @model
    @visualizationGraphCanvas.focusNode e.node
    @visualizationGraphInfo.show new Node(e.node), @model.get('custom_fields')

  onNodeHideInfo: (e) ->
    @visualizationGraphCanvas.unfocusNode()
    @visualizationGraphInfo.hide()

  # Config Panel Events
  onUpdateNodesColor: (e) ->
    @visualizationGraphCanvas.updateNodesColor e.value

  onUpdateNodesColorColumn: (e) ->
    # TODO!!! Add updateNodesColorColumn method in VisualizationGraphCanvas
    #@visualizationGraphCanvas.updateNodesColorColumn e.value

  onUpdateNodesSize: (e) ->
    @visualizationGraphCanvas.updateNodesSize e.value

  onToogleNodesLabel: (e) ->
    @visualizationGraphCanvas.toogleNodesLabel e.value

  onToogleNodesImage: (e) ->
    @visualizationGraphCanvas.toogleNodesImage e.value
  
  onToogleNodesWithoutRelation: (e) ->
    @visualizationGraphCanvas.toogleNodesWithoutRelation e.value

  onUpdateRelationsCurvature: (e) ->
    @visualizationGraphCanvas.updateRelationsCurvature e.value

  onUpdateRelationsLineStyle: (e) ->
    @visualizationGraphCanvas.updateRelationsLineStyle e.value

  onUpdateForceLayoutParam: (e) ->
    @visualizationGraphCanvas.updateForceLayoutParameter e.name, e.value

  # Navigation Events
  onZoomIn: (e) ->
    @visualizationGraphCanvas.zoomIn()
    
  onZoomOut: (e) ->
    @visualizationGraphCanvas.zoomOut()

  onFullscreen: (e) ->
    $('body').toggleClass 'fullscreen'
    @resize()

  updateGraphInfoNode: (node) ->
    if @visualizationGraphInfo.isVisible() and @visualizationGraphInfo.model.id == node.id
      #@visualizationGraphInfo.model = node
      #@visualizationGraphInfo.render()
      @visualizationGraphInfo.show node, @model.get('custom_fields')

  showChapter: (nodes, relations) ->
    # We use svg to check if visualizationGraphCanvas has data initialized
    if @visualizationGraphCanvas.svg
      # Update VisualizationGraphCanvas data
      @visualizationGraphCanvas.updateData nodes, relations
    else
      # Filter collection nodes & relations based on chapter nodes & relations
      collectionNodes     = @collection.nodes.models.filter     (d) => return nodes.indexOf(d.id) != -1
      collectionRelations = @collection.relations.models.filter (d) => return relations.indexOf(d.id) != -1  
      # Update VisualizationGraphCanvas data
      @visualizationGraphCanvas.setup @getDataFromCollection(collectionNodes, collectionRelations), @visualizationGraphConfiguration.parameters
      @visualizationGraphCanvas.setOffsetX 230 # translate left half the width of Story Info panel  
    # render VisualizationGraphCanvas
    @visualizationGraphCanvas.render()


module.exports = VisualizationGraph