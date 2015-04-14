###
# Assembles information about the available hard drive space on the system
###
module.exports = exports = (params, fn) ->

	# required modules
	df = require('node-diskfree')

	# get the disk info
	df.drives (err, drives) ->

		# check for err
		if err 
			fn(err)
		else
			# ask for details on the first drive then
			df.driveDetail drives[0], (err, data) ->

				# check for a error
				if err
					fn(err)
				else
					# calc the amounts
					total_diskspace = data.total.split(' ')[0] * 1000
					free_diskspace	= data.available.split(' ')[0] * 1000

					# return in details
					fn(null, {

						disk: {

							total: Math.round( total_diskspace / 10 ) * 10 ,
							free: Math.round( free_diskspace / 10 ) * 10,
							raid: [ 'ACTIVE', 'ACTIVE' ]

						}

					})