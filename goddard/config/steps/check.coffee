##
# check if 88.5 and 88.10 responds then skip to CONFIGURE
##
module.exports = exports = (params, fn) ->

	# load in required modules
	async = require('async')
	_ = require('underscore')
	request = require('request')
	ping = require('ping')

	# states of the routers
	deviceStatus = {

		router: false,
		wireless: false

	}

	# loop each
	async.series [

		(cb) ->
			console.log '========================='
			console.log 'CHECKING STATUS:'

			# create the request
			r = request {

					url: 'http://' + params.constants.mikrotik.ip.router + '',
					timeout: 2500

				}, (err, response, body) ->
					# handle the status
					if not err and body
						deviceStatus.router = true
					else
						deviceStatus.router = false

					# output to follow on console
					if deviceStatus.router == true
						# was it a success ?
						console.log 'ROUTER - OK'
					else
						console.log 'ROUTER - NOT CONFIGURED'
					cb(null)

		, (cb) ->	

			# create the request
			r = request {

					url: 'http://' + params.constants.mikrotik.ip.wireless + '',
					timeout: 2500

				}, (err, response, body) ->
					# handle the status
					if not err and body
						deviceStatus.wireless = true
					else
						deviceStatus.wireless = false

					# output to follow on console
					if deviceStatus.wireless == true
						# was it a success ?
						console.log 'WIRELESS - OK'
					else
						console.log 'WIRELESS - NOT CONFIGURED'
					console.log '========================='
					cb(null)

	], =>

		# loop count
		retries = 0
		max_retry = 5

		# get the type of device running at default now
		getDeviceTypeRunningAtGateway = (ip_str, cb) ->

			# debugging
			console.log 'pinging <' + ip_str + '> to see if something is still running there'

			# ping the device first
			ping.sys.probe ip_str, (isAlive) ->

				# run the callback
				already_calledback = false
				doCallbackCall = (err, type_str) ->
					if already_calledback == false
						cb(err, type_str)
						already_calledback = true

				# if it's there, just go for it
				if isAlive == true

					try
						# right so if we got here this was probably from boot
						# ping the main router and configure it
						mikroApi = require('mikronode')
						connection = new mikroApi(ip_str,'' + params.constants.mikrotik.username + '','')

						# handle any errors to avoid the unthrown errors
						connection.on 'error', (e) ->  doCallbackCall(e)

						# done !
						connection.connect (conn) ->

							# get the error if any
							conn.on 'error', (e) ->  doCallbackCall(e)

							# open the channel
							chan = conn.openChannel()

							# get the ip
							chan.write [ '/interface/print' ], ->
								chan.on 'done', (data) ->
									parsed = mikroApi.parseItems(data)

									# get all the types
									interface_types = _.pluck(parsed, 'type')

									# get the type
									type_str = if interface_types.indexOf('wlan') != -1 then 'wireless' else 'router'

									# close the connection and channel
									chan.close(true)
									conn.close(true)
									connection.close(true)

									# done
									doCallbackCall(null, type_str)
					catch e
						console.dir e
						# conn.close(true)
						doCallbackCall(e)

				else
					doCallbackCall(new Error())

		# try to get the router
		handleChoosingDevice = ->

			# count up
			retries = retries + 1

			# gateway at default now
			defaultGatewayStr = '' + params.constants.mikrotik.ip.default + ''

			# get the type
			getDeviceTypeRunningAtGateway defaultGatewayStr, (err, type_str) ->

				# check for a error
				if err

					# check it
					if deviceStatus.router == true and deviceStatus.wireless == true

						# debugging
						console.log 'FINISHED CHECKING AND SETTING BOTH ROUTER AND WIRELESS'

						# finish the loop
						fn(null)
					else
						setTimeout(handleChoosingDevice, 1000)

				else

					# choose the function
					deviceFunc = null

					# debug
					console.log 'Found <' + type_str + '> running at ' + defaultGatewayStr

					# check it !
					if type_str == 'router' and deviceStatus.router == false
						deviceFunc = configureRouter
					else if type_str == 'wireless' and deviceStatus.wireless == false
						deviceFunc = configureWireless

					# is it there ... ?
					if deviceFunc

						# execute it
						deviceFunc (err) =>

							# give up ?
							if retries <= max_retry

								# wait a second and try again
								setTimeout(handleChoosingDevice, 1000)

							else
								console.log 'TIMEOUT'
								process.exit(1)
								fn(null)

					else
						# give up ?
						if retries <= max_retry

							# wait a second and try again
							setTimeout(handleChoosingDevice, 1000)

						else
							console.log 'TIMEOUT'
							process.exit(1)
							fn(null)

		# changes the ip of a router sitting
		# at target address to passed ip
		configureIPAddress = (connect_to_str, new_ip_str, cb) ->

			try
				# right so if we got here this was probably from boot
				# ping the main router and configure it
				mikroApi = require('mikronode')
				connection = new mikroApi(connect_to_str,'' + params.constants.mikrotik.username + '','')
				# connection.debug = 5

				# done !
				connection.connect (conn) ->

					# open the channel
					chan = conn.openChannel()

					console.log 'channel'

					# get the ip
					chan.write '/ip/address/print', ->
						console.log 'waiting on data'
						chan.on 'done', (data) ->

							# parse the returns items
							parsed = mikroApi.parseItems(data)

							# find the interface we are going to configure
							interface_obj = _.find parsed, (interface_obj) ->
								return ('' + interface_obj.address).toLowerCase() == '' + params.constants.mikrotik.ip.default + '/24'

							# close and move on
							chan.close(true)

							# did we find that interface ?
							if interface_obj

								# open a new one
								chan = connection.openChannel()

								# handle done
								alreadyClosed = false
								handleClosingDone = (err) ->
									if alreadyClosed == false
										alreadyClosed = true

										# close and move on
										chan.close(true)
										connection.close(true)

										# throw back error
										cb(null)

								chan.on 'error', ->
								chan.getConnection().on('error', handleClosingDone)

								# configure the ip
								chan.write [ '/user/set', '=.id=*1', '=password=' + params.constants.mikrotik.password ], ->
									chan.on 'done', ->
										# configure the ip
										chan.write [ '/ip/address/set', '=.id=' + interface_obj['.id'], '=address=' + new_ip_str + '/24' ], ->
											chan.on 'done', handleClosingDone

										setTimeout(handleClosingDone, 8000)
										

							else

								# close and move on
								connection.close(true)

								# throw back error
								cb(new Error('No valid interface for default protocol'))
			catch e
				cb(e)
					

		# configures the router
		configureRouter = (cb) =>

			# debug
			console.log 'Trying to configure router'

			# configure the ip
			configureIPAddress('' + params.constants.mikrotik.ip.default + '', '' + params.constants.mikrotik.ip.router + '', (err) ->

				# debugging and enable
				console.log 'Trying to configure router [DONE]'
				deviceStatus.router = true

				# done !
				cb(null)
			)

		# configure the wireless access point
		configureWireless = (cb) =>

			# debug
			console.log 'Trying to configure wireless'

			# configure the ip
			configureIPAddress('' + params.constants.mikrotik.ip.default + '', '' + params.constants.mikrotik.ip.wireless + '', (err) ->

				# debugging and enable
				console.log 'Trying to configure wireless [DONE]'
				deviceStatus.wireless = true

				# done !
				cb(null)
			)

		# choose and configure out devices
		handleChoosingDevice()