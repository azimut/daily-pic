#!/bin/bash

# Used by skymap.* wallpapers and nasa.msfc, default is Buenos Aires
# http://en.wikipedia.org/wiki/List_of_cities_by_latitude
# Negative latitude is south.
# Negative longitude is West.
LONGITUDE='-58'
LATITUDE='-34'
MYTZ='Arg' # needs more testing to know if this should be replaced for other locations

FEH_OPT='--bg-fill'
USER_AGENT='Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/30.0.1599.66 Safari/537.36'

help.usage() {
	cat <<EOF
Usage: $0 [-hacnwmf] <site>

EOF
	help.usage.astronomy
	help.usage.comics
	help.usage.misc
	help.usage.news
	help.usage.nature
	help.usage.weather
}

help.usage.astronomy() {
	cat <<EOF
    -a
        nasa.apod
        nasa.apod.rand
        nasa.iotd
        nasa.jpl
        skymap.astrobot
        skymap.heavensabove
        skymap.astronetru
EOF
}
help.usage.comics() {
	cat <<EOF
    -c
        dilbert
        calvinandhobbes
        eatthattoast
        xkcd
EOF
}
help.usage.misc() {
	cat <<EOF
    -m
        4walled
        interfacelift
        wallhaven
        imgur.albums
        imgur.subreddit
        reddit
        deviantart
        simpledesktops
        fractionmagazine
        yandere
        konachan
EOF
}
help.usage.nature() {
	cat <<EOF
    -n
        bing
        chromecast
        natgeo
        nasa.eo.iotd
EOF
}
help.usage.news() {
	cat <<EOF
    -e
        clarinhd
        euronews
        reuters
EOF
}
help.usage.weather() {
	cat <<EOF
    -w
        latlong.nasa.msfc
        america.smn
        america.nasa.goes
        america.fvalk
        america.s.aw
        america.n.aw
        globe.dienet.mercator
        globe.dienet.peters
        globe.dienet.mollweide
        globe.dienet.rectangular
        arg.smn
        arg.nexsat
EOF
}
# >>>>>>>>>>> helpers

echostep() {
	echo -en '\x1b[34;01m[*]\x1b[39;49;00m '
	echo "$@"
}
echoerr() {
	echo -en '\x1b[31;01m[-]\x1b[39;49;00m ' 1>&2
	echo "$@" 1>&2
}
echoinf() {
	echo -en '\x1b[32;01m[+]\x1b[39;49;00m ' 1>&2
	echo "$@" 1>&2
}
dtitle() {
	echo -en '\x1b[32;01m[+]\x1b[39;49;00m ' 1>&2
	echo "$@" 1>&2
}
dmsg() {
	echo -en '\x1b[32;01m[+]\x1b[39;49;00m ' 1>&2
	echo "$@" 1>&2
}

# >>>>>>>>>>> checking minimum requirements and argument is present

check_in_path() {
	local cmd=$1
	hash "$cmd" &>/dev/null || {
		echoerr "uError: command \"$cmd\" not found in \$PATH, please add it or install it..."
		exit 1
	}
}

check_in_path 'feh'
check_in_path 'curl'
check_in_path 'shuf'
check_in_path 'jq'

python_check_in_path() {
	local module_name="$@"
	python -c 'import '"${module_name}" &>/dev/null || {
		echoerr "uError: python module \"${module_name}\" not installed, please install it with pip or from your distro repositories."
		exit 1
	}
}

[[ $# -eq 0 ]] && {
	echoerr "uError: Missing argument."
	help.usage
}

# >>>>>>>>>>> extra helpers

curlme() {
	local BASE_URL="$1"
	curl -A "${USER_AGENT}" -k -s -o- "${BASE_URL}"
}

xhtml() {
	xmlpath="$1"
	xmllint --html --xpath "${xmlpath}" - 2>/dev/null
}

random() {
	local n="$1"
	echo -n $((n * RANDOM / 32768 + 1))
}
# Description: takes an array as argument and returns a random element
#              a little bit cheap, but it works ...
get.array.rand() {
	echo "$@" | tr ' ' '\n' | shuf -n1
}

# Description: from the list of getopts flags returns a random one with the leading dash '-'
#              it works...
get.flag.rand() {
	local nflag=$((${#GETOPTS_ARGS} * RANDOM / 32768 + 1))
	echo -n '-'
	echo "${GETOPTS_ARGS}" | cut -b"${nflag}"
}

get.date.rand.since() {
	local first_strip_date=$1
	local fs_days_since=$(($(date --date="${first_strip_date}" +%s) / 60 / 60 / 24))

	local today_date=$(date +%F)
	local today_days_since=$(($(date +%s) / 60 / 60 / 24))

	local days_since=$((${today_days_since} - ${fs_days_since}))
	local random_day=$((days_since * RANDOM / 32768 + 1))
	echo $(date --date="$random_day days ago" +%F)
}

# Reference: https://github.com/thomaswsdyer/Julian-Date-Script
#            https://gist.github.com/jiffyclub/1294443
# Description: Gregorian to Reduced|Modified Julian-ish date
#              minutes, seconds and microseconds are NOT calculated
# Usage: f <year> <month> <day> <hour> <gmtoffset>
# Disclaimer: I glued this together the best I could...but still prone to fail
#             please improve it :)

julianDate() {
	jHour=$4
	jDay=$(echo 'scale=5; ('$jHour'/24)' | bc)

	gYear=$1
	gMonth=$2
	gDay=$(echo $3 ' + '$jDay | bc)

	A=$((${gYear} / 100))
	B=$((${A} / 4))
	C=$((2 - ${A} + ${B}))

	D=$(
		echo 'scale=10;( 365.25 * ('"${gYear}"' + 4716 ) )' |
			bc |
			cut -f1 -d'.'
	)

	E=$(
		echo 'scale=10; ( 30.6001 * ('"${gMonth}"' + 1 ) )' |
			bc |
			cut -f1 -d'.'
	)

	jDate=$(echo "scale=5; "'('"${C}+${gDay}+${D}+${E}-1524.5"')' | bc)
	jDate=$(echo 'scale=5; ( '$jDate' - 2400000.5 )' | bc)

	echo "$jDate"
}

# >>>>>>>>>>> cross-wm wallpaper setter

# Reference: http://bazaar.launchpad.net/~peterlevi/variety/trunk/view/head:/data/scripts/set_wallpaper
set.wallpaper() {
	local WP=$1

	# KDE - User will have to manually choose ~/.config/variety/wallpaper-kde.jpg as a wallpaper.
	# Afterwards, with the command below, Variety will just overwrite the file when changing the wallpaper
	# and KDE will refresh it
	if [ "$(env | grep KDE_FULL_SESSION | tail -c +18)" == "true" ]; then
		cp "$WP" ~/.config/variety/wallpaper-kde.jpg
		return 0
	fi

	#    hash gsettings &>/dev/null || \
	#    hash xfconf-query &>/dev/null || \
	DISPLAY=:0.0 feh ${FEH_OPT} "${WP}"
	colors=($(convert "${WP}" -resize %25 \
		-colors 3 \
		-unique-colors txt:- |
		awk '{print $3}' |
		tail -n+2))
	sed --follow-symlinks -i -e 's/^theme.border_normal[[:space:]]*=[[:space:]]*".*".*/theme.border_normal = "'${colors[0]}'"/g' ~/.config/awesome/rc.lua
	sed --follow-symlinks -i -e 's/^theme.border_focus[[:space:]]*=[[:space:]]*".*".*/theme.border_focus = "'${colors[2]}'"/g' ~/.config/awesome/rc.lua

	sed --follow-symlinks -i -e 's/^theme.fg_minimize[[:space:]]*=[[:space:]]*".*".*/theme.fg_minimize = "'${colors[0]}'"/g' ~/.config/awesome/rc.lua
	sed --follow-symlinks -i -e 's/^theme.fg_normal[[:space:]]*=[[:space:]]*".*".*/theme.fg_normal = "'${colors[1]}'"/g' ~/.config/awesome/rc.lua
	sed --follow-symlinks -i -e 's/^theme.fg_focus[[:space:]]*=[[:space:]]*".*".*/theme.fg_focus = "'${colors[2]}'"/g' ~/.config/awesome/rc.lua
	wal -a 60 -c -g -n -i "${WP}"

	# Gnome 3, Unity
	gsettings set org.gnome.desktop.background picture-uri "file://$WP" 2>/dev/null
	gsettings set com.canonical.unity-greeter background "$WP" 2>/dev/null
	if [ "$(gsettings get org.gnome.desktop.background picture-options)" == "'none'" ]; then
		gsettings set org.gnome.desktop.background picture-options 'zoom' 2>/dev/null
	fi

	# XFCE
	xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-path -s "" 2>/dev/null
	xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-path -s "$WP" 2>/dev/null

	# LXDE/PCmanFM
	pcmanfm --set-wallpaper "$WP" 2>/dev/null

	# Feh - commented, as it may cause problems with Nautilus, (see bug https://bugs.launchpad.net/variety/+bug/1047083)
	# feh --bg-scale "$WP" 2> /dev/null

	# MATE after 1.6
	gsettings set org.mate.background picture-filename "$WP" 2>/dev/null

	# MATE before 1.6
	mateconftool-2 -t string -s /desktop/mate/background/picture_filename "$WP" 2>/dev/null

	# Cinnamon after 1.8
	gsettings set org.cinnamon.background picture-uri "file://$WP" 2>/dev/null

	# Cinnamon after 2.0
	gsettings set org.cinnamon.desktop.background picture-uri "file://$WP" 2>/dev/null

	# Gnome 2
	gconftool-2 -t string -s /desktop/gnome/background/picture_filename "$WP" 2>/dev/null

}

# >>>>>>>>>>>
# >>>>>>>>>>> real work is done here, they just return ONE url of an image
# >>>>>>>>>>>

http.get.url.news.reuters() {
	dtitle 'news - reuters'
	python_check_in_path 'BeautifulSoup'
	python_check_in_path 'urllib2'

	python lib/python/news.reuters.py
}

http.get.url.news.euronews() {
	dtitle 'news - euronews - picture of the day'
	python_check_in_path 'BeautifulSoup'
	python_check_in_path 'urllib2'

	python lib/python/news.euronews
}

http.get.url.news.clarinhd() {
	dtitle 'news - clarinhd - picture of the day'
	python_check_in_path 'BeautifulSoup'
	python_check_in_path 'urllib2'

	python lib/python/news.clarinhd
}

http.get.url.nasa.eo.iotd() {
	dtitle 'nasa - earth observatory'
	local BASE_URL='http://earthobservatory.nasa.gov/IOTD/'
	local image_url=$(
		curl -A "${USER_AGENT}" -k -s -o- "${BASE_URL}" |
			fgrep '"lf"' |
			cut -f4 -d '"'
	)
	[[ ! -z $image_url ]] && {
		image_url=${image_url/.jpg/_lrg.jpg}
		echo "$image_url"
	}
}

http.get.url.aw.america() {
	dtitle 'aw - aviation weather '
	check_in_path 'convert'
	local URL=http://aviationweather.gov
	local ARGS=data/obs/sat/intl/ir_ICAO-A.jpg
	echo "${URL}/${ARGS}"
}

http.get.url.america.smn() {
	dtitle 'smn - servicio meteorologico nacional argentino'
	local URL='http://www.smn.gov.ar/vmsr'
	local INDEX_URL=${URL}'/deluxe-tree.js'
	local category=Globo itype=Topes
	local fcategory=globo fitype=tn
	local BASE_URL=$(
		curl -A "${USER_AGENT}" -k -s -o- "${INDEX_URL}" |
			fgrep -A3 $category |
			fgrep $itype |
			cut -f4 -d'"'
	)
	local BASE_URL="${URL}/${BASE_URL}"
	local image_url=$(
		curl -A "${USER_AGENT}" -k -s -o- "${BASE_URL}" |
			egrep -o '[a-z]+[0-9]+\.[0-9]+\.jpg' |
			tail -n1
	)
	[[ ! -z $image_url ]] && {
		echo "${URL}/imagenes/$fcategory/$fitype/${image_url}"
	}
}

# Reference: http://weather.msfc.nasa.gov/GOES/getsatellite.html
http.get.url.nasa.msfc() {
	dtitle 'nasa'
	local URL='http://weather.msfc.nasa.gov'
	local ARGS='cgi-bin/get-goes?satellite=GOES-E%20FULL'\
		'&lat='"$LATITUDE"'&lon='"$LONGITUDE"''\
		'&zoom=2'\
		'&palette=ir6.pal'\
		'&colorbar=0'\
		'&width=1000&height=600'\
		'&quality=100'
	local image_url=$(
		curl -A "${USER_AGENT}" -k -s -o- ${URL}/${ARGS} |
			grep jpg |
			cut -f2 -d'"'
	)
	echo "${URL}${image_url}"
}

# ut = universal time hours. It's actually a floating point number calculated from the minutes and seconds
#      for practical reasons here is a integer

http.get.url.skymap.astronetru() {
	dtitle 'astronet.ru - skymap'
	check_in_path 'date'
	local year=$(date --utc +%Y) month=$(date --utc +%m)
	local day=$(date --utc +%d) hour=$(date --utc +%H)
	local BASE_URL='http://www.astronet.ru:8105'
	local ARGS='cgi-bin/skyc.cgi?'\
		'ut='${hour}'&day='"${day}"'&month='${month}'&year='${year}\
		'&longitude='$((LONGITUDE * (-1)))'&latitude='${LATITUDE} \
		'&azimuth=0&height=90&m=5.0&dgrids=0&dcbnd=0&dfig=1&colstars=0&names=0&xs=800&theme=0&dpl=1&drawmw=1&pdf=0&lang=0'
	echo "${BASE_URL}/${ARGS}"
}

# Refence: http://www.skyandtelescope.com/astronomy-resources/online-star-charts
# size = image size
# SL = Constelations lines
# SN = Constelations names
# BW = Black and White flag
# time = date time in Julian calendary
# ecl = ecliptic line: The ecliptic is the apparent path of the Sun on the celestial sphere, and is the basis for the ecliptic coordinate system.
# cb  = constelation boundaries
http.get.url.skymap.heavenabove() {
	dtitle 'heavenabove - skymap'
	check_in_path 'date'
	check_in_path 'bc'
	local year=$(date --utc +%Y) month=$(date --utc +%m)
	local day=$(date --utc +%d) hour=$(date --utc +%H)
	local size=1000
	local jDate=$(julianDate $year $month $day $hour)
	local BASE_URL='http://www.heavens-above.com/wholeskychart.ashx?'\
		'lat='"${LATITUDE}"'&lng='"${LONGITUDE}"\
		'&loc=Unspecified&alt=79&tz='"${MYTZ}"'&'\
		'size='"${size}"'&'\
		'SL=1&SN=1&'\
		'BW=0&'\
		'time='${jDate}'&'\
		'ecl=1&'\
		'cb=0'

	echo "${BASE_URL}"
}

http.get.url.skymap.astrobot() {
	dtitle 'astrobot - skymap'
	local URL='http://www.astrobot.eu/skymapserver'
	local ARGS='skymap?type=gif&size=1000&colorset=0&lang=en&lat='$LATITUDE'&lon='$LONGITUDE'&timezone=UT&deco=15'
	local image_url=${URL}/${ARGS}
	echo "${image_url}"
}

http.get.url.nasa.jpl() {
	dtitle 'NASA - Jet Propulsion Laboratory'
	local -a category_array
	category_array+=('featured')
	category_array+=('sun')
	category_array+=('mercury')
	category_array+=('venus')
	category_array+=('earth')
	category_array+=('mars')
	category_array+=('jupiter')
	category_array+=('saturn')
	category_array+=('uranus')
	category_array+=('neptune')
	category_array+=('dwarf%20planet')
	category_array+=('asteroids%20and%20comets')
	category_array+=('universe')
	category_array+=('spacecraft%20and%20telescope')

	category=$(get.array.rand ${category_array[@]})

	dmsg 'Category: '"${category}"

	local URL='http://www.jpl.nasa.gov/spaceimages'
	local BASE_URL="${URL}"'/searchwp.php?category='"${category}"
	# step 1: get the number of pages on the category
	local max_page=$(
		curl -A "${USER_AGENT}" -k -s -o- "${BASE_URL}" |
			egrep -o '/spaceimages/searchwp.php\?category='"${category}"'&currentpage=[0-9]+' |
			tail -n1 |
			cut -f3 -d'='
	)
	local rand_page=$((max_page * RANDOM / 32768 + 1))
	local BASE_URL_PAGE=${BASE_URL}'&page='${rand_page}
	# step 2: download a random page from that category
	local PIC_URL=$(
		curl -A "${USER_AGENT}" -k -s -o- "${BASE_URL_PAGE}" |
			egrep -o 'wallpaper.php\?id=[[:alnum:]]+' |
			shuf -n1
	)
	# step 3: get the largest image
	local image_url=$(
		curl -A "${USER_AGENT}" -k -s -o- "${URL}/${PIC_URL}" |
			egrep -o 'images/wallpaper/[[:alnum:]x-]+\.(jpg|png|gif|jpeg)' |
			tail -1
	)
	[[ ! -z $image_url ]] && {
		echo ${URL}/${image_url}
	}
}

http.get.url.calvinandhobbes() {
	dtitle 'calvin and hobbes - comic'
	check_in_path 'date'

	local first_strip_date='1985-11-18'
	local date_strip=$(get.date.rand.since "${first_strip_date}")
	date_strip=${date_strip//-/\/} # fixing formatting

	dmsg 'Date: '"${date_strip}"

	local BASE_URL='http://www.gocomics.com/calvinandhobbes/'"${date_strip}"
	local image_url=$(
		curl -A "${USER_AGENT}" -k -s -o- "${BASE_URL}" |
			grep '"strip"' |
			tr '"' '\n' |
			grep asset
	)
	[[ ! -z $image_url ]] && {
		echo "${image_url}"
	}
}

# Reference: https://github.com/ondrg/dilbert-downloader
http.get.url.dilbert() {
	dtitle 'dilbert - comic'
	check_in_path 'date'

	local first_strip_date='1989-04-16'

	local date_strip=$(get.date.rand.since "${first_strip_date}")

	dmsg 'Date: '"${date_strip}"

	local BASE_URL='http://www.dilbert.com/'"${date_strip}"'/'
	local image_url=$(
		curl -A "${USER_AGENT}" -k -s -o- "${BASE_URL}" |
			grep '.strip.zoom.gif' |
			cut -f2 -d '"'
	)

	local IMAGE_BASE_URL='http://www.dilbert.com'

	[[ ! -z $image_url ]] && {
		echo "${IMAGE_BASE_URL}/${image_url}"
	}
}

http.get.url.eatthattoast() {
	dtitle 'eatthattoast - comic'
	local page=$((3 * RANDOM / 32768 + 1))
	local BASE_URL='http://eatthattoast.com/comic/page/'"${page}"'/'
	local IMAGE_BASE_URL=$(
		curl -A "${USER_AGENT}" -k -s -o- "${BASE_URL}" |
			grep 'Permanent Link' |
			egrep -o 'http://eatthattoast.com/comic/[[:alnum:]_-]+/' |
			shuf -n1
	)
	local image_url=$(
		curl -A "${USER_AGENT}" -k -s -o- "${IMAGE_BASE_URL}" |
			egrep -o 'http://eatthattoast.com/wp-content/uploads/[0-9]+/[0-9]+/[0-9-]+\.(png|gif|jpg|jpeg)'
	)

	[[ ! -z $image_url ]] && {
		echo "${image_url}"
	}
}

# Reference: https://github.com/payoj/imagedownloader
http.get.url.xkcd.rand() {
	dtitle 'xkcd - comic'
	local page=$((1351 * RANDOM / 32768 + 1))
	local BASE_URL='http://xkcd.com/'"${page}"'/'
	local image_url=$(
		curl -A "${USER_AGENT}" -k -s -o- "${BASE_URL}" |
			egrep -o 'http://imgs.xkcd.com/comics/[[:alnum:]_-]+\.(jpg|jpeg|png)' |
			head -1
	)

	[[ ! -z $image_url ]] && {
		echo "${image_url}"
	}
}

# Reference: https://github.com/dconnolly/Chromecast-Backgrounds
http.get.url.chromecast() {
	dtitle 'chromecast - wallpaper'
	local BASE_URL='https://clients3.google.com/cast/chromecast/home/v/c9541b08'
	local image_url="$(
		curl -A "${USER_AGENT}" -k -s -o- "${BASE_URL}" |
			egrep -o 'JSON\.parse[^)]+' |
			tr -d '\\[' |
			cut -f2 -d"'" |
			tr ',' '\n' |
			fgrep 'https' |
			sed -e 's/x22\(.*\)x22/\1/g' |
			fgrep .jpg |
			shuf -n1
	)"

	[[ ! -z $image_url ]] && {
		echo "${image_url}"
	}
}

# Reference: https://github.com/alexgisby/imgur-album-downloader
http.get.url.imgur.albums() {
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
http.get.url.imgur.subreddit() {
	dtitle 'imgur - wallpaper from subreddits'
	local -a BASE_URL_ARRAY
	BASE_URL_ARRAY+=('r/cyberpunk')
	BASE_URL_ARRAY+=('r/wallpapers')
	BASE_URL_ARRAY+=('r/ImaginaryLandscapes+ImaginaryMonsters+ImaginaryCharacters+ImaginaryTechnology')
	BASE_URL_ARRAY+=('r/SpecArt')
	BASE_URL_ARRAY+=('r/glitch_art')

	local BASE_URL=$(get.array.rand ${BASE_URL_ARRAY[@]})
	dmsg 'Category: '"${BASE_URL}"
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

http.get.url.simpledesktops() {
	dtitle 'simpledesktops - minimalistic desktops'
	local page=$((46 * RANDOM / 32768 + 1))
	local BASE_URL='http://simpledesktops.com/browse/'"${page}"'/'
	local image_url=$(
		curl -A "${USER_AGENT}" -k -s -o- "${BASE_URL}" |
			egrep -o 'http://static.simpledesktops.com/uploads/desktops/[0-9]+/[0-9]+/[0-9]+/[[:alnum:]_-]+\.(jpg|png|jpeg)' |
			shuf -n1
	)

	[[ ! -z $image_url ]] && {
		echo "${image_url}"
	}
}

# Reference: https://github.com/andrewhood125/realtime-earth-wallpaper
http.get.url.dienet.world() {
	dtitle 'dienet -  Image of earth'
	local proyection=$1
	local BASE_URL='http://static.die.net/earth/'$proyection
	local image_url="${BASE_URL}"/'1600.jpg'
	echo "${image_url}"
}

# Reference: https://github.com/datagutt/wallscrape
http.get.url.deviantart() {
	dtitle 'deviantart - random wallpaper, from different topics'
	local -a BASE_URL_ARRAY
	BASE_URL_ARRAY+=('http://www.deviantart.com/browse/all/customization/wallpaper/scifi/') # !!
	BASE_URL_ARRAY+=('http://www.deviantart.com/browse/all/customization/wallpaper/3d/')
	BASE_URL_ARRAY+=('http://www.deviantart.com/browse/all/customization/wallpaper/abstract/')
	BASE_URL_ARRAY+=('http://www.deviantart.com/browse/all/customization/wallpaper/fantasy/')
	BASE_URL_ARRAY+=('http://www.deviantart.com/browse/all/customization/wallpaper/fractals/')     # !!
	BASE_URL_ARRAY+=('http://www.deviantart.com/browse/all/customization/wallpaper/widescreen/')   # !!
	BASE_URL_ARRAY+=('http://www.deviantart.com/browse/all/customization/wallpaper/scenery/')      # !!
	BASE_URL_ARRAY+=('http://www.deviantart.com/browse/all/customization/wallpaper/minimalistic/') # !!
	BASE_URL_ARRAY+=('http://www.deviantart.com/browse/all/customization/wallpaper/technical/')    # !!

	local BASE_URL=$(get.array.rand ${BASE_URL_ARRAY[@]})

	local image_url=$(
		curl -A "${USER_AGENT}" -k -s -o- "${BASE_URL}" |
			egrep -o 'data-src="http://[[:alnum:]]+\.deviantart\.net/[[:alnum:]]+/200H/.+/.+/.+/.+/.+/.+\.(png|jpg|jpeg)"' |
			cut -f2 -d'"' |
			shuf -n1
	)
	if [[ ! -z $image_url ]]; then
		image_url=${image_url/200H/}
		echo "${image_url}"
	fi
}

# Reference: https://github.com/wmmc/Wallpaper-Downloader
http.get.url.reddit() {
	dtitle 'reddit - /r/wallpapers'
	curl -A "${USER_AGENT}" -k -s -o- 'https://www.reddit.com/r/wallpapers/.json' |
		jq -r '.data.children[].data.url | select(test("(png|jpg|jpeg)$"))' |
		shuf -n1
}

# Reference: https://github.com/tsia/bing-wallpaper
http.get.url.bing() {
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

http.get.url.wallhaven() {
	dtitle 'wallhaven.cc - random wallpaper, from different topics'

	local -a TAGS
	TAGS+=('outer-space')
	TAGS+=('cyberpunk')
	TAGS+=('fractals')
	TAGS+=('painting')
	TAGS+=('cityscapes')
	TAGS+=('landscapes')
	TAGS+=('subway')
	TAGS+=('lens')
	TAGS+=('macro')
	TAGS+=('leaves')

	BASE_URL='http://alpha.wallhaven.cc/search?q=%23'"$(get.array.rand ${TAGS[@]})"
	BASE_URL="${BASE_URL}"'&categories=111&purity=110&sorting=random&order=desc'

	local image_preview=$(
		curl -A "${USER_AGENT}" -k -s -o- "${BASE_URL[*]}" |
			egrep -o 'alpha.wallhaven.cc/wallpaper/[0-9]+' |
			sort -d |
			uniq |
			shuf -n1
	)

	local image_url=$(
		curl -A "${USER_AGENT}" -k -s -o- "${image_preview}" |
			egrep -o 'wallpapers.wallhaven.cc/wallpapers/full/wallhaven-[0-9]+\.(jpg|png|jpeg)' |
			head -n1
	)

	if [[ ! -z $image_url ]]; then
		echo "${image_url}"
	fi
}

http.get.url.nrlmry.nexsat() {
	dtitle 'nrlmry - Image of earth'
	local region='SouthAmerica'        # NW_Atlantic
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
http.get.url.4walled() {
	dtitle '4walled - random wallpaper'
	# board=
	# 1 -- /w/   -- Anime/Wallpapers
	# 2 -- /wg/  -- Wallpapers/General
	# 3 -- 7chan -- 7chan
	# 4 -- /hr/  -- NSFW/High Resolution
	#         --       -- ALL
	local board=

	# sfw=
	# -1 -- unrated
	#  0 -- Safe for work
	#  1 -- Borderline
	#  2 -- NSFW
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
http.get.url.interfacelift() {
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

http.get.url.nasa.apod.rand() {
	dtitle 'NASA - rand() Astronomy picture of th day'
	local BASE_URL='http://apod.nasa.gov/apod/archivepix.html'
	local BASE_INDEX=$(
		curl -A "${USER_AGENT}" -k -s -o- "${BASE_URL}" |
			egrep -o 'ap[0-9]*\.html' |
			head -n2000 |
			shuf -n1
	)
	local URL='http://apod.nasa.gov/apod'
	local image_url=$(
		curl -A "${USER_AGENT}" -k -s -o- "${URL}"/"${BASE_INDEX}" |
			egrep -m1 'jpg|png|gif' |
			cut -f2 -d'"'
	)
	[[ ! -z $image_url ]] && {
		echo "${URL}"/"${image_url}"
	}
}

# https://gist.github.com/JoshSchreuder/882666
http.get.url.nasa.apod() {
	dtitle 'NASA - Astronomy picture of the day'
	local BASE_URL='http://apod.nasa.gov/apod/'
	local IMAGE_BASE_URL=$BASE_URL
	local image_url=$(
		curl -A "${USER_AGENT}" -k -s -o- "${BASE_URL}" |
			egrep -m1 'jpg|png|gif' |
			cut -f2 -d'"'
	)
	if [[ ! -z $image_url ]]; then
		echo "${IMAGE_BASE_URL}""${image_url}"
	fi
}

# https://gist.github.com/JoshSchreuder/882668
http.get.url.natgeo() {
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

http.get.url.nasa.goes() {
	dtitle 'NASA goes -  Image of earth'
	local BASE_URL='http://goes.gsfc.nasa.gov/goescolor/goeseast/overview2/color_lrg'
	local image_url="${BASE_URL}"/latestfull.jpg
	echo "${image_url}"
}

http.get.url.fvalk() {
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

http.get.url.smn.satopes() {
	dtitle 'SMN - Servicio meteorologico nacional argentino'
	local BASE_URL='http://www.smn.gov.ar/pronos/imagenes'
	local image_url="${BASE_URL}"/satopes.jpg
	#    echo "${image_url}"
	#     echo 'http://www.smn.gov.ar/vmsr/conae/MCidas/LATEST/goes13_imager_LATEST_argentina_shss_b4_ctt.jpg'
	echo 'http://www.smn.gov.ar/vmsr/conae/MCidas/LATEST/goes13_imager_LATEST_argentina_b4_ctt.jpg'
}

# Reference: http://awesome.naquadah.org/wiki/NASA_IOTD_Wallpaper
# The Content-Encoding returned by this server is not always the same, sometimes returns gzipped data and sometimes in plain text.
# That's why I am using some logic to detect that and "base64" to store the gzip file in a variable.
http.get.url.nasa.iotd() {
	dtitle 'NASA Image of the day'
	check_in_path 'base64'
	local BASE_URL='http://www.nasa.gov/rss/dyn/image_of_the_day.rss'
	local html_url=$(base64 <(curl -A "${USER_AGENT}" -k -s -o- --header 'Accept-Encoding: gzip' "${BASE_URL}"))
	local ftype=$(echo "$html_url" | base64 --decode | file -)

	if [[ $ftype == *gzip* ]]; then
		html_url=$(echo "$html_url" | base64 --decode | gunzip -)
	else
		html_url=$(echo "$html_url" | base64 --decode)
	fi

	image_url=$(echo "$html_url" | fgrep -m1 enclosure | cut -f2 -d'"')
	if [[ ! -z $image_url ]]; then
		echo "${image_url}"
	fi
}
http.get.url.fractionmagazine() {
	dtitle 'Japan Fraction Magazine'
	local BASE_URL='http://www.fractionmagazinejapan.com/'
	# step 1: get the japananese index page, aparently change according to the latest issue
	local jpn_index_relpath=$(curl -A "${USER_AGENT}" -k -s -o- "${BASE_URL}" |
		egrep -m1 -o 'jpne/.*/.*.html')
	# step 2: get a random magazine url
	local magazine_relpath=$(curl -A "${USER_AGENT}" -k -s -o- "${BASE_URL}"${jpn_index_relpath} |
		grep '号</a' |
		cut -f2 -d'"' |
		cut -f2,3 -d/ |
		shuf -n 1)
	local magazine_dir=${magazine_relpath%/*}
	# step 3: get the pages on that magazine
	#    local magazine_pages=($( curl -A "${USER_AGENT}" -k -s -o- "${BASE_URL}jpne/${magazine_relpath}"\
	#                             | grep -m1 bdnavi-numbers2 \
	#                             | tr '<' '\n' \
	#                             | grep href \
	#                             | cut -f2 -d'"'))
	#    magazine_pages+=(${magazine_relpath##*/})
	# step 4: select a random page:
	#    local magazine_page=$(get.array.rand ${magazine_pages[@]})
	local magazine_page=${magazine_relpath##*/}
	# step 5: select gallery on the magazine
	local gallery_relpath=$(curl -A "${USER_AGENT}" -k -s -o- "${BASE_URL}"jpne/"${magazine_dir}/${magazine_page}" |
		grep '<p><span class="img"><a' |
		cut -f4 -d'"' |
		shuf -n1)
	# step 6: return photo
	image_url=$(curl -A "${USER_AGENT}" -k -s -o- "${BASE_URL}"jpne/${magazine_dir}/${gallery_relpath} |
		grep '^<span class="img">' |
		cut -f4 -d'"' |
		cut -f3- -d/ |
		shuf -n1)

	if [[ ! -z $image_url ]]; then
		echo "${BASE_URL}""${image_url}"
	fi
}
http.get.url.yandere() {
	dtitle 'yandere - landscapes'
	local page=$((20 * RANDOM / 32768 + 1))
	local BASE_URL='https://yande.re/post.xml?limit=50&tags=landscape&page='${page}
	local image_url="$(curl -A "${USER_AGENT}" "${BASE_URL}" -k -s -o- | grep 'post id' | cut -f42 -d'"' | shuf -n1)"
	echo "${image_url}"
}
http.get.url.theanimegallery() {
	dtitle 'The Anime List'
	local domain='www.theanimegallery.com'
	# local url='http://'${domain}'/gallery/category:screenshots'
	# local lastpage=$( curlme "${url}" \
	#                       | xhtml '//a[@class="paging"][last()]/@href' \
	#                       | tr -cd '[0-9]' )
	local rpage=$(random 209)
	local rurl='http://'${domain}'/gallery/category:screenshots/page:'${rpage}
	local purl=$(curlme $rurl |
		xhtml '//div[@class="thumbimage"]/a/@href' |
		tr ' ' '\n' |
		grep href |
		cut -f2 -d'"' |
		shuf -n1 |
		sed 's#.*image:\([0-9]*\).*#\1#g')
	# http://www.theanimegallery.com/download/image:183887
	local purl='http://'${domain}
	#    local purl='http://'${domain}${purl}
	#    local iurl='http://'${domain}$(curlme $purl | xhtml '//div[@class="download"]/a/@href' | cut -f2 -d'"')
	echo "$purl"
}
http.get.url.konachan() {
	dtitle 'konachan - scenic'
	local page=$((20 * RANDOM / 32768 + 1))
	local BASE_URL='https://konachan.com/post.xml?limit=50&tags=scenic&page='${page}
	local image_url="$(curl -A "${USER_AGENT}" "${BASE_URL}" -k -s -o- | grep 'post actual' | cut -f58 -d'"' | shuf -n1)"
	echo "${image_url}"
}
# stop here if we are being sourced
[[ "${BASH_SOURCE[0]}" != "${0}" ]] && return 0

# >>>>>>>>>>> switch-board of flags

while getopts ':hn:a:c:w:m:e:' opt; do
	case $opt in
	m)
		case $OPTARG in
		4walled)
			jpg=$(http.get.url.4walled)
			;;
		interfacelift)
			jpg=$(http.get.url.interfacelift)
			;;
		wallhaven)
			jpg=$(http.get.url.wallhaven)
			;;
		deviantart)
			jpg=$(http.get.url.deviantart)
			;;
		reddit)
			jpg=$(http.get.url.reddit)
			;;
		imgur.subreddit)
			jpg=$(http.get.url.imgur.subreddit)
			;;
		imgur.albums)
			jpg=$(http.get.url.imgur.albums)
			;;
		simpledesktops)
			jpg=$(http.get.url.simpledesktops)
			;;
		theanimegallery)
			jpg=$(http.get.url.theanimegallery)
			;;
		fractionmagazine)
			jpg=$(http.get.url.fractionmagazine)
			;;
		yandere)
			jpg=$(http.get.url.yandere)
			;;
		konachan)
			jpg=$(http.get.url.konachan)
			;;
		*)
			help.usage.misc
			exit 1
			;;
		esac
		;;
	w)
		case $OPTARG in
		arg.smn)
			jpg=$(http.get.url.smn.satopes)
			;;
		america.smn)
			jpg=$(http.get.url.america.smn)
			FEH_OPT='--bg-max'
			CONVERT_OPT=(-stroke black -strokewidth 50 -draw "line 0,0 1000,0")
			;;
		america.s.aw)
			jpg=$(http.get.url.aw.america)
			CONVERT_OPT=(-gravity south -crop 100%x50% +repage)
			;;
		america.n.aw)
			jpg=$(http.get.url.aw.america)
			CONVERT_OPT=(-gravity north -crop 100%x50% +repage)
			;;
		america.nasa.goes)
			jpg=$(http.get.url.nasa.goes)
			FEH_OPT='--bg-max'
			;;
		latlong.nasa.msfc)
			jpg="$(http.get.url.nasa.msfc)"
			;;
		globe.dienet.mercator)
			jpg=$(http.get.url.dienet.world 'mercator')
			;;
		globe.dienet.peters)
			jpg=$(http.get.url.dienet.world 'peters')
			;;
		globe.dienet.rectangular)
			jpg=$(http.get.url.dienet.world 'rectangular')
			;;
		globe.dienet.mollweide)
			jpg=$(http.get.url.dienet.world 'mollweide')
			;;
		arg.nexsat)
			jpg="$(http.get.url.nrlmry.nexsat)"
			;;
		america.fvalk)
			jpg=$(http.get.url.fvalk)
			FEH_OPT='--bg-max'
			;;
		*)
			help.usage.weather
			exit 1
			;;
		esac
		;;
	n)
		case $OPTARG in
		natgeo)
			jpg=$(http.get.url.natgeo)
			;;
		bing)
			jpg=$(http.get.url.bing)
			;;
		chromecast)
			jpg=$(http.get.url.chromecast)
			;;
		nasa.eo.iotd)
			jpg=$(http.get.url.nasa.eo.iotd)
			;;
		*)
			help.usage.nature
			exit 1
			;;
		esac
		;;
	e)
		case $OPTARG in
		clarinhd)
			jpg=$(http.get.url.news.clarinhd)
			;;
		euronews)
			jpg=$(http.get.url.news.euronews)
			;;
		reuters)
			jpg=$(http.get.url.news.reuters)
			;;
		*)
			help.usage.news
			exit 1
			;;
		esac
		;;
	c)
		case $OPTARG in
		dilbert)
			jpg=$(http.get.url.dilbert)
			FEH_OPT='--bg-center --image-bg black'
			;;
		calvinandhobbes)
			jpg=$(http.get.url.calvinandhobbes)
			FEH_OPT='--bg-center --image-bg black'
			;;
		eatthattoast)
			jpg=$(http.get.url.eatthattoast)
			FEH_OPT='--bg-center --image-bg black'
			;;
		xkcd)
			jpg=$(http.get.url.xkcd.rand)
			FEH_OPT='--bg-center --image-bg black'
			;;
		*)
			help.usage.comics
			exit 1
			;;
		esac
		;;
	a)
		case $OPTARG in
		nasa.iotd)
			jpg=$(http.get.url.nasa.iotd)
			;;
		nasa.apod)
			jpg=$(http.get.url.nasa.apod)
			;;
		nasa.apod.rand)
			jpg=$(http.get.url.nasa.apod.rand)
			;;
		nasa.jpl)
			jpg=$(http.get.url.nasa.jpl)
			;;
		skymap.astrobot)
			jpg=$(http.get.url.skymap.astrobot)
			FEH_OPT='--bg-max --image-bg black'
			CONVERT_OPT=(-stroke black -strokewidth 50)
			CONVERT_OPT+=(-draw "line 0,0 250,0" -draw "line 750,0 1000,0")
			CONVERT_OPT+=(-draw "line 0,1000 250,1000" -draw "line 750,1000 1000,1000")
			;;
		skymap.heavensabove)
			jpg=$(http.get.url.skymap.heavenabove)
			;;
		skymap.astronetru)
			FEH_OPT='--bg-max --image-bg black'
			;;
		*)
			help.usage.astronomy
			exit 1
			;;
		esac
		;;
	\?)
		help.usage
		exit 1
		;;
	h)
		help.usage
		exit 1
		;;
	:)
		case $OPTARG in
		a)
			help.usage.astronomy
			exit 1
			;;
		e)
			help.usage.news
			exit 1
			;;
		w)
			help.usage.weather
			exit 1
			;;
		c)
			help.usage.comics
			exit 1
			;;
		m)
			help.usage.misc
			exit 1
			;;
		n)
			help.usage.nature
			exit 1
			;;
		esac
		;;
	esac
done

# >>>>>>>>>>> setting up the env

mkdir -p pics # portability
cd pics

# >>>>>>>>>>> Dowload the image AND set it as wallpaper

# DOWNLOAD IMAGE
if [[ ! -z $jpg ]]; then
	pic_name=${jpg##*/}
	filename="${PWD}/${pic_name}"

	echostep 'Downloading image...'
	# Reference: http://blog.yjl.im/2012/03/downloading-only-when-modified-using.html
	curl -A "${USER_AGENT}" -k --dump-header - "${jpg}" -z "${filename}" -o "${filename}" -s -L 2>/dev/null

	# Apply convert filter to downloaded image
	[[ ! -z $CONVERT_OPT ]] && hash convert &>/dev/null && {
		original_image="$filename"
		filename="${PWD}"'/wp.png'
		echostep 'Applying convert filter to image...'
		convert "${original_image}" "${CONVERT_OPT[@]}" $filename
	}
fi

if [[ ! -z $filename ]]; then
	echostep 'Setting wallpaper...'
	set.wallpaper "${filename}"
	ln -sf "${filename}" $HOME/wallpaper.jpg
	[[ ! -z $jpg ]] && echo 'URL:  '"${jpg}"
	if [[ ! -z $pic_name ]]; then
		echo 'FILE: '$PWD/"${pic_name}"
	else
		echo 'FILE: '$filename
	fi
fi
