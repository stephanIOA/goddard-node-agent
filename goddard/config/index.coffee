###
# Assembles all the enabled modules ready for use
###
module.exports = exports = (params, fn) ->

	# load in required modules
	_ = require('underscore')
	async = require('async')

	# output from all of them if any
	payload = {}

	##
	# Steps that are taken:
	# -> check if 88.5 and 88.10 exists, if it does skip to CONFIGURE step
	# -> check what device is at 88.1 if none continue 
	# -> if it's wifi configure the wifi device
	# -> if it's the router configure to use 88.5
	# -> loop until we reach the wifi access point at 88.1
	# -> configure wireless access point to listen at 88.10
	# -> apply settings to router
	# -> apply to wireless access point
	# -> handshake
	##

	# the array of enabled configs
	configHandlers = [

		require('./steps/check'),
		require('./steps/configure')

	]

	# handles collecting the result
	handleCollection = (configHandler, cb) ->

		# run the config to collect
		configHandler(params, (err, output) ->

			# if we got no error
			if not err and output
				payload = _.merge(payload, output)

			# return with the error if any
			cb(err)

		)

	# execute each of them the function and collect the result.
	async.eachSeries configHandlers, handleCollection, fn