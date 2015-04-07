###
# Assembles all the enabled modules ready for use
###
module.exports = exports = (params, fn) ->

	# load in the required modules
	async = require('async')
	_ = require('underscore')

	# builds the default payload
	payload = {

		node: {},
		wireless: {},
		router: {},
		relay: {},
		bgan: {},
		nodeid: params.uid,
		timestamp: new Date().getTime()

	}

	# the array of enabled metrics
	metricHandlers = [

		require('./node/system.coffee'),
		require('./node/disk.coffee'),
		require('./node/memory.coffee')

	]

	# handles collecting the result
	handleCollection = (metricHandler, cb) ->

		# run the metric to collect
		metricHandler(params, (err, output) ->

			# if we got no error
			if not err
				payload = _.extend(payload, output)

			# return with the error if any
			cb(err)

		)

	# execute each of them the function and collect the result.
	async.each metricHandlers, handleCollection, (err) ->

		# handle each
		fn(err, payload)