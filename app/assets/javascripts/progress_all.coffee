class Progress

	constructor: () ->
		$("#map-tutorial").hide()
		$("#map-about").hide()
		$("#tweet").hide()
		@ids = []
		NW = new L.LatLng(40.65563874006115,-74.13093566894531)
		SE = new L.LatLng(40.81640757520087,-73.83087158203125)
		@map = L.mapbox.map('map', 'https://s3.amazonaws.com/maptiles.nypl.org/859-final/859spec.json', 
			zoomControl: false
			animate: true
			scrollWheelZoom: true
			attributionControl: true
			minZoom: 12
			maxZoom: 20
			dragging: true
			maxBounds: new L.LatLngBounds(NW, SE)
		)

		L.control.zoom(
			position: 'topright'
		).addTo(@map)

		# @map.on('load', @getPolygons)
		@no_color = '#AF2228'
		@yes_color = '#609846'
		@fix_color = '#FFB92D'
		@nil_color = '#AAAAAA'

		@addEventListeners()

		@resetSheet()

		L.InspectorMarker = L.Marker.extend
			options:
				polygon_count: 0
				sheet_id: 0
				bounds: []

		window.map = @

	addEventListeners: () =>
		p = @

		@map.on('load', @getCounts)

	resetSheet: () ->
		@map.removeLayer @sheet if @map.hasLayer @sheet
		@sheet = L.geoJson({features:[]},
			style: (feature) ->
				color: @nil_color
				opacity: 0
				fillOpacity: 0.5
				stroke: false
		).addTo @map

	getCounts: () =>
		data = $('#progressjs').data("progress")

		@updateScore(data.all_polygons_session)

		# marker clustering layer
		markers = new L.MarkerClusterGroup
			singleMarkerMode: true
			disableClusteringAtZoom: 19
			iconCreateFunction: (c) ->
				count = 0
				for child in c.getAllChildMarkers()
					count = count + parseInt(child.options.polygon_count)
				c = 'cluster-large'
				if count < 10
					c = 'cluster-small'
				else if count < 30
					c = 'cluster-medium'
				new L.DivIcon
					html: count
					className: c
					iconSize: L.point(30, 30)
			polygonOptions:
				stroke: false
		
		p = @

		markers.on("click", (e) ->
			console.log "click:", e.layer
			p.resetSheet()
			p.getPolygons(e.layer.options.sheet_id)
		)

		markers.on("clusterclick", (e) ->
			p.resetSheet()
		)

		counts = data.counts
		@addMarker markers, count for count in counts

		markers.addTo @map
		@

	addMarker: (markers, data) ->
		# console.log data

		bbox = data.bbox.split ","
		
		W = parseFloat(bbox[0])
		S = parseFloat(bbox[1])
		E = parseFloat(bbox[2])
		N = parseFloat(bbox[3])

		SW = new L.LatLng(S, W)
		NW = new L.LatLng(N, W)
		NE = new L.LatLng(N, E)
		SE = new L.LatLng(S, E)

		bounds = new L.LatLngBounds(SW, NE)
		latlng = bounds.getCenter()

		markers.addLayer new L.InspectorMarker latlng,
			polygon_count: data.polygon_count
			sheet_id: data.sheet_id
			bounds: bounds
		@

	getPolygons: (sheet_id) ->
		v = @
		$.getJSON('/viz/sheet/' + sheet_id + '.json', (data) ->
			console.log data
			v.processPolygons(data)
		)

	processPolygons: (data) ->
		return if data.polygons.length==0

		m = @map

		for polygon in data.polygons
			json = 
				type : "Feature"
				properties:
					id: polygon.id
				geometry:
					type: "Polygon"
					coordinates: $.parseJSON(polygon.geometry)

			@sheet.addData json

		@map.fitBounds(@sheet.getBounds())

	updateScore: (current) =>
		# mapScore = if total > 0 then Math.round(current*100/total) else 0

		# mapDOM = $("#map-bar")
		# mapDOM.find(".bar").css("width", mapScore + "%")
		$("#score .total").text(current)
		# $("#map-total").text("of " + total.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",") + " shapes")

		url = $('#progressjs').data("server")
		tweet = current + " buildings checked! Data mining old maps with the Building Inspector from @NYPLMaps @nypl_labs"
		twitterurl = "https://twitter.com/share?url=" + url + "&text=" + tweet

		$("#tweet").show()

		$("#tweet").attr "href", twitterurl


$ ->
	window._progress = new Progress()