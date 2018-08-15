
class BubbleChart
  constructor: (data) ->
    @data = data
    @width = 940
    @height = 600

    @tooltip = CustomTooltip("gates_tooltip", 240)

    # locations the nodes will move towards
    # depending on which view is currently being
    # used
    @center = {x: @width / 2, y: @height / 2}
    @algorithm_centers = {
      "Logistic Regression": {x: 180, y: @height / 2},
      "Naive Bayes": {x: 400, y: @height / 2},
      "Random Forest": {x: 600, y: @height / 2},
      "XGBoost": {x: @width-180 , y: @height / 2}
    }
    
    
    # used when setting up force and
    # moving around nodes
    @layout_gravity = -0.01
    @damper = 0.1

    # these will be set in create_nodes and create_vis
    @vis = null
    @nodes = []
    @force = null
    @circles = null

    # nice looking colors - no reason to buck the trend
    @fill_color = d3.scale.ordinal()
      .domain(["Wrong", "Correct"])
      .range(["#fc8d59", "#7fcdbb"])

    
    this.create_nodes()
    this.create_vis()

  # create node objects from original data
  # that will serve as the data behind each
  # bubble in the vis, then add each node
  # to @nodes to be used later
  create_nodes: () =>
    @data.forEach (d) =>
      node = {
        id: d.id_MODEL
        radius: 5
        value: d.count_MODEL
        group_MODEL: d.group_MODEL
        algorithm: d.algorithm_MODEL
        f1scores: d.Accuracy_MODEL
        x: Math.random() * 900
        y: Math.random() * 800
      }
      @nodes.push node

    @nodes.sort (a,b) -> b.value - a.value


  # create svg at #vis and then 
  # create circle representation for each node
  create_vis: () =>
    @vis = d3.select("#vis").append("svg")
      .attr("width", @width)
      .attr("height", @height)
      .attr("id", "svg_vis")

    @circles = @vis.selectAll("circle")
      .data(@nodes, (d) -> d.id_MODEL)

    # used because we need 'this' in the 
    # mouse callbacks
    that = this

    # radius will be set to 0 initially.
    # see transition below
    @circles.enter().append("circle")
      .attr("r", 0)
      .attr("fill", (d) => @fill_color(d.group_MODEL))
      .attr("stroke-width", 2)
      .attr("stroke", (d) => d3.rgb(@fill_color(d.group_MODEL)).darker())


    # Fancy transition to make bubbles appear, ending with the
    # correct radius
    @circles.transition().duration(2000).attr("r", (d) -> d.radius)


  # Charge function that is called for each node.
  # Charge is proportional to the diameter of the
  # circle (which is stored in the radius attribute
  # of the circle's associated data.
  # This is done to allow for accurate collision 
  # detection with nodes of different sizes.
  # Charge is negative because we want nodes to 
  # repel.
  # Dividing by 8 scales down the charge to be
  # appropriate for the visualization dimensions.
  charge: (d) ->
    -Math.pow(d.radius, 2.0) / 8

  # Starts up the force layout with
  # the default values
  start: () =>
    @force = d3.layout.force()
      .nodes(@nodes)
      .size([@width, @height])

  # Sets up force layout to display
  # all nodes in one circle.
  display_group_MODEL_all: () =>
    @force.gravity(@layout_gravity)
      .charge(this.charge)
      .friction(0.9)
      .on "tick", (e) =>
        @circles.each(this.move_towards_center(e.alpha))
          .attr("cx", (d) -> d.x)
          .attr("cy", (d) -> d.y)
    @force.start()

    this.hide_algorithms()
    this.hide_f1scores()

  # Moves all circles towards the @center
  # of the visualization
  move_towards_center: (alpha) =>
    (d) =>
      d.x = d.x + (@center.x - d.x) * (@damper + 0.02) * alpha
      d.y = d.y + (@center.y - d.y) * (@damper + 0.02) * alpha

  # sets the display of bubbles to be separated
  # into each algorithm. Does this by calling move_towards_algorithm
  display_by_algorithm: () =>
    @force.gravity(@layout_gravity)
      .charge(this.charge)
      .friction(0.9)
      .on "tick", (e) =>
        @circles.each(this.move_towards_algorithm(e.alpha))
          .attr("cx", (d) -> d.x)
          .attr("cy", (d) -> d.y)
    @force.start()

    this.display_algorithms()
    this.display_f1scores()


  # move all circles to their associated @algorithm_centers 
  move_towards_algorithm: (alpha) =>
    (d) =>
      target = @algorithm_centers[d.algorithm]
      d.x = d.x + (target.x - d.x) * (@damper + 0.02) * alpha * 1.1
      d.y = d.y + (target.y - d.y) * (@damper + 0.02) * alpha * 1.1


  # Method to display algorithm titles
  display_algorithms: () =>
    algorithms_x = {"Logistic Regression": 100, "Naive Bayes": 380, "Random Forest": 620, "XGBoost": @width- 90}
    algorithms_data = d3.keys(algorithms_x)
    algorithms = @vis.selectAll(".algorithms")
      .data(algorithms_data)

    algorithms.enter().append("text")
      .attr("class", "algorithms")
      .attr("x", (d) => algorithms_x[d] )
      .attr("y", 80)
      .attr("text-anchor", "middle")
      .attr("font-size", 20)
      .attr("fill", "grey")
      .text((d) -> d)

  # Method to display f1 scores
  display_f1scores: () =>
    f1scores_x = {"F1 Score: 67%": 100, "F1 Score: 69%": 380, "F1 Score: 68%": 620, "F1 Score: 90%": @width- 90}
    f1scores_data = d3.keys(f1scores_x)
    f1scores = @vis.selectAll(".f1scores")
      .data(f1scores_data)

    f1scores.enter().append("text")
      .attr("class", "f1scores")
      .attr("x", (d) => f1scores_x[d] )
      .attr("y", 130)
      .attr("font-size", 13)
      .attr("text-anchor", "middle")
      .text((d) -> d)


  # Method to hide algorithm titiles
  hide_algorithms: () =>
    algorithms = @vis.selectAll(".algorithms").remove()
    
  # Method to hide algorithm titiles
  hide_f1scores: () =>
    f1scores = @vis.selectAll(".f1scores").remove()





root = exports ? this

$ ->
  chart = null

  render_vis = (csv) ->
    chart = new BubbleChart csv
    chart.start()
    root.display_all()
  root.display_all = () =>
    chart.display_group_MODEL_all()
  root.display_algorithm = () =>
 	 chart.display_by_algorithm()
  root.toggle_view = (view_type) =>
    if view_type == 'algorithm'
      root.display_algorithm()
      root.display_f1scores()
    else
      root.display_all()

  d3.csv "data/Model.csv", render_vis
