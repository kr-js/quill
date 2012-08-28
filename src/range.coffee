#= underscore
#= require rangy/rangy-core


class TandemRange
  @getSelection: (editor) ->
    rangySelection = rangy.getSelection(editor.iframe.contentWindow)
    return null unless rangySelection.anchorNode? && rangySelection.focusNode?
    if !rangySelection.isBackwards()
      start = new Tandem.Position(editor, rangySelection.anchorNode, rangySelection.anchorOffset)
      end = new Tandem.Position(editor, rangySelection.focusNode, rangySelection.focusOffset)
    else
      start = new Tandem.Position(editor, rangySelection.focusNode, rangySelection.focusOffset)
      end = new Tandem.Position(editor, rangySelection.anchorNode, rangySelection.anchorOffset)
    return new TandemRange(editor, start, end)

  # constructor: (TandemEditor editor, Number startIndex, Number endIndex) ->
  # constructor: (TandemEditor editor, Object start, Object end) ->
  constructor: (@editor, @start, @end) ->
    # TODO initialize with index
    @start = new Tandem.Position(@editor, @start) if _.isNumber(@start)
    @end = new Tandem.Position(@editor, @end) if _.isNumber(@end)

  equals: (range) ->
    return false if range == null
    return range.start.leaf == @start.leaf && range.end.leaf == @end.leaf && range.start.offset == @start.offset && range.end.offset == @end.offset
      
  getAttributeIntersection: ->
    attributes = null
    _.all(this.getLeafPositions(), (position) ->
      leafAttributes = Tandem.Utils.Node.getAttributes(position.leaf.node)
      if attributes
        _.each(attributes, (value, key) ->
          if leafAttributes[key] != true
            delete attributes[key]
        )
      else
        attributes = leafAttributes

      for key,value of attributes when value == true
        return true
      return false
    )
    return attributes || {}

  getRangy: ->
    range = rangy.createRangyRange(@editor.iframe.contentWindow)
    range.setStart(@start.leaf.node.firstChild, @start.offset)
    range.setEnd(@end.leaf.node.firstChild, @end.offset)
    return range

  getLeafNodes: ->
    range = this.getRangy()
    if range.collapsed
      return [@start.leaf.node]
    else
      nodes = _.map(range.getNodes([3]), (node) -> 
        return node.parentNode
      )
      nodes.pop() if nodes[nodes.length - 1] != @end.leaf.node || @end.offset == 0
      return nodes

  getLeafPositions: ->
    return _.map(this.getLeafNodes(), (node) =>
      return new Tandem.Position(@editor, node, 0)
    )

  groupNodesByLine: ->
    currentLine = 0
    return _.reduce(this.getLeafPositions(), (lines, position) ->
      line = Tandem.Utils.Node.getLine(position.leaf.node)
      if currentLine == line
        lines[lines.length - 1].push(position.leaf.node)
      else
        lines.push([position.leaf.node])
        currentLine = line
      return lines
    , [])

  isCollapsed: ->
    return @start.leaf == @end.leaf && @start.offset == @end.offset


window.Tandem ||= {}
window.Tandem.Range = TandemRange
