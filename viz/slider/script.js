var svg = d3
	.select('svg')
	.attr('class', 'plot')
	.attr('height', 600)
	.attr('width', 960)
	// resize plot when window is resized (see below)
	.call(responsivefy);

var path = d3.geoPath();
var format = d3.format('');
var height = 600;
var width = 960;

var margin = {
	top    : 40,
	right  : 40,
	bottom : 40,
	left   : 40
};

// thanks to https://brendansudol.com/writing/responsive-d3 for this function!
function responsivefy(svg) {
	// container will be the DOM element
	// that the svg is appended to
	// we then measure the container
	// and find its aspect ratio
	const container = d3.select(svg.node().parentNode),
		width = parseInt(svg.style('width'), 10),
		height = parseInt(svg.style('height'), 10),
		aspect = width / height;

	// set viewBox attribute to the initial size
	// control scaling with preserveAspectRatio
	// resize svg on inital page load
	svg.attr('viewBox', `0 0 ${width} ${height}`).attr('preserveAspectRatio', 'xMinYMid').call(resize);

	// add a listener so the chart will be resized
	// when the window resizes
	// multiple listeners for the same event type
	// requires a namespace, i.e., 'click.foo'
	// api docs: https://goo.gl/F3ZCFr
	d3.select(window).on('resize.' + container.attr('id'), resize);

	// this is the code that resizes the chart
	// it will be called on load
	// and in response to window resizes
	// gets the width of the container
	// and resizes the svg to fill it
	// while maintaining a consistent aspect ratio
	function resize() {
		const w = parseInt(container.style('width'));
		svg.attr('width', w);
		svg.attr('height', Math.round(w / aspect));
	}
}

function dateFunction(date) {
	var formatTime = d3.timeFormat('%B %d, %Y');
	return formatTime(new Date(date));
}

function dateFunctionNoYear(date) {
	var formatTime = d3.timeFormat('%B %d');
	return formatTime(new Date(date));
}

var formatDateIntoYear = d3.timeFormat('%Y');
var formatDate = d3.timeFormat('%b %Y');
var parseDate = d3.timeParse('%m/%d/%y');

var startDate = new Date('2020-02-16'),
	endDate = new Date('2017-04-01');

var moving = false;
var currentValue = 0;
var targetValue = width - 100;

var playButton = d3.select('#play-button');

var x = d3.scaleTime().domain([ new Date('2020-02-16'), new Date('2020-03-29') ]).range([ 0, targetValue ]).clamp(true);

var slider = svg
	.append('g')
	.attr('class', 'slider')
	.attr('transform', 'translate(' + margin.left + ',' + height / 10 + ')');

slider
	.append('line')
	.attr('class', 'track')
	.attr('x1', x.range()[0])
	.attr('x2', x.range()[1])
	.select(function() {
		return this.parentNode.appendChild(this.cloneNode(true));
	})
	.attr('class', 'track-inset')
	.select(function() {
		return this.parentNode.appendChild(this.cloneNode(true));
	})
	.attr('class', 'track-overlay')
	.call(
		d3
			.drag()
			.on('start.interrupt', function() {
				slider.interrupt();
			})
			.on('start drag', function() {
				currentValue = d3.event.x;
				update(x.invert(currentValue));
			})
	);

slider
	.insert('g', '.track-overlay')
	.attr('class', 'ticks')
	.attr('transform', 'translate(0,' + 18 + ')')
	.selectAll('text')
	.data(x.ticks(10))
	.enter()
	.append('text')
	.attr('x', x)
	.attr('y', 10)
	.attr('text-anchor', 'middle')
	.text(function(d) {
		return formatDate(d);
	});

var handle = slider.insert('circle', '.track-overlay').attr('class', 'handle').attr('r', 9);

var label = slider
	.append('text')
	.attr('class', 'label')
	.attr('text-anchor', 'middle')
	.text(dateFunctionNoYear(startDate))
	.attr('transform', 'translate(0,' + -25 + ')');

function increaseOrDecrease(value) {
	if (value > 0) {
		return 'increase';
	} else {
		return 'decrease';
	}
}

// var radius = d3.scaleSqrt().domain([ -50, 50 ]).range([ 0, 25 ]);

// // label positions
// labely = height - 50;
// labelx = width - 280;

// // Add the year label; the value is set on transition.
// var label = svg
// 	.append('text')
// 	.attr('class', 'year label')
// 	.attr('text-anchor', 'middle')
// 	// position the label
// 	.attr('y', labely)
// 	.attr('x', labelx)
// 	.text(dateFunction('2020-02-16'));

// var helperlabel = svg
// 	.append('text')
// 	.attr('class', 'helper label')
// 	.attr('text-anchor', 'middle')
// 	// position the label
// 	.attr('y', labely + 20)
// 	.attr('x', labelx)
// 	.text('Hover to change date');

queue()
	.defer(d3.json, 'https://d3js.org/us-10m.v1.json')
	.defer(
		d3.csv,
		'https://raw.githubusercontent.com/connorrothschild/covid-mobility/master/data/county-data-long-averages.csv'
	)
	.await(ready);

var dataset;

function ready(error, us, data) {
	if (error) throw error;

	var rateById = {},
		nameById = {};

	data.forEach(function(d) {
		d.value = +d.value;
		d.fips = d.fips;
		rateById[d.fips] = +d.value;
		nameById[d.fips] = d.Region;
		stateById = d.State;
		d.date = dateFunction(d.date);
	});

	console.log(data);
	dataset = data;
	drawPlot(dataset);

	// data = data.filter(
	// 	(d = (d) => {
	// 		return d.Category == 'Transit stations';
	// 	})
	// );

	// data = data.filter(
	// 	(d = (d) => {
	// 		return d.date == '2020-03-29';
	// 	})
	// );

	playButton.on('click', function() {
		var button = d3.select(this);
		if (button.text() == 'Pause') {
			moving = false;
			clearInterval(timer);
			// timer = 0;
			button.text('Play');
		} else {
			moving = true;
			timer = setInterval(step, 100);
			button.text('Pause');
		}
		console.log('Slider moving: ' + moving);
	});

	function step() {
		update(x.invert(currentValue));
		currentValue = currentValue + targetValue / 100;
		if (currentValue > targetValue) {
			moving = false;
			currentValue = 0;
			clearInterval(timer);
			// timer = 0;
			playButton.text('Play');
			console.log('Slider moving: ' + moving);
		}
	}

	var color = d3.scaleSequential(d3.interpolateSpectral).domain([ -50, 50 ]);

	// https://blockbuilder.org/curran/3094b37e63b918bab0a06787e161607b
	// Add a legend for the color values.
	var legend = svg
		.selectAll('.legend')
		.data(color.ticks(8))
		.enter()
		.append('g')
		.attr('class', 'legend')
		.attr('transform', function(d, i) {
			return 'translate(' + (width - 325 + i * 20) + ',' + 70 + ')';
		});

	legend.append('rect').attr('width', 20).attr('height', 20).style('fill', color);

	legend
		.append('text')
		.attr('class', 'legend-labels')
		.attr('x', 0)
		.attr('y', 33) // .attr('dx', '.35em')
		.text(function(d, i) {
			if (i == 0 || i == 10 || i == 5) {
				return d;
			} else {
				return null;
			}
		});

	d3.select('.legend').append('text').attr('x', 0).attr('y', -12).attr('dx', '1.5em').text('% Change in mobility');

	// var box = label.node().getBBox();

	// var overlay = svg
	// 	.append('rect')
	// 	.attr('class', 'overlay')
	// 	.attr('x', box.x)
	// 	.attr('y', box.y)
	// 	.attr('width', box.width)
	// 	.attr('height', box.height);
	// .on('mouseover', enableInteraction);

	// svg.transition().duration(5000).ease(d3.easeLinear).tween('date', tweenDate);

	function drawPlot(data) {
		color = d3.scaleSequential(d3.interpolateSpectral).domain([ -50, 50 ]);

		var tool_tip = d3
			.tip()
			.attr('class', 'd3-tip')
			// if the mouse position is greater than 650 (~ Kentucky/Missouri),
			// offset tooltip to the left instead of the right
			// credit https://stackoverflow.com/questions/28536367/in-d3-js-how-to-adjust-tooltip-up-and-down-based-on-the-screen-position
			.offset(function() {
				if (current_position[0] > 650) {
					return [ -30, -240 ];
				} else {
					return [ 5, 30 ];
				}
			})
			.html("<div id='tipDiv'></div>");

		svg.call(tool_tip);

		currentDate = '02-16-20';

		counties = svg
			.append('g')
			.attr('class', 'counties')
			.selectAll('path')
			.data(topojson.feature(us, us.objects.counties).features)
			.enter()
			.append('path')
			.attr('d', path)
			.attr('stroke', 'grey')
			.attr('stroke-width', 0.1)
			.call(style, currentDate)
			// .style('fill', function(d) {
			// 	if (!isNaN(rateById[d.id])) {
			// 		return color(rateById[d.id]);
			// 	} else {
			// 		return 'white';
			// 	}
			// })
			// appending svg inside of tooltip for year by year change.
			// h/t https://bl.ocks.org/maelafifi/ee7fecf90bb5060d5f9a7551271f4397
			// h/t https://stackoverflow.com/questions/43904643/add-chart-to-tooltip-in-d3
			.on('mouseover', function(d) {
				// define and store the mouse position. this is used to define
				// tooltip offset, seen above.
				current_position = d3.mouse(this);
				// console.log(current_position[0]);

				current_county = nameById[d.id];
				current_state = stateById;

				tool_tip.show();
				var tipSVG = d3.select('#tipDiv').append('svg').attr('width', 220).attr('height', 55);

				// tipSVG
				// 	.append('circle')
				// 	.attr('fill', function() {
				// 		return color(rateById[d.id]);
				// 	})
				// 	.attr('stroke', 'black')
				// 	.attr('cx', 180)
				// 	.attr('cy', 30)
				// 	.attr('r', function() {
				// 		return radius(rateById[d.id]);
				// 	});

				tipSVG
					.append('text')
					.text(function() {
						if (current_county == undefined) {
							return '';
						} else if (isNaN(rateById[d.id])) {
							return '';
						} else {
							return (
								Math.round(rateById[d.id]) +
								'% ' +
								increaseOrDecrease(rateById[d.id]) +
								' from baseline'
							);
						}
					}) // .transition()
					// .duration(1000)
					.attr('x', 0)
					.attr('y', 55);

				tipSVG
					.append('text')
					.attr('class', 'county-name')
					.text(function() {
						if (current_county == undefined) {
							return 'No available data';
						} else {
							return current_county;
						}
					})
					// .transition()
					// .duration(1000)
					.attr('x', 0)
					.attr('y', 18);

				tipSVG
					.append('text')
					.attr('class', 'state-name')
					.text(function() {
						if (current_county == undefined) {
							return '';
						} else {
							return current_state;
						}
					})
					// .transition()
					// .duration(1000)
					.attr('x', 0)
					.attr('y', 35);
			})
			.on('mouseout', tool_tip.hide)
			.call(style, currentDate);
	}

	function update(h) {
		// update position and text of label according to slider scale
		handle.attr('cx', x(h));
		label.attr('x', x(h)).text(dateFunctionNoYear(h));
		console.log(h);

		var newData = dataset.filter(function(d, h) {
			return d.date == dateFunction(h);
		});

		console.log(newData);
		// drawPlot(newData);

		// counties
		// 	.enter()
		// 	.data(newData)
		// 	.append('path')
		// 	.attr('d', path)
		// 	.attr('stroke', 'grey')
		// 	.attr('stroke-width', 0.1)
		// 	.style('fill', function(d) {
		// 		if (!isNaN(rateById[d.id])) {
		// 			return color(rateById[d.id]);
		// 		} else {
		// 			return 'white';
		// 		}
		// 	});
	}

	// counties.style('fill', function(d) {
	// 	if (rateById[d.id] !== null) {
	// 		return color(rateById[d.id]);
	// 	} else {
	// 		return '#FFFFFF';
	// 	}
	// });

	// // create nation
	// svg
	// 	.append('path')
	// 	.datum(topojson.feature(us, us.objects.nation))
	// 	.attr('class', 'land')
	// 	.attr('d', path)
	// 	.attr('fill', 'none')
	// 	.attr('stroke', 'grey')
	// 	.attr('stroke-width', 0.2);

	// // create the actual state objects
	// svg
	// 	.append('path')
	// 	.datum(topojson.mesh(us, us.objects.states, (a, b) => a !== b))
	// 	.attr('fill', 'none')
	// 	.attr('stroke', 'grey')
	// 	.attr('stroke-width', 0.15)
	// 	.attr('stroke-linejoin', 'round')
	// 	.attr('d', path);

	function style(counties, date) {
		newdata = interpolateData(date);

		console.log(date);

		var rateById = {};
		var nameById = {};

		newdata.forEach(function(d) {
			d.value = +d.value;
			d.fips = d.fips;
			rateById[d.fips] = +d.value;
			nameById[d.fips] = d.Region;
			stateById = d.State;
			d.date = parseDate(d.date);
		});

		console.log(newdata);

		counties.style('fill', function(d) {
			if (!isNaN(rateById[d.id])) {
				return color(rateById[d.id]);
			} else {
				return 'white';
			}
		});

		// create nation
		svg
			.append('path')
			.datum(topojson.feature(us, us.objects.nation))
			.attr('class', 'land')
			.attr('d', path)
			.attr('fill', 'none')
			.attr('stroke', 'grey')
			.attr('stroke-width', 0.2);

		// create the actual state objects
		svg
			.append('path')
			.datum(topojson.mesh(us, us.objects.states, (a, b) => a !== b))
			.attr('fill', 'none')
			.attr('stroke', 'grey')
			.attr('stroke-width', 0.15)
			.attr('stroke-linejoin', 'round')
			.attr('d', path);
	}

	// // after the transition finishes, mouseover to change  year.
	// function enableInteraction() {
	// 	var dateScale = d3
	// 		.scaleLinear()
	// 		.domain(
	// 			d3.extent(data, function(d) {
	// 				return new Date(d.date);
	// 			})
	// 		)
	// 		.range([ box.x + 10, box.x + box.width - 10 ])
	// 		.clamp(true);

	// 	// Cancel the current transition, if any.
	// 	svg.transition().duration(0);

	// 	overlay
	// 		.on('mouseover', mouseover)
	// 		.on('mouseout', mouseout)
	// 		.on('mousemove', mousemove)
	// 		.on('touchmove', mousemove);

	// 	function mouseover() {
	// 		label.classed('active', true);
	// 	}
	// 	function mouseout() {
	// 		label.classed('active', false);
	// 	}
	// 	function mousemove() {
	// 		displayDate(dateScale.invert(d3.mouse(this)[0]));
	// 	}
	// }

	// Tweens the entire chart by first tweening the year, and then the data.
	// For the interpolated data, the dots and label are redrawn.
	function tweenDate() {
		var date = d3.interpolate(new Date('2020-02-16'), new Date('2020-03-29'));
		return function(t) {
			displayDate(date(t));
		};
	}

	// Updates the display to show the specified year.
	function displayDate(date) {
		currentDate = date;
		counties.call(style, date);
		label.text(dateFunctionNoYear(date));
	}

	// // Interpolates the dataset for the given (fractional) year.
	function interpolateData(date) {
		// currentDate = date;

		return data.filter(function(row) {
			return row['date'] == dateFunction(date);
			// return new Date(row.date) === new Date(date);
		});
	}
}
