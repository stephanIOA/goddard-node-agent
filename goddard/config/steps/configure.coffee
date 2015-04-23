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
	S = require('string')
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

		
		# debug
		console.log 'running the import command'

		# right so if we got here this was probably from boot
		# ping the main router and configure it
		mikroApi = require('mikronode')
		connection = new mikroApi(address_ip_str,params.constants.mikrotik.username,params.constants.mikrotik.password)

		# done !
		connection.connect (conn) ->

			# required module
			readline = require('readline')

			# commands
			command_strs = []

			# configure to read the file and how
			rl = readline.createInterface({

				input : fs.createReadStream('./config/' + key_str + '.rsc'),
				output: process.stdout,
				terminal: false

			})

			# current command
			command_prefix_str = ''
			current_line_str = ''
			prefixes = []

			# run each of the lines
			rl.on 'line',(line) ->

				# assign prefix
				if S(line).startsWith('/')
					command_prefix_str = line
				else
					# check the line
					if S(line).endsWith('\\')
						current_line_str = current_line_str + line + '\n'
					else
						current_line_str = current_line_str + line 
						# console.log current_line_str
						command_strs.push(command_prefix_str + ' ' + current_line_str)
						current_line_str = ''

			# when done
			rl.on 'close', ->

				# run the command
				handleRunningCommand = (command_str, callbackItem) ->

					# debugging
					fs.writeFile './line.rsc', command_str, ->

						# connect using ftp
						Client = require('ftp')
						c = new Client()
						c.on 'ready', ->
							c.put './line.rsc', 'line.rsc', (err) ->
								# check for a error
								if err
									callbackItem(err)
								else
									# open the channel
									chan = conn.openChannel()

									# get the ip
									chan.write [ '/import', '=file-name=line.rsc' ], ->
										chan.on 'done', (data) ->

											# did we get a response ?
											if data[0][1]

												# display the output
												console.log command_str
												console.log data[0][1]

											# close the connection
											chan.close(true)

											# done
											callbackItem()

						# handle any errors thrown
						c.on 'error', (err) ->
							# debug
							console.dir err
							# throw back callback
							callbackItem()

						# try to connect
						c.connect({

							host: address_ip_str,
							user: params.constants.mikrotik.username,
							password: params.constants.mikrotik.password

						})

				# awesome no send to server
				async.eachSeries command_strs, handleRunningCommand, ->

					# close the connection
					conn.close(true)

					# output this
					cb()

	# loop each of the configs
	async.eachSeries [ 'wireless', 'router' ], handleConfigApplication, fn