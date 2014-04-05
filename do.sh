#!/bin/bash

FEH_OPT='--bg-fill'
WGET_OPT='--user-agent=Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/30.0.1599.66 Safari/537.36'
USER_AGENT='Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/30.0.1599.66 Safari/537.36'
GETOPTS_ARGS='ecgiafsmntwbrdoulz'


help.usage(){
    cat <<EOF
Usage: $0 [-h${GETOPTS_ARGS}]
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
   -e reddit (wallpaper/imgur)
   -d deviantart (rand/24h)
   -o world dienet
   -u imgur subreddit
   -l imgur albums
   -z chromecast wallpaper
   -r random!
EOF
}

echoerr() { echo "$@" 1>&2; }
dtitle()  { echo -en '# '"$@"'\n\n' 1>&2; }

check_in_path(){
    local cmd=$1
    hash "$cmd" &>/dev/null || {
        echoerr "uError: command \"$cmd\" not found in \$PATH, please add it or install it..."
        exit 1
    }
}

check_in_path 'feh'
check_in_path 'curl'
check_in_path 'shuf'

[[ $# -ne 1 ]] && { 
    echoerr "uError: Missing argument."
    help.usage
    exit 1
}

# Description: takes an array as argument and returns a random element
#              a little bit cheap, but it works ...
get.array.rand(){
    echo "$@" | tr ' ' '\n' | shuf -n1
}

# Description: from the list of getopts flags returns a random one with the leading dash '-'
#              it works...
get.flag.rand(){
      local nflag=$(( ${#GETOPTS_ARGS} * RANDOM / 32768 + 1))
      echo -n '-'; echo "${GETOPTS_ARGS}" | cut -b"${nflag}"
}

# Reference: https://github.com/dconnolly/Chromecast-Backgrounds
http.get.url.chromecast(){
    dtitle 'chromecast - wallpaper'
    local BASE_URL='https://clients3.google.com/cast/chromecast/home/v/c9541b08'
    local image_url=$(
        curl -A "${USER_AGENT}" -k -s -o- "${BASE_URL}" | 
        egrep -o 'JSON\.parse[^)]+' |
        tr -d '\\' |
        cut -f2 -d"'" |
        tr ',' '\n' |
        grep https |
        shuf -n1
    )

    [[ ! -z $image_url ]] && {
        image_url=${image_url:3}
        image_url=${image_url:0:-3}
        echo "${image_url}"
    }
}

# Reference: https://github.com/alexgisby/imgur-album-downloader
http.get.url.imgur.albums(){
    dtitle 'imgur - wallpaper from a list of albums'
    local -a BASE_URL_ARRAY
    BASE_URL_ARRAY+=('a/vU7KC') # cyberpunk
    BASE_URL_ARRAY+=('a/kknsQ') # wallpaper collection

    local BASE_URL=$(get.array.rand ${BASE_URL_ARRAY[@]})
    
    BASE_URL='http://imgur.com/'"${BASE_URL}"'/noscript'
    
    local image_url=$(
        curl -A "${USER_AGENT}" -k -s -o- "${BASE_URL}" | 
        egrep -o '"//i\.imgur.com/[[:alnum:]]+\.(jpg|png|jpeg)' | 
        cut -f3- -d/ | 
        shuf -n1
    )

    [[ ! -z $image_url ]] && {
        echo 'http://'"${image_url}"
    }
}


# Reference: https://gist.github.com/Skylark95/5970915
http.get.url.imgur.subreddit(){
    dtitle 'imgur - wallpaper from subreddits'
    local -a BASE_URL_ARRAY
    BASE_URL_ARRAY+=('r/cyberpunk')
    BASE_URL_ARRAY+=('r/wallpapers')

    local BASE_URL=$(get.array.rand ${BASE_URL_ARRAY[@]})
    local page=$((10 * RANDOM / 32768 + 1))
    
    BASE_URL='https://api.imgur.com/3/gallery/'"${BASE_URL}"'/time/'"${page}"'/images.xml'

    local ak='1b138bce405b2e0'
   
    local image_url=$(
        curl -A "${USER_AGENT}" -k -s -o- --header 'Authorization: Client-ID '"${ak}" "${BASE_URL}" |
        egrep -o 'http://i\.imgur.com/[[:alnum:]]+\.(jpg|png|jpeg)' |
        shuf -n1
    )

    [[ ! -z $image_url ]] && {
        echo "${image_url}"
    }
}

# Reference: https://github.com/andrewhood125/realtime-earth-wallpaper
http.get.url.dienet.world(){
    dtitle 'dienet -  Image of earth'
    local BASE_URL='http://static.die.net/earth/mercator'
    local image_url="${BASE_URL}"/'1600.jpg'
    echo "${image_url}"
}

# Reference: https://github.com/datagutt/wallscrape
http.get.url.deviantart(){
    dtitle 'deviantart - random wallpaper, from different topics'
    local -a BASE_URL_ARRAY
    BASE_URL_ARRAY+=('http://www.deviantart.com/customization/wallpaper/scifi/')        # !!
    BASE_URL_ARRAY+=('http://www.deviantart.com/customization/wallpaper/3d/')
    BASE_URL_ARRAY+=('http://www.deviantart.com/customization/wallpaper/abstract/')
    BASE_URL_ARRAY+=('http://www.deviantart.com/customization/wallpaper/fantasy/')
    BASE_URL_ARRAY+=('http://www.deviantart.com/customization/wallpaper/fractals/')     # !!
    BASE_URL_ARRAY+=('http://www.deviantart.com/customization/wallpaper/widescreen/')   # !!
    BASE_URL_ARRAY+=('http://www.deviantart.com/customization/wallpaper/scenery/')      # !!
    BASE_URL_ARRAY+=('http://www.deviantart.com/customization/wallpaper/minimalistic/') # !!
    BASE_URL_ARRAY+=('http://www.deviantart.com/customization/wallpaper/technical/')    # !!

    local BASE_URL=$(get.array.rand ${BASE_URL_ARRAY[@]})

    local image_url=$(
        curl -A "${USER_AGENT}" -k -s -o- "${BASE_URL}" | 
        egrep -o 'data-src="http://[[:alnum:]]+\.deviantart\.net/[[:alnum:]]+/200H/.+/.+/.+/.+/.+/.+\.(png|jpg|jpeg)"' | 
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
    dtitle 'reddit - /r/wallpapers'
    local BASE_URL='http://www.reddit.com/r/wallpapers/.json'
    local image_url=$(
        curl -A "${USER_AGENT}" -k -s -o- "${BASE_URL}" | 
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
    dtitle 'bing -  image of the day'
    local BASE_URL='http://www.bing.com/HPImageArchive.aspx?format=js&n=1&pid=hp&video=0'
    local IMAGE_BASE_URL='http://www.bing.com'
    local image_url=$(
        curl -A "${USER_AGENT}" -k -s -o- "${BASE_URL}" | 
	    sed -E 's/.*"url":"([^"]+)"[,\}].*/\1/g' 
    )
    if [[ ! -z ${image_url} ]]; then
        echo "${IMAGE_BASE_URL}""${image_url}"
    fi
}

# https://github.com/jabbalaci/Wallpaper-Downloader-and-Rotator-for-Gnome
http.get.url.wallbase(){
    dtitle 'wallbase.cc - random wallpaper, from different topics'
    local -a BASE_URL_ARRAY
    #BASE_URL_ARRAY+=('http://wallbase.cc/random')
    BASE_URL_ARRAY+=('http://wallbase.cc/search?tag=8135')  # outer-space
    BASE_URL_ARRAY+=('http://wallbase.cc/search?tag=11544') # cyberpunk
    BASE_URL_ARRAY+=('http://wallbase.cc/search?tag=41408') # mandelbrot
    BASE_URL_ARRAY+=('http://wallbase.cc/search?tag=17756') # historic
    BASE_URL_ARRAY+=('http://wallbase.cc/search?tag=12637') # maps
    BASE_URL_ARRAY+=('http://wallbase.cc/search?tag=20118') # manga
    BASE_URL_ARRAY+=('http://wallbase.cc/search?tag=8383')  # dc comics
    BASE_URL_ARRAY+=('http://wallbase.cc/search?tag=44153') # vertigo comics
    BASE_URL_ARRAY+=('http://wallbase.cc/search?tag=8208')  # cityscapes
    BASE_URL_ARRAY+=('http://wallbase.cc/search?tag=8023')  # landscapes

    local BASE_URL=$(get.array.rand ${BASE_URL_ARRAY[@]})

    local image_url=$(
        curl -A "${USER_AGENT}" -k -s -o- "${BASE_URL}" | 
	    egrep -o 'http://thumbs.wallbase.cc//[[:alpha:]-]+/thumb-[0-9]+.(jpg|png|jpeg)' | 
	    shuf -n1
    )
    image_url=${image_url/thumb-/wallpaper-}
    image_url=${image_url/thumbs/wallpapers}
    if [[ ! -z $image_url ]]; then
        echo "${image_url}"
    fi
}

http.get.url.nrlmry.nexsat(){
    dtitle 'nrlmry - Image of earth'
    local region='SouthAmerica' # NW_Atlantic
    local path='SouthAmerica/Overview' # NW_Atlantic/Caribbean
    local BASE_URL='http://www.nrlmry.navy.mil/nexsat-bin/nexsat.cgi?BASIN=CONUS&SUB_BASIN=focus_regions&AGE=Archive&REGION='"${region}"'&SECTOR=Overview&PRODUCT=vis_ir_background&SUB_PRODUCT=goes&PAGETYPE=static&DISPLAY=single&SIZE=Thumb&PATH='"${path}"'/vis_ir_background/goes&&buttonPressed=Archive'
    local IMAGE_BASE_URL='http://www.nrlmry.navy.mil/htdocs_dyn_apache/PUBLIC/nexsat/thumbs/full_size/'"${path}"'/vis_ir_background/goes/'
    local image_url=$(
        curl -A "${USER_AGENT}" -k -s -o- "$BASE_URL" | 
        fgrep -m1 option | 
        cut -f2 -d'"'
    )
    if [[ ! -z $image_url ]]; then
        echo "${IMAGE_BASE_URL}"/"${image_url}"
    fi
}

# reference: https://gist.github.com/alexander-yakushev/5546599
http.get.url.4walled(){
    dtitle '4walled - random wallpaper'
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
    #    1 -- Borderline
    #    2 -- NSFW
    local sfw=0
    
    local URL='http://4walled.cc/search.php?tags=&board'${board}'=&width_aspect=1024x133&searchstyle=larger&sfw='"${sfw}"'&search=random'
    local BASE_URL=$(
        curl -A "${USER_AGENT}" -k -s -o- "${URL}" | 
        fgrep -m1 '<li class' | 
        cut -f4 -d"'"
    )
    local image_url=$(
        curl -A "${USER_AGENT}" -k -s -o- "${BASE_URL}" | 
	fgrep -m1 'href="http' | 
	cut -f2 -d'"'
    )
    if [[ ! -z $image_url ]]; then
        echo "${image_url}"
    fi
}

# Reference: https://github.com/dmacpherson/py-interfacelift-downloader
http.get.url.interfacelift(){
    dtitle 'Interfacelift -  random wallpaper'
    local BASE_URL='http://interfacelift.com/wallpaper/downloads/random/fullscreen/1600x1200/'
    local IMAGE_BASE_URL='http://interfacelift.com'
    local image_url=$(
        curl -A "${USER_AGENT}" -k -s -o- "${BASE_URL}" | 
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
    dtitle 'NASA - Astronomy picture of the day'
    local BASE_URL='http://apod.nasa.gov/apod/'
    local IMAGE_BASE_URL=$BASE_URL
    local image_url=$(
        curl -A "${USER_AGENT}" -k -s -o- "${BASE_URL}" | 
        fgrep -m1 jpg | 
        cut -f2 -d'"'
    )
    if [[ ! -z $image_url ]]; then
        echo "${IMAGE_BASE_URL}""${image_url}"
    fi
}

# https://gist.github.com/JoshSchreuder/882668
http.get.url.natgeo(){
    dtitle 'Natgeo - Photo of the day'
    local BASE_URL='http://photography.nationalgeographic.com/photography/photo-of-the-day/'
    local IMAGE_BASE_URL='images.nationalgeographic.com'
    local image_url=$(
        curl -A "${USER_AGENT}" -k -s -o- "${BASE_URL}" |  
        egrep -o -m1 "${IMAGE_BASE_URL}"'/.*[0-9]*x[0-9]*.jpg' 
    )
    if [[ ! -z $image_url ]]; then
        echo 'http://'"${image_url}"
    fi
}

http.get.url.nasa.goes(){
    dtitle 'NASA goes -  Image of earth'
    local BASE_URL='http://goes.gsfc.nasa.gov/goescolor/goeseast/overview2/color_lrg'
    local image_url="${BASE_URL}"/latestfull.jpg
    echo "${image_url}"
}

http.get.url.fvalk(){
    dtitle 'FVALK - Image of earth'
    local BASE_URL='http://www.fvalk.com/images/Day_image/?M=D'
    local IMAGE_BASE_URL='http://www.fvalk.com/images/Day_image/'
    local dust='GOES-12'
    local image_url=$(
        curl -A "${USER_AGENT}" -k -s -o- "${BASE_URL}" | 
    	grep -m1 "${dust}" | 
	    cut -f6 -d'"'
    )
    if [[ ! -z $image_url ]]; then
        echo "${IMAGE_BASE_URL}""${image_url}"
    fi
}

http.get.url.smn.satopes(){
    dtitle 'SMN - Servicio meteorologico nacional argentino'
    local BASE_URL='http://www.smn.gov.ar/pronos/imagenes'
    local image_url="${BASE_URL}"/satopes.jpg
    echo "${image_url}"
}

# Reference: http://awesome.naquadah.org/wiki/NASA_IOTD_Wallpaper
# The Content-Encoding returned by this server is not always the same, sometimes returns gzipped data and sometimes in plain text.
# That's why I am using some logic to detect that and "base64" to store the gzip file in a variable.
http.get.url.nasa.iotd(){
    dtitle 'NASA Image of the day'
    check_in_path 'base64'
    local BASE_URL='http://www.nasa.gov/rss/dyn/lg_image_of_the_day.rss'
    local html_url=$(base64 <(curl -A "${USER_AGENT}" -k -s -o- --header 'Accept-Encoding: gzip' "${BASE_URL}"))
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
while getopts ':h'"${GETOPTS_ARGS}" opt; do
    case $opt in
        g) jpg=$(http.get.url.natgeo) ;;
        i) jpg=$(http.get.url.nasa.iotd) ;;
        a) jpg=$(http.get.url.nasa.apod) ;;
        n) jpg=$(http.get.url.nasa.goes); FEH_OPT='--bg-max';;
        f) jpg=$(http.get.url.fvalk); FEH_OPT='--bg-max' ;;
        o) jpg=$(http.get.url.dienet.world);;
        s) jpg=$(http.get.url.smn.satopes);;
        m) jpg=$(http.get.url.nrlmry.nexsat);;
        c) jpg=$(http.get.url.4walled);;
        t) jpg=$(http.get.url.interfacelift);;
        w) jpg=$(http.get.url.wallbase);;
        b) jpg=$(http.get.url.bing);;
        d) jpg=$(http.get.url.deviantart);;
        e) jpg=$(http.get.url.reddit);;
        u) jpg=$(http.get.url.imgur.subreddit);;
        l) jpg=$(http.get.url.imgur.albums);;
        z) jpg=$(http.get.url.chromecast);;
        r) ((OPTIND--)); set -- $(get.flag.rand);;
        h) help.usage;;
        *) echoerr 'uError: option not supported. '; help.usage; exit 1;;
    esac
done

mkdir -p pics # portability
cd pics

# referece: http://blog.yjl.im/2012/03/downloading-only-when-modified-using_23.html
#           http://blog.yjl.im/2012/03/downloading-only-when-modified-using.html
if [[ ! -z $jpg ]]; then
    pic_name=${jpg##*/}
    filename="${PWD}/${pic_name}"
    
    curl -A "${USER_AGENT}" -k --dump-header - "${jpg}" -z "${filename}" -o "${filename}" -s -L 2>/dev/null
    
    if hash gnome-session &>/dev/null; then
        check_in_path 'gsettings'
        gsettings set org.gnome.desktop.background picture-uri file://"${filename}"
    elif hash gnome-about &>/dev/null; then
        check_in_path 'gconftool-2'
        gconftool-2 -t str --set /desktop/gnome/background/picture_filename "${filename}"
        gconftool-2 -t str --set /desktop/gnome/background/picture_options "scaled"
    fi

    DISPLAY=:0.0 feh "${FEH_OPT}" "${filename}"
    
    echo 'URL:  '"${jpg}"
    echo 'FILE: '"${filename}"
fi
