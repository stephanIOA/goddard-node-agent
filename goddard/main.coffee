###
# Goddard Agent
# That runs on a cron job
# to configure the node and 
# send metrics back up to the 
# hub
###

# parse the parameters
argv = require('minimist')(process.argv.slice(2))

# check for the type
if argv.action

	# generate the params
	runParams = {
		uid: '1',
		constants: require('./constants')
	}

	# check if we know it ?
	if argv.action == 'metrics'

		# get the metric function
		metricsRun = require('./metrics')

		# run and get our details
		metricsRun(runParams, (err, payload) ->

			# output when we are done
			# with the payload coming out
			console.dir payload

		)
	else if argv.action == 'configure'
		# get the config function
		configRun = require('./config')
		# get it going
		configRun(runParams, (err) -> 
			console.log 'done'
		)
	else
		console.log 'Unknown --action flag.'

else
	console.log 'Missing the --action flag'


