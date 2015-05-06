#!/bin/sh
# double check folder
mkdir -p /var/goddard

# done
echo "{\"build\":\"busy\",\"process\":\"Loading base image\",\"timestamp\":\"$( date +%s )\"}" > /var/goddard/build.json

# load in the docker image
docker load < /var/goddard/node.img.tar || true

# done
echo "{\"build\":\"busy\",\"process\":\"Downloading app list for node ...\",\"timestamp\":\"$( date +%s )\"}"  > /var/goddard/build.json

# read in all the apps from the server
curl "http://hub.goddard.unicore.io/apps.json?uid=$(cat /var/goddard/node.json | jq -r '.uid')" > /var/goddard/apps.raw.json

# check if the returned json was valid
eval cat /var/goddard/apps.raw.json | jq -r '.'

# register the return code
ret_code=$?

# check the code, must be 0
if [ $ret_code = 0 ]; then

	# move the json to live node details
	mv /var/goddard/apps.raw.json /var/goddard/apps.json

	# done
	echo "{\"build\":\"busy\",\"process\":\"Downloading app list for node ...\",\"timestamp\":\"$( date +%s )\"}"  > /var/goddard/build.json

	# awesome start a deploy
	cat /var/goddard/apps.json | jq -r '.[]  | "\(.key) \(.domain) \(.port)"' > /var/goddard/apps.keys.txt

	# delete the old nginx conf
	rm /etc/nginx/conf.d/*.conf || true

	# write default config
	cat /var/goddard/agent/templates/nginx.static.conf > /etc/nginx/conf.d/default.conf

	# cool so now we have the keys
	while read tkey tdomain tport
	do

		# debug
		echo "Downloading application $tdomain"

		# done
		echo "{\"build\":\"busy\",\"process\":\"Downloading application $tdomain\",\"timestamp\":\"$( date +%s )\"}"  > /var/goddard/build.json

		# sync down the code
		rsync -aPzr --progress node@hub.goddard.unicore.io:/var/goddard/apps/$tkey/ /var/goddard/apps/$tkey

		# debug
		echo "Building $tdomain"

		# done
		echo "{\"build\":\"busy\",\"process\":\"Building $tdomain\",\"timestamp\":\"$( date +%s )\"}"  > /var/goddard/build.json

		# build the app
		cd /var/goddard/apps/$tkey && docker build --tag="$tkey" --rm=true .

	done < /var/goddard/apps.keys.txt

	# done
	echo "Stopping all running apps"

	# done
	echo "{\"build\":\"busy\",\"process\":\"Stopping all running apps\",\"timestamp\":\"$( date +%s )\"}"  > /var/goddard/build.json

	# stop all the running apps
	docker kill $(docker ps -a -q) || true

	# cool so now we have the keys
	while read tkey tdomain tport
	do

		# start the app
		echo "Starting $tdomain"

		# done
		echo "{\"build\":\"busy\",\"process\":\"Starting $tdomain\",\"timestamp\":\"$( date +%s )\"}"  > /var/goddard/build.json

		# start the app
		cd /var/goddard/apps/$tkey && docker run --restart=always -p $tport:8080 -d $tkey

		# done
		echo "Adding $tdomain web server config"

		# done
		echo "{\"build\":\"busy\",\"process\":\"Adding $tdomain web server config\",\"timestamp\":\"$( date +%s )\"}"  > /var/goddard/build.json

		# write out the service file
		sudo cat <<-EOF > /etc/nginx/conf.d/$tdomain.conf

			server {

				listen                          80;
				server_name                     $tdomain;
				access_log                      /var/log/nginx/${tkey}.access.log;
				error_log                       /var/log/nginx/${tkey}.error.log;

				location / {

					proxy_pass                  http://127.0.0.1:${tport}$request_uri;
					proxy_redirect              off;

					proxy_set_header            Host             $host;
					proxy_set_header            X-Real-IP        $remote_addr;
					proxy_set_header            X-Forwarded-For  $proxy_add_x_forwarded_for;
					proxy_max_temp_file_size    0;

					client_max_body_size        10m;
					client_body_buffer_size     128k;

					proxy_connect_timeout       120;
					proxy_send_timeout          1200;
					proxy_read_timeout          120;

					proxy_buffer_size           128k;
					proxy_buffers               4 256k;
					proxy_busy_buffers_size     256k;
					proxy_temp_file_write_size  256k;

				}

			}

		EOF

	done < /var/goddard/apps.keys.txt

else			

	# done
	echo "{\"build\":\"error\",\"process\":\"Parsing of app.json failed from hub server\",\"timestamp\":\"$( date +%s )\"}"  > /var/goddard/build.json

	# debugging to tell us why
	echo "The json parsing test failed, server returned invalid JSON, the test was done on /var/goddard/apps.raw.json"

	# stop the process
	exit 1

fi

# restart nginx
service nginx restart || true

# done
echo "{\"build\":\"done\",\"process\":\"Done\",\"timestamp\":\"$( date +%s )\"}"  > /var/goddard/build.json
