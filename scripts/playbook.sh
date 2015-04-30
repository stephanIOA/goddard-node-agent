# make sure the folder exists
mkdir -p /var/goddard/playbook

# sync down the playbook that the node can run
rsync -avr node@goddard.io.co.za:/var/goddard/playbook/ /var/goddard/playbook