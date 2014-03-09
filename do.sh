#!/bin/bash

# https://gist.github.com/JoshSchreuder/882666
# https://gist.github.com/JoshSchreuder/882668
http.get.url.nasa.apod(){
        local BASE_URL='http://apod.nasa.gov/apod/'
	local IMAGE_BASE_URL=$BASE_URL
	local image_url=$(wget --quiet -O - "${BASE_URL}" | fgrep -m1 jpg | cut -f2 -d'"')
	if [[ ! -z $image_url ]]; then
		echo "${IMAGE_BASE_URL}""${image_url}"
	fi
}

http.get.url.netgeo.(){
	local BASE_URL='http://photography.nationalgeographic.com/photography/photo-of-the-day/'
	local IMAGE_BASE_URL='images.nationalgeographic.com'
	local image_url=$(wget --quiet -O - "${BASE_URL}" | egrep -o -m1 "${IMAGE_BASE_URL}"'/.*[0-9]*x[0-9]*.jpg')
	if [[ ! -z $image_url ]]; then
		echo 'http://'"${image_url}"
	fi

}

http.get.url.fvalk(){
	local BASE_URL='http://www.fvalk.com/images/Day_image/?M=D'
	local IMAGE_BASE_URL='http://www.fvalk.com/images/Day_image/'
	local dust='GOES-12'
	local image_url=$(wget --quiet -O - "${BASE_URL}" | grep -m1 "${dust}" | cut -f6 -d'"')
	if [[ ! -z $image_url ]]; then
		echo "${IMAGE_BASE_URL}""${image_url}"
	fi
}

# Reference: http://awesome.naquadah.org/wiki/NASA_IOTD_Wallpaper
# The Content-encoding of this server is not always the same, sometimes is gzipped and sometimes not.
# That's why I am using some login to detect that and "base64" to store the gzip file in a variable.
http.get.url.nasa.iotd(){
	local BASE_URL='http://www.nasa.gov/rss/dyn/lg_image_of_the_day.rss'
	local html_url=$(base64 <(wget --quiet -O - --header='Accept-Encoding: gzip' "${BASE_URL}"))
	local ftype=$(echo "$html_url" | base64 --decode | file -)
	
	if [[ $ftype == *gzip* ]]; then
		html_url=$(echo "$html_url" | base64 --decode | gunzip -)
	else
		html_url=$(echo "$html_url" | base64 --decode )
	fi
	
	image_url=$(echo "$html_url" | fgrep -m1 enclosure | cut -f2 -d'"' )

	if [[ ! -z $image_url ]]; then
		echo "${image_url}"
	fi

}

while getopts ':giaf' opt; do
	case $opt in
		g) http.get.url.netgeo. ;;
		i) http.get.url.nasa.iotd ;;
		a) http.get.url.nasa.apod ;;
		f) http.get.url.fvalk ;;
		*) echo 'uError: option not supported. ';;
	esac
done
