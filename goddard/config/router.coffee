###
# Assembles information about the available hard drive space on the system
###
module.exports = exports = (params, fn) ->

	# pull in the module
	mikroApi = require('mikronode')

	# right so if we got here this was probably from boot
	# ping the main router and configure it
	connection = new mikroApi('192.168.88.1','admin','')
	connection.connect (conn) ->

		# open the channel
		chan = conn.openChannel()

		# get the ip
		chan.write '/interface/print', ->
			chan.on 'done', (data) ->
				parsed = mikroApi.parseItems(data)

				# get all the types
				interface_types = _.pluck(parsed, 'type')

				# get the interface
				if interface_types.indexOf('wlan') != -1
					# this is the wifi !
					console.log 'this is wifi'
				else
					console.log 'this is not the wifi interface'

				chan.close()
				conn.close()

				# done
				fn(null)

	# check if this is the wifi router
	fn(null)

	.write('/ip/address/getall',function(channel) {