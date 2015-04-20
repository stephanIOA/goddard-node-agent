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

	try
		# right so if we got here this was probably from boot
		# ping the main router and configure it
		mikroApi = require('mikronode')
		connection = new mikroApi('192.168.88.10','admin','rogerwilco')

		# done !
		connection.connect (conn) ->

			# open the channel
			chan = conn.openChannel()

			# get the ip
			chan.write [ '/ip/hotspot/host/print' ], ->
				chan.on 'done', (data) ->
					# parse the items
					parsed = mikroApi.parseItems(data)

					# close the cons
					chan.close(true)
					conn.close(true)

					doCallbackCall(null, {

							router: {

								hosts: parsed

							}

						})
	catch e
		doCallbackCall(e)
