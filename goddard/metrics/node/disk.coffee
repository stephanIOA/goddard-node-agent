###
# Assembles information about the available hard drive space on the system
###
module.exports = exports = (params, fn) ->

	# required modules
	df = require('node-diskfree')
	fs = require('fs')
	_ = require('underscore')

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

					# read in raid status
					fs.readFile '/proc/mdstat', (err, data) ->

						# coolio
						if err
							fn(err)
						else

							# parse out status
							parsed_status_matches = ('' + data).toLowerCase().match(/\[(.*?)\]/gi)

							# get the last one
							parsed_status = _.last(parsed_status_matches)

							# final raids status
							raid_status = []

							# get the status
							parsed_status = parsed_status.replace('[', '')
							parsed_status = parsed_status.replace(']', '')

							# check the status
							for drive_status in parsed_status

								# depending on status add item
								if drive_status == 'u'
									raid_status.push('UP')
								else
									raid_status.push('DOWN')

							# return in details
							fn(null, {

								node: {

									disk: {

										total: Math.round( total_diskspace / 10 ) * 10 ,
										free: Math.round( free_diskspace / 10 ) * 10,
										raid: raid_status

									}
									
								}

							})