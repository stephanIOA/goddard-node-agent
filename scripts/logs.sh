rsync -avr /var/log/nginx/*.log node@goddard.io.co.za:/var/log/$(cat /var/goddard/node.json | jq -r '.uid')/$(date +%Y)/$(date +%m)/$(date +%d)/
rm /var/log/nginx/*.log