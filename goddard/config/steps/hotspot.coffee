##
# check if 88.5 and 88.10 responds then skip to CONFIGURE
##
module.exports = exports = (params, fn) ->

	# load in required modules
	async = require('async')
	_ = require('underscore')
	request = require('request')
	ping = require('ping')

	# connect using ftp
	Client = require('ftp')
	c = new Client()
	c.on 'ready', ->
		c.put './templates/hotspot.redirect.html', 'hotspot/login.html', (err) ->
			# close the connection
			c.end()
			# trigger callback
			fn(err)

	# handle any errors thrown
	c.on 'error', fn

	# try to connect
	c.connect({

		host: params.constants.mikrotik.ip.router,
		user: params.constants.mikrotik.username,
		password: params.constants.mikrotik.password

	})