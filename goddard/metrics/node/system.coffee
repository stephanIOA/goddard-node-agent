###
# Assembles information about the available hard drive space on the system
###
module.exports = exports = (params, fn) ->

	# required modules
	os = require('os')

	# returns !
	fn null, {

		cpus: os.cpus().length,
		load: os.loadavg().join(' '),
		uptime: os.uptime()

	}