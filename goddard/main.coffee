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

	# check if we know it ?
	if argv.action == 'metrics'
		# get the metric function
		metricsRun = require('./metrics')

		# run and get our details
		metricsRun({

			uid: '1'

		}, (err, payload) ->

			console.dir payload

		)
	else if argv.action == 'configure'
		console.log 'configure here'
	else
		console.log 'Unknown --action flag.'

else
	console.log 'Missing the --action flag'


