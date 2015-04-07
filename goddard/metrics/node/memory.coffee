###
# Assembles information about the available hard drive space on the system
###
module.exports = exports = (params, fn) ->

	# required modules
	os = require('os')

	# returns !
	fn null, {

		memory: {

			total: os.totalmem(),
			free: os.freemem()

		}

	}