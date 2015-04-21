###
# Assembles information about the available hard drive space on the system
###
module.exports = exports = (params, fn) ->

	# get all the metrics
	bgan = require('hughes-bgan');
	bgan.metrics {

			host: params.bgan.ip,
			port: 1829

		}, (err, res) ->
			if err
				fn(err, {})
			else
				# check if good
				parsed_obj = JSON.parse(res)

				# did it return
				if parsed_obj
					# output we are going to send out
					output_obj = {}

					# add each if it exists
					output_obj.faults = parsed_obj.faults or 0
					if parsed_obj.gps
						output_obj.lat = parsed_obj.gps.lat or null
						output_obj.lng = parsed_obj.gps.lon or null
						output_obj.status = parsed_obj.gps.status or null

					output_obj.ethernet = parsed_obj.ethernet == 1
					output_obj.usb = parsed_obj.usb == 1
					output_obj.signal = parsed_obj.signal or 0
					output_obj.temp = parsed_obj.temp or 0
					output_obj.imsi = parsed_obj.imsi or null
					output_obj.imei = parsed_obj.imei or null
					output_obj.ip = parsed_obj.ip or null
					output_obj.satellite_id = parsed_obj.satellite_id or null

					# done
					fn(null, {

							bgan: output_obj

						})
				else
					fn(new Error('Could not parse response ...'), {})