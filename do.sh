#!/bin/bash

FEH_OPT='--bg-max'

# https://gist.github.com/JoshSchreuder/882666
http.get.url.nasa.apod(){
        local BASE_URL='http://apod.nasa.gov/apod/'
	local IMAGE_BASE_URL=$BASE_URL
	local image_url=$(wget --quiet -O - "${BASE_URL}" | fgrep -m1 jpg | cut -f2 -d'"')
	if [[ ! -z $image_url ]]; then
		echo "${IMAGE_BASE_URL}""${image_url}"
	fi
}

# https://gist.github.com/JoshSchreuder/882668
http.get.url.netgeo(){
	local BASE_URL='http://photography.nationalgeographic.com/photography/photo-of-the-day/'
	local IMAGE_BASE_URL='images.nationalgeographic.com'
	local image_url=$(wget --quiet -O - "${BASE_URL}" | egrep -o -m1 "${IMAGE_BASE_URL}"'/.*[0-9]*x[0-9]*.jpg')
	if [[ ! -z $image_url ]]; then
		echo 'http://'"${image_url}"
	fi

}

# Alternative: http://goes.gsfc.nasa.gov/goescolor/goeseast/overview2/color_lrg/latestfull.jpg
http.get.url.fvalk(){
	local BASE_URL='http://www.fvalk.com/images/Day_image/?M=D'
	local IMAGE_BASE_URL='http://www.fvalk.com/images/Day_image/'
	local dust='GOES-12'
	local image_url=$(wget --quiet -O - "${BASE_URL}" | grep -m1 "${dust}" | cut -f6 -d'"')
	if [[ ! -z $image_url ]]; then
		echo "${IMAGE_BASE_URL}""${image_url}"
	fi
}

http.get.url.smn.satopes(){
	local BASE_URL='http://www.smn.gov.ar/pronos/imagenes'
	local image_url="${BASE_URL}"/satopes.jpg
	echo "${image_url}"
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

# this will need to be replaced someday with a more custom logic that getopts ~azimut
while getopts ':giafs' opt; do
	case $opt in
		g) jpg=$(http.get.url.netgeo) ;;
		i) jpg=$(http.get.url.nasa.iotd) ;;
		a) jpg=$(http.get.url.nasa.apod) ;;
		f) jpg=$(http.get.url.fvalk) ;;
		s) jpg=$(http.get.url.smn.satopes); FEH_OPT='--bg-fill';;
		*) echo 'uError: option not supported. ';;
	esac
done

mkdir -p pics # portability
cd pics

# referece: http://blog.yjl.im/2012/03/downloading-only-when-modified-using_23.html
if [[ ! -z $jpg ]]; then
	pic_name=${jpg##*/}
	wget "$jpg" --server-response --timestamping --no-verbose --ignore-length
	DISPLAY=:0.0 feh "${FEH_OPT}" "${pic_name}"
fi
