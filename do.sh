#!/bin/bash

http.get.url.nasa.apod(){
	#echo "Downloading page to find image"
	if wget http://apod.nasa.gov/apod/ --quiet -O /tmp/apod.html; then
		grep -m 1 jpg /tmp/apod.html | sed -e 's/<//' -e 's/>//' -e 's/.*=//' -e 's/"//g' -e 's/^/http:\/\/apod.nasa.gov\/apod\//'
	else
		echo 'uError: we couldn'"'"'t fetch the url..'
		exit 1
	fi
	rm -f /tmp/apod.html
}

http.get.image.nasa.apod(){
	if [[ ! -f ${IMAGE_PATH} ]]; then
		wget $(http.get.url.nasa.apod) --quiet -O ${IMAGE_PATH}
	fi
}

TODAY=$(date +%d%m%y)
IMAGE_DIR=${HOME}/nasa-pic
IMAGE_NAME=${TODAY}_apod.jpg
IMAGE_PATH=${IMAGE_DIR}/${IMAGE_NAME}

while getopts ':gn' opt; do
	case $opt in
		g) echo g ;;
		n) http.get.image.nasa.apod ;;
		*) echo 'uError: option not supported. ';;
	esac
done
