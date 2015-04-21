###
# Assembles information about the available hard drive space on the system
###
module.exports = exports = (params, fn) ->

	# required modules
	os = require('os')

	# build presentable load
	loadavgs = ( Math.round(loadavg*100)/100  for loadavg in os.loadavg())

	# returns !
	fn null, {

		node: {

			cpus: os.cpus().length,
			load: loadavgs.join(' '),
			uptime: os.uptime()
			
		}

	}