###
# Assembles all the enabled modules ready for use
###
module.exports = exports = (params, fn) ->

	# load in the required modules
	async = require('async')
	_ = require('lodash')
	request = require('request')
	fs = require('fs')

	# builds the default payload
	payload = {

		node: {},
		wireless: {},
		router: {},
		relays: [],
		bgan: {},
		nodeid: params.uid,
		timestamp: new Date().getTime()

	}

	# the array of enabled metrics
	metricHandlers = [

		require('./node/system'),
		require('./node/disk'),
		require('./node/memory'),
		require('./bgan'),
		require('./router/hosts'),
		require('./wireless/hosts'),
		require('./relay')

	]

	# handles collecting the result
	handleCollection = (metricHandler, cb) ->

		# run the metric to collect
		metricHandler(params, (err, output) ->

			# if we got no error
			if output
				payload = _.merge(payload, output)

			# return with the error if any
			cb(null)

		)

	# execute each of them the function and collect the result.
	async.each metricHandlers, handleCollection, (err) ->

		# timing
		started = new Date().getTime()

		# awesome no send out the metrics to the endpoint
		server_host_url = params.argv.server or params.node.server or '6fcf9014.ngrok.com'

		# add in the server host url
		if server_host_url.indexOf('http://') == -1
			server_host_url = 'http://' + server_host_url

		# create the metric endpoint
		metric_endpoint_url_str = server_host_url + '/metric.json'

		# debug
		console.log 'POSTing to ' + metric_endpoint_url_str

		# handle when the metrics are done
		metricsCallback = (err, payload) ->

			# timing
			ended = new Date().getTime()

			# output info
			console.log 'Update request to server callback took ' + (ended-started) + 'ms'

			# handle each
			fn(err, payload)

		# check the save
		if params.argv.save

			# done
			fs.writeFile '/var/goddard/status.json', JSON.stringify(payload), (err) ->

				# output when we are done
				# with the payload coming out
				metricsCallback(err, payload)

		else

			# send it out
			request {

				url: metric_endpoint_url_str,
				method: 'POST',
				timeout: 5000 * 5,
				headers: {
					"content-type": "application/json"
				},
				json: payload

			}, (err, response, body) -> 	

				# response debugging
				console.log 'server response:'
				console.log body

				# handle it
				metricsCallback(err, payload)
