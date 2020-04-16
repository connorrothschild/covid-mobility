let dimensions = {
	width  : window.innerWidth * 0.8,
	height : 400,
	margin : {
		top    : 15,
		right  : 15,
		bottom : 65,
		left   : 60
	}
};
dimensions.boundedWidth = dimensions.width - dimensions.margin.left - dimensions.margin.right;
dimensions.boundedHeight = dimensions.height - dimensions.margin.top - dimensions.margin.bottom;

d3
	.csv(
		'https://raw.githubusercontent.com/connorrothschild/covid-mobility/0d778130fdd1beba1a250664948b8e93780f84dd/data/mobility/county/county-names.csv'
	)
	.row(function(d) {
		return d.county_state;
	})
	.get(function(rows) {
		d3
			.select('datalist')
			.selectAll('option')
			.data(rows) // performing a data join
			.enter() // extracting the entering selection
			.append('option') // adding an option to the selection of options
			.attr('value', function(d) {
				return d;
			});
	});

function responsivefy(svg) {
	// get container + svg aspect ratio
	var container = d3.select(svg.node().parentNode),
		width = parseInt(svg.style('width')),
		height = parseInt(svg.style('height')),
		aspect = width / height;

	// add viewBox and preserveAspectRatio properties,
	// and call resize so that svg resizes on inital page load
	svg.attr('viewBox', '0 0 ' + width + ' ' + height).attr('perserveAspectRatio', 'xMinYMid').call(resize);

	// to register multiple listeners for same event type,
	// you need to add namespace, i.e., 'click.foo'
	// necessary if you call invoke this function for multiple svgs
	// api docs: https://github.com/mbostock/d3/wiki/Selections#on
	d3.select(window).on('resize.' + container.attr('id'), resize);

	// get width of container and resize svg to fit it
	function resize() {
		var targetWidth = parseInt(container.style('width'));
		svg.attr('width', targetWidth);
		svg.attr('height', Math.round(targetWidth / aspect));
	}
}

const svg = d3.select('#my_dataviz').append('svg').attr('width', dimensions.width).attr('height', dimensions.height);
// .call(responsivefy);

const bounds = svg.append('g').attr('transform', `translate(${dimensions.margin.left}, ${dimensions.margin.top})`);
// .call(responsivefy);

bounds
	.append('defs')
	.append('clipPath')
	.attr('id', 'bounds-clip-path')
	.append('rect')
	.attr('width', dimensions.boundedWidth)
	.attr('height', dimensions.boundedHeight);
// .call(responsivefy);

const clip = bounds.append('g').attr('clip-path', 'url(#bounds-clip-path)');

var csv;

var selected_county = 'Harris County';
var selected_state = 'Texas';
var selected_category = 'Workplace';

//Read the data
d3.csv(
	'https://raw.githubusercontent.com/connorrothschild/covid-mobility/master/data/archived/county-data-long-cleaned.csv',
	function(data) {
		data.forEach(function(d) {
			d.date = d.date;
			d.value = +d.value;
		});

		csv = data;

		data = csv.filter(function(d) {
			return d.Region == selected_county && d.State == selected_state && d.Category == selected_category;
		});

		console.table(data);

		const xAccessor = (d) => new Date(d.date);
		const yAccessor = (d) => d.value;

		var mindate = new Date('2020-02-16'),
			maxdate = new Date('2020-03-29');

		var ticks = [ mindate, maxdate ];
		var tickLabels = [ 'February 15', 'March 28' ];

		var x = d3
			.scaleTime()
			.domain([ mindate, maxdate ]) // values between for month of january
			.range([ 0, dimensions.boundedWidth ]);

		var xAxisGenerator = d3.axisBottom(x);

		xAxisGenerator.tickValues(ticks).tickFormat(function(d, i) {
			return tickLabels[i];
		});

		var xAxis = bounds
			.append('g')
			.attr('transform', 'translate(0,' + dimensions.boundedHeight + ')')
			.call(xAxisGenerator);

		xAxis.selectAll('text').attr('font-size', '2em').style('text-anchor', function(d, i) {
			if (tickLabels[i] == 'February 15') {
				return 'start';
			} else {
				return 'end';
			}
		});

		// Add Y axis
		const y = d3
			.scaleLinear()
			.domain(
				d3.extent(data, function(d) {
					return d.value;
				})
			)
			.range([ dimensions.boundedHeight, 0 ]);

		bounds.append('g').call(d3.axisLeft(y)).attr('class', 'y axis');

		// Initialize line with group a
		const line = bounds
			.append('g')
			.append('path')
			.datum(data)
			.attr(
				'd',
				d3
					.line()
					.x(function(d) {
						return x(new Date(d.date));
					})
					.y(function(d) {
						return y(d.value);
					})
			)
			.attr('stroke', 'grey')
			.style('stroke-width', 4)
			.style('fill', 'none');

		const refLine = bounds
			.append('line')
			.style('stroke', 'black')
			.attr('x1', x(new Date('2020-03-14')))
			.attr('y1', 0)
			.attr('x2', x(new Date('2020-03-14')))
			.attr('y2', dimensions.boundedHeight);

		const annotation = bounds
			.append('text')
			.attr('y', 20) //magic number here
			.attr('x', function() {
				return 1.01 * x(new Date('2020-03-14'));
			})
			.attr('text-anchor', 'start')
			.attr('class', 'myLabel') //easy to style with CSS
			.text(' Trump declares national emergency');

		const listeningRect = bounds
			.append('rect')
			.data(data)
			.attr('class', 'listening-rect')
			.attr('width', dimensions.boundedWidth)
			.attr('height', dimensions.boundedHeight)
			.on('mousemove', function() {
				const mousePosition = d3.mouse(this);
				onMouseMove(mousePosition, data);
			})
			.on('mouseleave', onMouseLeave);

		// svg
		// 	.append('svg:line')
		// 	.datum(data)
		// 	.attr('x1', 0)
		// 	.attr('y1', 0)
		// 	.attr('x2', dimensions.boundedWidth)
		// 	.attr('y2', 0)
		// 	.attr('class', 'refline');

		const tooltip = d3.select('#tooltip');
		const tooltipCircle = bounds
			.append('circle')
			.attr('class', 'tooltip-circle')
			.attr('r', 4)
			.attr('stroke', '#af9358')
			.attr('fill', 'white')
			.attr('stroke-width', 2)
			.style('opacity', 0);

		function setupButtons() {
			d3.selectAll('.button').on('click', function() {
				// Remove active class from all buttons
				d3.selectAll('.button').classed('active', false);
				// Find the button just clicked
				var button = d3.select(this);

				// Set it as the active button
				button.classed('active', true);

				// Get the id of the button
				var buttonId = button.attr('id');

				console.log(buttonId);
				// Toggle the bubble chart based on
				// the currently clicked button.
				// update(current)
				selected_category = buttonId;

				updateCat(selected_county, selected_state, selected_category);
			});
		}

		setupButtons();

		function onMouseMove(mousePosition, data) {
			// const mousePosition = d3.mouse(this);
			const hoveredDate = x.invert(mousePosition[0]);

			const getDistanceFromHoveredDate = (d) => Math.abs(xAccessor(d) - hoveredDate);
			const closestIndex = d3.scan(data, (a, b) => getDistanceFromHoveredDate(a) - getDistanceFromHoveredDate(b));
			const closestDataPoint = data[closestIndex];

			const closestXValue = xAccessor(closestDataPoint);
			const closestYValue = yAccessor(closestDataPoint);

			const formatDate = d3.timeFormat('%B %-d');
			tooltip.select('#date').text(formatDate(closestXValue) + ' in ' + selected_county);

			tooltip.select('#interest').text(function() {
				if (!isNaN(closestYValue)) {
					return closestYValue + '%';
				} else {
					return 'No data available.';
				}
			});

			const xTip = x(closestXValue) + dimensions.margin.left;
			const yTip = y(closestYValue) + dimensions.margin.top;

			tooltip.style('transform', `translate(` + `calc(-50% + ${xTip}px),` + `calc(${yTip}px)` + `)`);

			tooltip.style('opacity', 1);

			tooltipCircle.attr('cx', x(closestXValue)).attr('cy', y(closestYValue)).style('opacity', 1);
		}

		function onMouseLeave() {
			tooltip.style('opacity', 0);
			tooltipCircle.style('opacity', 0);
		}

		d3.select('#locSelector').on('change', function() {
			var selected_loc = this.value;
			selected_county = selected_loc.split(',')[0];
			selected_state = selected_loc.split(',')[1];

			selected_state = selected_state.trim();

			// var selected_category = 'Workplace';

			// setupButtons();

			// console.log(selected_category);

			update(selected_county, selected_state, selected_category);
		});

		// A function that update the chart
		function update(selected_county, selected_state, selected_category) {
			// Create new data with the selection?
			data = csv.filter(function(d) {
				return d.Region == selected_county && d.State == selected_state && d.Category == selected_category;
			});

			// data = data.filter(function(d) {
			// 	return d.Category == selected_category;
			// });

			console.table(data);

			const yAccessor2 = (d) => d.value;

			// Add Y axis
			y
				.domain(
					d3.extent(data, function(d) {
						return d.value;
					})
				)
				.range([ dimensions.boundedHeight, 0 ]);

			// Give these new data to update line
			line
				.datum(data)
				.transition()
				.duration(1000)
				.attr(
					'd',
					d3
						.line()
						.x(function(d) {
							return x(new Date(d.date));
						})
						.y(function(d) {
							return y(d.value);
						})
						.defined((d) => !isNaN(d.value)) // Omit empty values.
				)
				.attr('stroke', 'grey');

			listeningRect
				.on('mousemove', function() {
					const mousePosition = d3.mouse(this);

					// const mousePosition = d3.mouse(this);
					const hoveredDate = x.invert(mousePosition[0]);

					const getDistanceFromHoveredDate = (d) => Math.abs(xAccessor(d) - hoveredDate);
					const closestIndex = d3.scan(
						data,
						(a, b) => getDistanceFromHoveredDate(a) - getDistanceFromHoveredDate(b)
					);
					const closestDataPoint = data[closestIndex];

					const closestXValue = xAccessor(closestDataPoint);
					const closestYValue = yAccessor2(closestDataPoint);

					const formatDate = d3.timeFormat('%B %-d');

					tooltip.select('#date').text(formatDate(closestXValue) + ' in ' + selected_county);

					tooltip.select('#interest').text(function() {
						if (!isNaN(closestYValue)) {
							return closestYValue + '%';
						} else {
							return 'No data available.';
						}
					});

					const xTip = x(closestXValue) + dimensions.margin.left;
					const yTip = y(closestYValue) + dimensions.margin.top;

					tooltip.style('transform', `translate(` + `calc(-50% + ${xTip}px),` + `calc(${yTip}px)` + `)`);

					tooltip.style('opacity', 1);

					tooltipCircle.attr('cx', x(closestXValue)).attr('cy', y(closestYValue)).style('opacity', 1);
				})
				.on('mouseleave', onMouseLeave);

			// update(selected_county, selected_state, selected_category);
		}

		function updateCat(selected_county, selected_state, selected_category) {
			// Create new data with the selection?
			data = csv.filter(function(d) {
				return d.Region == selected_county && d.State == selected_state && d.Category == selected_category;
			});

			console.table(data);

			const yAccessor2 = (d) => d.value;

			// Add Y axis
			y
				.domain(
					d3.extent(data, function(d) {
						return d.value;
					})
				)
				.range([ dimensions.boundedHeight, 0 ]);

			// Give these new data to update line
			line
				.datum(data)
				.transition()
				.duration(1000)
				.attr(
					'd',
					d3
						.line()
						.x(function(d) {
							return x(new Date(d.date));
						})
						.y(function(d) {
							return y(d.value);
						})
						.defined((d) => !isNaN(d.value)) // Omit empty values.
				)
				.attr('stroke', 'grey');

			listeningRect
				.on('mousemove', function() {
					const mousePosition = d3.mouse(this);

					// const mousePosition = d3.mouse(this);
					const hoveredDate = x.invert(mousePosition[0]);

					const getDistanceFromHoveredDate = (d) => Math.abs(xAccessor(d) - hoveredDate);
					const closestIndex = d3.scan(
						data,
						(a, b) => getDistanceFromHoveredDate(a) - getDistanceFromHoveredDate(b)
					);
					const closestDataPoint = data[closestIndex];

					const closestXValue = xAccessor(closestDataPoint);
					const closestYValue = yAccessor2(closestDataPoint);

					const formatDate = d3.timeFormat('%B %-d');

					tooltip.select('#date').text(formatDate(closestXValue) + ' in ' + selected_county);

					tooltip.select('#interest').text(function() {
						if (!isNaN(closestYValue)) {
							return closestYValue + '%';
						} else {
							return 'No data available.';
						}
					});

					const xTip = x(closestXValue) + dimensions.margin.left;
					const yTip = y(closestYValue) + dimensions.margin.top;

					tooltip.style('transform', `translate(` + `calc(-50% + ${xTip}px),` + `calc(${yTip}px)` + `)`);

					tooltip.style('opacity', 1);

					tooltipCircle.attr('cx', x(closestXValue)).attr('cy', y(closestYValue)).style('opacity', 1);
				})
				.on('mouseleave', onMouseLeave);

			// update(selected_county, selected_state, selected_category);
		}
	}
);
