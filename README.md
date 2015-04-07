# Goddard Node Agent

The "agent" is a collection of scripts that are built to be run once off by cron jobs that are configured on the node.

There are a few "actions" that the agent performs:

### Configuration

Run on boot of the node. This script ensure thats all the components in the box are setup and working. This is meant to ensure that internal config of the box will also be able to connect and creates a baseline of a working unit that can be provisioned from the server after a connection has been setup.

### Metrics

Runs every X minutes. And collects a variety of metrics from the system to build a metric payload that is sent up to the Hub Server. Were it is saved and processed. 

This is still a work in progress and more metrics might be added or removed as the project continues.

A current example of the payload:

````json
{

	"nodeid": 1,
	"timestamp": "",
	"node": {

		"cpus": 4,
		"load": "1.0, 0.6, 0.4",
		"uptime": 13,

		"memory": {

			"free": 468,
			"total": 1024

		},
		"disk": {

			"free": 14300,
			"total": 19900,
			"raid": [ "ACTIVE","ACTIVE" ]

		}

	},
	"bgan": {

		"uptime": 1,
		"lat": "33.123",
		"lng": "18.134",
		"temp": 38.4,
		"ping": 1300

	},
	"router": {

		"uptime": 100

	},
	"wireless": {

		"uptime": 100

	},
	"relays": [ 1,0,0,0 ]

}
````