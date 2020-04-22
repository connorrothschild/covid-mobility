var width = 960,
	height = 500,
	formatPercent = d3.format('.0%');

var margin = {
	top    : 40,
	right  : 40,
	bottom : 40,
	left   : 40
};

var rateById = {};
var countyById = {};
var stateById = {};
var csv = {};

var color = d3.scale
	.threshold()
	.domain([ -100, -50, -10, 0, 10, 50, 100 ])
	.range([ '#b2182b', '#d6604d', '#f4a582', '#fddbc7', '#d1e5f0', '#92c5de', '#4393c3', '#2166ac' ]);

var svg = d3
	.select('#map')
	.append('svg')
	.attr('width', width + margin.left + margin.right)
	.attr('height', height + margin.top + margin.bottom)
	.append('g')
	.attr('transform', 'translate(' + margin.left + ',' + margin.top + ')');

tooltip = d3.select('body').append('div').attr('class', 'tooltip').style('opacity', 0);

queue()
	.defer(
		d3.csv,
		'https://raw.githubusercontent.com/connorrothschild/covid-mobility/master/viz/data/mobility/county/with_without_stayathome.csv'
	)
	.defer(d3.json, 'us.json')
	.await(ready);

var legendText = [ '', '-100%', '', '', '0%', '', '', '+100%' ];
var legendColors = [ '#b2182b', '#d6604d', '#f4a582', '#fddbc7', '#d1e5f0', '#92c5de', '#4393c3', '#2166ac' ];

function dateFunction(date) {
	var formatTime = d3.time.format('%B %d, %Y');
	return formatTime(new Date(date));
}

function dateFunctionNoYear(date) {
	var formatTime = d3.time.format('%B %d');
	return formatTime(new Date(date));
}

function ready(error, data, us) {
	var counties = topojson.feature(us, us.objects.counties);

	csv = data;

	data = csv.filter(function(d) {
		return d.with_without == 'with';
	});

	data.forEach(function(d) {
		// d.seconds = +new Date(d.date);
		// d.date = dateFunction(d.date);
		d.fips = +d.fips;
		// d.pred = +d.pred;
		rateById[d.fips] = +d.pred;
		countyById[d.fips] = d.county + ', ' + d.State;
		// stateById[d.fips] = d.State;
	});

	console.log(rateById);
	console.log(data);

	var projection = d3.geo.albersUsa().translate([ width / 2, height / 2 ]);

	var path = d3.geo.path().projection(projection);

	console.log(counties.features);

	svg
		.selectAll('.county')
		.data(counties.features)
		.enter()
		.append('path')
		.attr('class', 'county')
		.attr('d', path)
		.style('stroke', 'grey')
		.style('stroke-width', 0.7);
	// .style('fill', 'grey')
	// .filter(function(d) {
	// 	return d.with_without == 'with';
	// })
	// .style('fill', function(d) {
	// 	if (!isNaN(rateById[d.id]) && rateById[d.id] !== 'undefined') {
	// 		return color(rateById[d.id]);
	// 	}
	// });

	svg
		.append('path')
		.datum(
			topojson.feature(us, us.objects.states, function(a, b) {
				return a !== b;
			})
		)
		.attr('class', 'states')
		.attr('d', path)
		.style('stroke', 'grey')
		.style('stroke-width', 0.7);

	var legend = svg.append('g').attr('id', 'legend');

	var legenditem = legend
		.selectAll('.legenditem')
		.data(d3.range(8))
		.enter()
		.append('g')
		.attr('class', 'legenditem')
		.attr('transform', function(d, i) {
			return 'translate(' + i * 31 + ',0)';
		});

	legenditem
		.append('rect')
		.attr('x', width - 240)
		.attr('y', -7)
		.attr('width', 30)
		.attr('height', 6)
		.attr('class', 'rect')
		.style('fill', function(d, i) {
			return legendColors[i];
		});

	legenditem.append('text').attr('x', width - 240).attr('y', -10).style('text-anchor', 'middle').text(function(d, i) {
		return legendText[i];
	});

	d3
		.selectAll('.county')
		.on('mouseover', function(d) {
			if (!isNaN(rateById[d.id])) {
				tooltip.transition().duration(250).style('opacity', 1);
				tooltip
					.html(
						'<p><strong>' +
							countyById[d.id] +
							'</strong>: ' +
							// d.State +
							'</strong></p>' +
							'<tr><td>Change in mobility without a stay-at-home order' +
							// dateFunctionNoYear(d.properties.seconds[second][0].seconds) +
							': </td><td><b>' +
							formatPercent(rateById[d.id] / 100) +
							'</b></td></tr>'
					)
					.style('left', d3.event.pageX + 15 + 'px')
					.style('top', d3.event.pageY - 28 + 'px');
			} else {
				tooltip.transition().duration(250).style('opacity', 1);
				tooltip
					.html('</td><td><b>' + 'No available data' + '</b></td></tr>')
					.style('left', d3.event.pageX + 15 + 'px')
					.style('top', d3.event.pageY - 28 + 'px');
			}
		})
		.on('mouseout', function(d) {
			tooltip.transition().duration(250).style('opacity', 0);
		});
}

function update() {
	d3.select('.withWithout').text('without');

	dataNew = csv.filter(function(d) {
		return d.with_without == 'without';
	});

	dataNew.forEach(function(d) {
		d.fips = +d.fips;
		rateById[d.fips] = +d.pred;
		countyById[d.fips] = d.county + ', ' + d.State;
	});

	console.log(dataNew);
	// console.log(counties);

	svg.selectAll('.county').transition().duration(1000).style('fill', function(d) {
		// if (!isNaN(rateById[d.fips])) {
		return color(rateById[d.id]);
		// }
	});

	d3
		.selectAll('.county')
		.on('mouseover', function(d) {
			if (!isNaN(rateById[d.id])) {
				tooltip.transition().duration(250).style('opacity', 1);
				tooltip
					.html(
						'<p><strong>' +
							countyById[d.id] +
							'</strong>: ' +
							// d.State +
							'</strong></p>' +
							'<tr><td>Change in mobility without a stay-at-home order' +
							// dateFunctionNoYear(d.properties.seconds[second][0].seconds) +
							': </td><td><b>' +
							formatPercent(rateById[d.id] / 100) +
							'</b></td></tr>'
					)
					.style('left', d3.event.pageX + 15 + 'px')
					.style('top', d3.event.pageY - 28 + 'px');
			} else {
				tooltip.transition().duration(250).style('opacity', 1);
				tooltip
					.html('</td><td><b>' + 'No available data' + '</b></td></tr>')
					.style('left', d3.event.pageX + 15 + 'px')
					.style('top', d3.event.pageY - 28 + 'px');
			}
		})
		.on('mouseout', function(d) {
			tooltip.transition().duration(250).style('opacity', 0);
		});
}

function redo() {
	d3.select('.withWithout').text('with');
	dataOld = csv.filter(function(d) {
		return d.with_without == 'with';
	});

	dataOld.forEach(function(d) {
		// d.seconds = +new Date(d.date);
		// d.date = dateFunction(d.date);
		d.fips = +d.fips;
		// d.pred = +d.pred;
		rateById[d.fips] = +d.pred;
		countyById[d.fips] = d.county + ', ' + d.State;
		// stateById[d.fips] = d.State;
	});

	console.log(dataOld);

	svg
		.selectAll('.county')
		.transition()
		.duration(1000) // .style('fill', 'grey')
		// .filter(function(d) {
		// 	return d.with_without == 'with';
		// })
		.style('fill', function(d) {
			if (!isNaN(rateById[d.id]) && rateById[d.id] !== 'undefined') {
				return color(rateById[d.id]);
			}
		});

	var legend = svg.append('g').attr('id', 'legend');

	var legenditem = legend
		.selectAll('.legenditem')
		.data(d3.range(8))
		.enter()
		.append('g')
		.attr('class', 'legenditem')
		.attr('transform', function(d, i) {
			return 'translate(' + i * 31 + ',0)';
		});

	legenditem
		.append('rect')
		.attr('x', width - 240)
		.attr('y', -7)
		.attr('width', 30)
		.attr('height', 6)
		.attr('class', 'rect')
		.style('fill', function(d, i) {
			return legendColors[i];
		});

	legenditem.append('text').attr('x', width - 240).attr('y', -10).style('text-anchor', 'middle').text(function(d, i) {
		return legendText[i];
	});

	d3
		.selectAll('.county')
		.on('mouseover', function(d) {
			if (!isNaN(rateById[d.id])) {
				tooltip.transition().duration(250).style('opacity', 1);
				tooltip
					.html(
						'<p><strong>' +
							countyById[d.id] +
							'</strong>: ' +
							// d.State +
							'</strong></p>' +
							'<tr><td>Change in mobility with a stay-at-home order' +
							// dateFunctionNoYear(d.properties.seconds[second][0].seconds) +
							': </td><td><b>' +
							formatPercent(rateById[d.id] / 100) +
							'</b></td></tr>'
					)
					.style('left', d3.event.pageX + 15 + 'px')
					.style('top', d3.event.pageY - 28 + 'px');
			} else {
				tooltip.transition().duration(250).style('opacity', 1);
				tooltip
					.html('</td><td><b>' + 'No available data' + '</b></td></tr>')
					.style('left', d3.event.pageX + 15 + 'px')
					.style('top', d3.event.pageY - 28 + 'px');
			}
		})
		.on('mouseout', function(d) {
			tooltip.transition().duration(250).style('opacity', 0);
		});
}

d3.select(window).on('load', redo);
