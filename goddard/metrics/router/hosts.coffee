###
# Assembles information about the available hard drive space on the system
###
module.exports = exports = (params, fn) ->

	# run the callback
	already_calledback = false
	doCallbackCall = (err, type_str) ->
		if already_calledback == false
			fn(err, type_str)
			already_calledback = true

	# handles any error
	handleConnectionErrors = (err) ->

		# connection error, finish with our callback
		doCallbackCall(null, {

				wireless: {

					status: 'error'

				}

			})

	try
		# right so if we got here this was probably from boot
		# ping the main router and configure it
		mikroApi = require('mikronode')
		connection = new mikroApi(params.constants.mikrotik.ip.router,params.constants.mikrotik.username,params.constants.mikrotik.password)



		# done !
		connection.connect (conn) ->

			# handle errors on connection
			try
				conn.on 'error', handleConnectionErrors
			catch e
				# nothing, just as a sanity check

			# open the channel
			chan = conn.openChannel()

			# handle errors
			chan.on 'error', handleConnectionErrors

			# get the ip
			chan.write [ '/ip/hotspot/host/print' ], ->
				chan.on 'done', (data) ->
					# parse the items
					parsed = mikroApi.parseItems(data)

					# close the cons
					chan.close(true)
					conn.close(true)

					# done
					doCallbackCall(null, {

							router: {

								hosts: parsed

							}

						})

		# handle errors
		connection.on 'error', handleConnectionErrors

	catch e
		
		# signal that the agent is done
		doCallbackCall(e)
