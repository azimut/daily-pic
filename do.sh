#!/bin/bash

FEH_OPT='--bg-fill'
WGET_OPT='--user-agent=Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/30.0.1599.66 Safari/537.36'

help.usage(){
    cat <<EOF
Usage: $0 [-hcgiafsmntwbd]
   -g National Geographic Image of the day
   -a NASA Astronomy Picture Of the Day (APOD)
   -i NASA Image of the Day
   -f FVALK satellite image of the earth updated each 3 hours
   -s SMN Servicio Metereologico Nacional Argentino - Imagen de radar
   -c images from 4chan/4walled.cc (rand)
   -m monterey nexsat
   -n nasa goes
   -t interfacelift (rand)
   -w wallbase (rand)
   -b bing (iod)
   -r reddit (wallpaper/imgur)
   -d deviantart (rand/24h)
EOF
}

echoerr() { echo "$@" 1>&2; }

check_in_path(){
    local cmd=$1
    hash "$cmd" &>/dev/null || {
        echoerr "uError: command \"$cmd\" not found in \$PATH, please add it or install it..."
        exit 1
    }
}

check_in_path 'feh'
check_in_path 'wget'

[[ $# -ne 1 ]] && { 
    echoerr "uError: Missing argument."
    help.usage
    exit 1
}

# Reference: https://github.com/datagutt/wallscrape
http.get.url.deviantart(){
    local BASE_URL='http://browse.deviantart.com/customization/wallpaper/'
    local image_url=$(
        wget "${WGET_OPT}" -q -O- "${BASE_URL}" | 
        egrep -o 'data-src="http://[[:alnum:]]+\.deviantart\.net/[[:alnum:]]+/200H/.+/.+/.+/.+/.+/.+\.png"' | 
        cut -f2 -d'"' | 
        shuf -n1
    )
    image_url=${image_url/200H/}
    if [[ ! -z $image_url ]]; then
        echo "${image_url}"
    fi
}

# Reference: https://github.com/wmmc/Wallpaper-Downloader
http.get.url.reddit(){
    local BASE_URL='http://www.reddit.com/r/wallpapers/.json'
    local image_url=$(
        wget "${WGET_OPT}" -q -O- "${BASE_URL}" | 
	tr ' ' '\n' | 
	egrep -o 'http://i.imgur.com/[[:alnum:]]+\.(png|jpg)' | 
	shuf -n1
    )
    if [[ ! -z ${image_url} ]]; then
        echo "${image_url}"
    fi
}

# Reference: https://github.com/tsia/bing-wallpaper
http.get.url.bing(){
    local BASE_URL='http://www.bing.com/HPImageArchive.aspx?format=js&n=1&pid=hp&video=0'
    local IMAGE_BASE_URL='http://www.bing.com'
    local image_url=$(
        wget "${WGET_OPT}" -q -O- "${BASE_URL}" | 
	sed -E 's/.*"url":"([^"]+)"[,\}].*/\1/g' 
    )
    if [[ ! -z ${image_url} ]]; then
        echo "${IMAGE_BASE_URL}""${image_url}"
    fi
}

http.get.url.wallbase(){
    local BASE_URL='http://wallbase.cc/random'
    local image_url=$(
        wget "${WGET_OPT}" -q -O- "${BASE_URL}" | 
	egrep -o 'http://thumbs.wallbase.cc//[[:alpha:]-]+/thumb-[0-9]+.jpg' | 
	shuf -n1
    )
    image_url=${image_url/thumb-/wallpaper-}
    image_url=${image_url/thumbs/wallpapers}
    if [[ ! -z $image_url ]]; then
        echo "${image_url}"
    fi
}

http.get.url.nrlmry.nexsat(){
    local region='SouthAmerica' # NW_Atlantic
    local path='SouthAmerica/Overview' # NW_Atlantic/Caribbean
    local BASE_URL='http://www.nrlmry.navy.mil/nexsat-bin/nexsat.cgi?BASIN=CONUS&SUB_BASIN=focus_regions&AGE=Archive&REGION='"${region}"'&SECTOR=Overview&PRODUCT=vis_ir_background&SUB_PRODUCT=goes&PAGETYPE=static&DISPLAY=single&SIZE=Thumb&PATH='"${path}"'/vis_ir_background/goes&&buttonPressed=Archive'
    local IMAGE_BASE_URL='http://www.nrlmry.navy.mil/htdocs_dyn_apache/PUBLIC/nexsat/thumbs/full_size/'"${path}"'/vis_ir_background/goes/'
    local image_url=$(
        wget "${WGET_OPT}" -q -O- "$BASE_URL" | 
        fgrep -m1 option | 
        cut -f2 -d'"'
    )
    if [[ ! -z $image_url ]]; then
        echo "${IMAGE_BASE_URL}"/"${image_url}"
    fi
}

# reference: https://gist.github.com/alexander-yakushev/5546599
http.get.url.4walled(){
    # board=
    #	1 -- /w/   -- Anime/Wallpapers
    #	2 -- /wg/  -- Wallpapers/General
    #	3 -- 7chan -- 7chan
    #	4 -- /hr/  -- NSFW/High Resolution
    #         --       -- ALL
    local board=
    
    # sfw=
    #	-1 -- unrated
    #	 0 -- Safe for work
    #        1 -- Borderline
    #        2 -- NSFW
    local sfw=0
    
    local URL='http://4walled.cc/search.php?tags=&board'${board}'=&width_aspect=1024x133&searchstyle=larger&sfw='"${sfw}"'&search=random'
    local BASE_URL=$(
        wget "${WGET_OPT}" -q -O- "${URL}" | 
        fgrep -m1 '<li class' | 
        cut -f4 -d"'"
    )
    local image_url=$(
        wget "${WGET_OPT}" -O- -q "${BASE_URL}" | 
	fgrep -m1 'href="http' | 
	cut -f2 -d'"'
    )
    if [[ ! -z $image_url ]]; then
        echo "${image_url}"
    fi
}

# Reference: https://github.com/dmacpherson/py-interfacelift-downloader
http.get.url.interfacelift(){
    local BASE_URL='http://interfacelift.com/wallpaper/downloads/random/fullscreen/1600x1200/'
    local IMAGE_BASE_URL='http://interfacelift.com'
    local image_url=$(
        wget "${WGET_OPT}" --quiet -O - "${BASE_URL}" | 
        egrep -o 'a href="/wallpaper/[[:alnum:]]+/[[:alnum:]_]+.jpg' | 
        cut -f2 -d'"' | 
        shuf -n1
    )
    if [[ ! -z $image_url ]]; then
        echo "${IMAGE_BASE_URL}""${image_url}"
    fi
}

# https://gist.github.com/JoshSchreuder/882666
http.get.url.nasa.apod(){
    local BASE_URL='http://apod.nasa.gov/apod/'
    local IMAGE_BASE_URL=$BASE_URL
    local image_url=$(
        wget "${WGET_OPT}" --quiet -O - "${BASE_URL}" | 
        fgrep -m1 jpg | 
        cut -f2 -d'"'
    )
    if [[ ! -z $image_url ]]; then
        echo "${IMAGE_BASE_URL}""${image_url}"
    fi
}

# https://gist.github.com/JoshSchreuder/882668
http.get.url.natgeo(){
    local BASE_URL='http://photography.nationalgeographic.com/photography/photo-of-the-day/'
    local IMAGE_BASE_URL='images.nationalgeographic.com'
    local image_url=$(
        wget "${WGET_OPT}" --quiet -O - "${BASE_URL}" |  
        egrep -o -m1 "${IMAGE_BASE_URL}"'/.*[0-9]*x[0-9]*.jpg' 
    )
    if [[ ! -z $image_url ]]; then
        echo 'http://'"${image_url}"
    fi
}

http.get.url.nasa.goes(){
    local BASE_URL='http://goes.gsfc.nasa.gov/goescolor/goeseast/overview2/color_lrg'
    local image_url="${BASE_URL}"/latestfull.jpg
    echo "${image_url}"
}

http.get.url.fvalk(){
    local BASE_URL='http://www.fvalk.com/images/Day_image/?M=D'
    local IMAGE_BASE_URL='http://www.fvalk.com/images/Day_image/'
    local dust='GOES-12'
    local image_url=$(
        wget "${WGET_OPT}" --quiet -O - "${BASE_URL}" | 
	grep -m1 "${dust}" | 
	cut -f6 -d'"'
    )
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
# The Content-Encoding returned by this server is not always the same, sometimes returns gzipped data and sometimes in plain text.
# That's why I am using some logic to detect that and "base64" to store the gzip file in a variable.
http.get.url.nasa.iotd(){
    check_in_path 'base64'
    local BASE_URL='http://www.nasa.gov/rss/dyn/lg_image_of_the_day.rss'
    local html_url=$(base64 <(wget "${WGET_OPT}" --quiet -O - --header='Accept-Encoding: gzip' "${BASE_URL}"))
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
while getopts ':hcgiafsmntwbrd' opt; do
    case $opt in
        g) jpg=$(http.get.url.natgeo) ;;
        i) jpg=$(http.get.url.nasa.iotd) ;;
        a) jpg=$(http.get.url.nasa.apod) ;;
        f) jpg=$(http.get.url.fvalk); FEH_OPT='--bg-max' ;;
        s) jpg=$(http.get.url.smn.satopes);;
        c) jpg=$(http.get.url.4walled);;
        m) jpg=$(http.get.url.nrlmry.nexsat);;
        n) jpg=$(http.get.url.nasa.goes); FEH_OPT='--bg-max';;
        t) jpg=$(http.get.url.interfacelift);;
        w) jpg=$(http.get.url.wallbase);;
        b) jpg=$(http.get.url.bing);;
        r) jpg=$(http.get.url.reddit);;
        d) jpg=$(http.get.url.deviantart);;
        h) help.usage;;
        *) echoerr 'uError: option not supported. '; help.usage; exit 1;;
    esac
done

mkdir -p pics # portability
cd pics

# referece: http://blog.yjl.im/2012/03/downloading-only-when-modified-using_23.html
if [[ ! -z $jpg ]]; then
    pic_name=${jpg##*/}
    filename="${PWD}/${pic_name}"
    wget "${WGET_OPT}" "${jpg}" --server-response --timestamping --no-verbose --ignore-length
    DISPLAY=:0.0 feh "${FEH_OPT}" "${filename}"
    echo
    echo 'URL:  '"${jpg}"
    echo 'FILE: '"${filename}"
fi
