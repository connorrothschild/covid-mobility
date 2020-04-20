var width = 960,
	height = 500,
	formatPercent = d3.format('.0%');

var margin = {
	top    : 40,
	right  : 40,
	bottom : 40,
	left   : 40
};

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
		'https://raw.githubusercontent.com/connorrothschild/covid-mobility/master/viz/data/archived/county-data-long-cleaned-averages.csv'
	)
	.defer(d3.json, 'us.json')
	.await(ready);

var legendText = [ '', '-50%', '', '', '0%', '', '', '+50%' ];
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

	data.forEach(function(d) {
		d.seconds = +new Date(d.date);
		d.date = dateFunction(d.date);
		d.fips = +d.fips;
		d.value = +d.value;
		d.county = d.Region;
	});

	// console.log(data);

	var dataByCountyByYear = d3
		.nest()
		.key(function(d) {
			return d.fips;
		})
		.key(function(d) {
			return d.seconds;
		})
		.map(data);

	counties.features.forEach(function(county) {
		county.properties.seconds = dataByCountyByYear[+county.id];
	});

	// console.log(counties);

	// var color = d3.scaleSequential(d3.interpolateSpectral).domain([ -50, 50 ]);
	var color = d3.scale
		.threshold()
		.domain([ -50, -25, -10, 0, 10, 25, 50 ])
		.range([ '#b2182b', '#d6604d', '#f4a582', '#fddbc7', '#d1e5f0', '#92c5de', '#4393c3', '#2166ac' ]);

	var projection = d3.geo.albersUsa().translate([ width / 2, height / 2 ]);

	var path = d3.geo.path().projection(projection);

	var countyShapes = svg
		.selectAll('.county')
		.data(counties.features)
		.enter()
		.append('path')
		.attr('class', 'county')
		.attr('d', path)
		.style('fill', 'grey');

	svg
		.append('path')
		.datum(
			topojson.feature(us, us.objects.states, function(a, b) {
				return a !== b;
			})
		)
		.attr('class', 'states')
		.attr('d', path);

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

	function update(second) {
		slider.property('value', second);
		// console.log(second);
		d3.select('.date').text(dateFunctionNoYear(second));
		// console.log(dateFunctionNoYear(second));
		countyShapes.style('fill', function(d) {
			if (d.properties.seconds !== undefined && !isNaN(d.properties.seconds[second][0].value)) {
				return color(d.properties.seconds[second][0].value);
			}
		});

		countyShapes
			.on('mouseover', function(d) {
				if (d.properties.seconds !== undefined && !isNaN(d.properties.seconds[second][0].value)) {
					tooltip.transition().duration(250).style('opacity', 1);
					tooltip
						.html(
							'<p><strong>' +
								d.properties.seconds[second][0].county +
								'</strong>, ' +
								d.properties.seconds[second][0].State +
								'</strong></p>' +
								'<tr><td>Change in mobility on ' +
								dateFunctionNoYear(d.properties.seconds[second][0].seconds) +
								': </td><td><b>' +
								formatPercent(d.properties.seconds[second][0].value / 100) +
								'</b></td></tr>'
						)
						.style('left', d3.event.pageX + 15 + 'px')
						.style('top', d3.event.pageY - 28 + 'px');
				}
			})
			.on('mouseout', function(d) {
				tooltip.transition().duration(250).style('opacity', 0);
			});
	}

	var slider = d3
		.select('.slider')
		.append('input')
		.attr('type', 'range')
		.attr('min', +new Date('2020-02-16'))
		.attr('max', +new Date('2020-03-29'))
		.attr('step', 1000 * 60 * 60 * 24)
		.on('input', function() {
			var second = +this.value;
			update(second);
		});

	update(+new Date('2020-02-16'));
}
