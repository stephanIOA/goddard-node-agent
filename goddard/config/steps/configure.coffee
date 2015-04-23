##
# check if 88.5 and 88.10 responds then skip to CONFIGURE
##
module.exports = exports = (params, fn) ->

	# load in required modules
	async = require('async')
	_ = require('underscore')
	request = require('request')
	ping = require('ping')
	fs = require('fs')
	readline = require('readline')

	# handle reading in the actual config files
	handleConfigApplication = (key_str, cb) ->

		# the ip to use based on type
		address_ip_str = params.constants.mikrotik.ip.default

		# check the type
		if params.constants.mikrotik.ip[ key_str ]
			address_ip_str = params.constants.mikrotik.ip[ key_str ]
		
		# debugging
		console.log 'connecting to ' + address_ip_str + ' with ' + key_str + '.rsc that has the preloaded config'

		# connect using ftp
		Client = require('ftp')
		c = new Client()
		c.on 'ready', ->
			c.put './config/' + key_str + '.rsc', 'config.rsc', (err) ->
				# check for a error
				if err
					cb(err)
				else
					# debug
					console.log 'running the import command'
					# close it
					c.end()
					# right so if we got here this was probably from boot
					# ping the main router and configure it
					mikroApi = require('mikronode')
					connection = new mikroApi(address_ip_str,params.constants.mikrotik.username,params.constants.mikrotik.password)

					# done !
					connection.connect (conn) ->

						# open the channel
						chan = conn.openChannel()

						# get the ip
						chan.write [ '/import', '=file-name=config.rsc' ], ->
							chan.on 'done', (data) ->

								# display the output
								console.log 'output from config import'
								console.log data

								# close the connection
								chan.close(true)
								conn.close(true)

								# output this
								cb()

		# handle any errors thrown
		c.on 'error', (err) ->
			# debug
			console.dir err
			# throw back callback
			cb(err)

		# try to connect
		c.connect({

			host: address_ip_str,
			user: params.constants.mikrotik.username,
			password: params.constants.mikrotik.password

		})

	# loop each of the configs
	async.eachSeries [ 'wireless', 'router' ], handleConfigApplication, fn