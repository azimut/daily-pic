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

# used by flashcards, make sure it's installed or change it to one of your prefference
FONT_PATH='/usr/share/fonts/TTF/sazanami-gothic.ttf'

help.usage(){
    cat <<EOF
Usage: $0 [-hacnwmf] <site>

EOF
    help.usage.astronomy
    help.usage.comics
    help.usage.flashcards
    help.usage.misc
    help.usage.nature
    help.usage.weather
}

help.usage.flashcards(){
    cat <<EOF
    -f
        hiragana
        katakana
        kanji
        goterms
EOF
}

help.usage.astronomy(){
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
help.usage.comics(){
    cat <<EOF
    -c
        dilbert
        calvinandhobbes
        eatthattoast
        xkcd
EOF
}
help.usage.misc(){
    cat <<EOF
    -m
        4walled
        interfacelift
        wallbase
        imgur.albums
        imgur.subreddit
        reddit
        deviantart
        simpledesktops
EOF
}
help.usage.nature(){
    cat <<EOF
    -n 
        bing
        chromecast
        natgeo
        nasa.eo.iotd
EOF
}
help.usage.weather(){
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

echoerr() { echo "$@" 1>&2; }
dtitle()  { echo -en '# '"$@"'\n\n' 1>&2; }
dmsg()  { echo -en '- '"$@"'\n\n' 1>&2; }

# >>>>>>>>>>> checking minimum requirements and argument is present

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

[[ $# -eq 0 ]] && { 
    echoerr "uError: Missing argument."
    help.usage
    exit 1
}


# >>>>>>>>>>> extra helpers

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

get.date.rand.since(){
    local first_strip_date=$1
    local fs_days_since=$(( $(date --date="${first_strip_date}" +%s) / 60 / 60 / 24 ))
     
    local today_date=$(date +%F)
    local today_days_since=$(( $(date +%s) / 60 / 60 / 24 ))
     
    local days_since=$(( ${today_days_since} - ${fs_days_since} ))
    local random_day=$(( days_since * RANDOM / 32768 + 1 ))
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
    jDay=$( echo 'scale=5; ('$jHour'/24)' | bc)
    
    gYear=$1
    gMonth=$2
    gDay=$( echo $3 ' + '$jDay | bc)

    A=$(( ${gYear} / 100 ))
    B=$(( ${A} / 4 ))
    C=$(( 2 - ${A} + ${B} ))

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
set.wallpaper(){
    local WP=$1

    # KDE - User will have to manually choose ~/.config/variety/wallpaper-kde.jpg as a wallpaper.
    # Afterwards, with the command below, Variety will just overwrite the file when changing the wallpaper
    # and KDE will refresh it
    if [ "`env | grep KDE_FULL_SESSION | tail -c +18`" == "true" ]; then
        cp "$WP" ~/.config/variety/wallpaper-kde.jpg
        return 0
    fi
    
#    hash gsettings &>/dev/null || \
#    hash xfconf-query &>/dev/null || \
    DISPLAY=:0.0 feh ${FEH_OPT} "${WP}"

    # Gnome 3, Unity
    gsettings set org.gnome.desktop.background picture-uri "file://$WP" 2> /dev/null
    gsettings set com.canonical.unity-greeter background "$WP" 2>/dev/null
    if [ "`gsettings get org.gnome.desktop.background picture-options`" == "'none'" ]; then
        gsettings set org.gnome.desktop.background picture-options 'zoom' 2>/dev/null
    fi
    
    # XFCE
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-path -s "" 2> /dev/null
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-path -s "$WP" 2> /dev/null
    
    # LXDE/PCmanFM
    pcmanfm --set-wallpaper "$WP" 2> /dev/null
    
    # Feh - commented, as it may cause problems with Nautilus, (see bug https://bugs.launchpad.net/variety/+bug/1047083)
    # feh --bg-scale "$WP" 2> /dev/null
    
    # MATE after 1.6
    gsettings set org.mate.background picture-filename "$WP" 2> /dev/null
    
    # MATE before 1.6
    mateconftool-2 -t string -s /desktop/mate/background/picture_filename "$WP" 2> /dev/null
    
    # Cinnamon after 1.8
    gsettings set org.cinnamon.background picture-uri "file://$WP" 2> /dev/null
    
    # Cinnamon after 2.0
    gsettings set org.cinnamon.desktop.background picture-uri "file://$WP" 2> /dev/null
    
    # Gnome 2
    gconftool-2 -t string -s /desktop/gnome/background/picture_filename "$WP" 2> /dev/null

}


# >>>>>>>>>>>
# >>>>>>>>>>> real work is done here, they just return ONE url of an image
# >>>>>>>>>>>

# Reference: https://github.com/taeram/zen-wallpaper
#            for a simple version of flashcards look at:
#            http://github.com/azimut/scripts/scripts/

# Reference: http://symbolcodes.tlt.psu.edu/bylanguage/japanesecharthiragana.html
flashcard.hiragana(){
    dtitle 'flashcard - hiragana'
    check_in_path 'convert'
    declare -A hiragana
    hiragana=(
        [あ]='a'  [い]='i'  [う]='u'  [え]='e'  [お]='o'
        [か]='ka' [き]='ki' [く]='ku' [け]='ke' [こ]='ko'
        [が]='ga' [ぎ]='gi' [ぐ]='gu' [げ]='ge' [ご]='go'
        [さ]='sa' [し]='si' [す]='su' [せ]='se' [そ]='so'
        [ざ]='za' [じ]='zi' [ず]='zu' [ぜ]='ze' [ぞ]='zo'
        [た]='ta' [ち]='ti' [つ]='tu' [て]='te' [と]='to'
        [だ]='da' [ぢ]='di' [づ]='du' [で]='de' [ど]='do'
        [な]='na' [に]='ni' [ぬ]='nu' [ね]='ne' [の]='no'
        [は]='ha' [ひ]='hi' [ふ]='hu' [へ]='he' [ほ]='ho'
        [ば]='ba' [び]='bi' [ぶ]='bu' [べ]='be' [ぼ]='bo'
        [ぱ]='pa' [ぴ]='pi' [ぷ]='pu' [ぺ]='pe' [ぽ]='po'
        [ま]='ma' [み]='mi' [む]='mu' [め]='me' [も]='mo'
        [や]='ya'           [ゆ]='yu'           [よ]='yo'
        [ら]='ra' [り]='ri' [る]='ru' [れ]='re' [ろ]='ro'
        [わ]='wa' [ゐ]='wi'           [ゑ]='we' [を]='wo'
        [ん]='n'
        [ゔ]='vu'
    )
    rand_char=$(echo ${!hiragana[@]} | tr ' ' '\n' | shuf -n1)
    rand_desc=${hiragana[$rand_char]}
    echo "${rand_char}"'@'"${rand_desc}"
}

# Reference: http://symbolcodes.tlt.psu.edu/bylanguage/japanesechartkatakana.html
flashcard.katakana(){
    dtitle 'flashcard - katakana'
    check_in_path 'convert'
    declare -A katakana
    katakana=(
        [ア]='a'  [イ]='i'  [ウ]='u'  [エ]='e'  [オ]='o'
        [カ]='ka' [キ]='ki' [ク]='ku' [ケ]='ke' [コ]='ko'
        [ガ]='ga' [ギ]='gi' [グ]='gu' [ゲ]='ge' [ゴ]='go'
        [サ]='sa' [シ]='si' [ス]='su' [セ]='se' [ソ]='so'
        [ザ]='za' [ジ]='zi' [ズ]='zu' [ゼ]='ze' [ゾ]='zo'
        [タ]='ta' [チ]='ti' [ツ]='tu' [テ]='te' [ト]='to'
        [ダ]='da' [ヂ]='di' [ヅ]='du' [デ]='de' [ド]='do'
        [ナ]='na' [ニ]='ni' [ヌ]='nu' [ネ]='ne' [ノ]='no'
        [ハ]='ha' [ヒ]='hi' [フ]='hu' [ヘ]='he' [ホ]='ho'
        [バ]='ba' [ビ]='bi' [ブ]='bu' [ベ]='be' [ボ]='bo'
        [パ]='pa' [ピ]='pi' [プ]='pu' [ペ]='pe' [ポ]='po'
        [マ]='ma' [ミ]='mi' [ム]='mu' [メ]='me' [モ]='mo'
        [ヤ]='ya'           [ユ]='yu'           [ヨ]='yo'
        [ラ]='ra' [リ]='ri' [ル]='ru' [レ]='re' [ロ]='ro'
        [ワ]='wa' [ヰ]='wi'           [ヱ]='we' [ヲ]='wo'
        [ン]='n     '
        [ヴ]='vu' [ヷ]='va' [ヸ]='vi' [ヹ]='ve' [ヺ]='vo'
    )
    rand_char=$(echo ${!katakana[@]} | tr ' ' '\n' | shuf -n1)
    rand_desc=${katakana[$rand_char]}
    echo "${rand_char}"'@'"${rand_desc}"
}

# Reference: http://japanese.about.com/od/kan2/a/100kanji.htm
flashcard.kanji(){
    dtitle 'flashcard - kanji'
    check_in_path 'convert'
    declare -A kanji
    kanji=(
        [日]='sun'
        [一]='one'
        [大]='big'
        [年]='year'
        [中]='middle'
        [会]='to meet'
        [人]='human being, people'
        [本]='book'
        [月]='moon, month'
        [長]='long'
        [国]='country'
        [出]='to go out'
        [上]='up, top'
        [十]='ten'
        [生]='life'
        [子]='child'
        [分]='minute'
        [東]='east'
        [三]='three'
        [行]='to go'
        [同]='same'
        [今]='now'
        [高]='high, expensive'
        [金]='money, gold'
        [時]='time'
        [手]='hand'
        [見]='to see, to look'
        [市]='city'
        [力]='power'
        [米]='rice'
        [自]='oneself'
        [前]='before'
        [円]='Yen (Japanese currency)'
        [合]='to combine'
        [立]='to stand'
        [内]='inside'
        [二]='two'
        [事]='affair, matter'
        [社]='company, society'
        [者]='person'
        [地]='ground, place'
        [京]='capital'
        [間]='interval, between'
        [田]='rice field'
        [体]='body'
        [学]='to study'
        [下]='down, under'
        [目]='eye'
        [五]='five'
        [後]='after'
        [新]='new'
        [明]='bright, clear'
        [方]='direction'
        [部]='section'
        [女]='woman'
        [八]='eight'
        [心]='heart'
        [四]='four'
        [民]='people, nation'
        [対]='opposite'
        [主]='main, master'
        [正]='right, correct'
        [代]='to substitute, generation'
        [言]='to say'
        [九]='nine'
        [小]='small'
        [思]='to think'
        [七]='seven'
        [山]='mountain'
        [実]='real'
        [入]='to enter'
        [回]='to turn around, time'
        [場]='place'
        [野]='field'
        [開]='to open'
        [万]='ten thousand'
        [全]='whole'
        [定]='to fix'
        [家]='house'
        [北]='north'
        [六]='six'
        [問]='question'
        [話]='to speak'
        [文]='letter, writings'
        [動]='to move'
        [度]='degree, time'
        [県]='prefecture'
        [水]='water'
        [安]='inexpensive, peaceful'
        [氏]='courtesy name (Mr., Mister)'
        [和]='harmonious, peace'
        [政]='government, politics'
        [保]='to maintain, to keep'
        [表]='to express, surface'
        [道]='way'
        [相]='phase, mutual'
        [意]='mind, meaning'
        [発]='to start, to emit'
        [不]='not, un~, in~'
        [党]='political party'
    )
    rand_char=$(echo ${!kanji[@]} | tr ' ' '\n' | shuf -n1)
    rand_desc=${kanji[$rand_char]}
    echo "${rand_char}"'@'"${rand_desc}"
}
flashcard.goterms(){
    dtitle 'flashcard - kanji'
    check_in_path 'convert'
    declare -A goterms
    goterms=(
        ['Aji']='A weakness that is left behind in the opponent s position.
Has been translated as flavor, aftertaste,  and \"funny business\".
Typically it can be exploited in more than one way.'
        ['Atari']='A move that reduces a stone or chain of stones to one liberty.
The stones with one liberty are said to be \"in atari\".
An atari play that reduce one s own stones liberties to one is \"self-atari\".
an atari against two groups is \"double atari\".
Stones in atari can be captured on the opponents next turn unless they are defended.'
        ['Capturing race']='A race to fill in the liberties of two groups,
neither of which can live independently.
Also called semeai.'
        ['Chain']='A group of stones that are directly adjacent along the lines of the board.
The stones in a chain share liberties and live or die as a unit.
Also string.'
        ['Connection']='A play that joins two stones or chains into a single chain by connecting them along the lines of the board.
or that makes it possible for them to be so joined even if the opponent were to play first.
or that makes it unprofitable for the opponent to actively separate them.'
        ['Cut']='A move which separates two or more of a player s stones by occupying a point adjacent to them.'
        ['Dame']='1) Any empty point adjacent to a stone.
2) a neutral point between established Black and White positions which does not count as territory for either player.'
        ['Damezumari']='Inability to play at a tactically desirable point due to lack of liberties.'
        ['Death']='A group is dead when its owner cannot,
playing first with correct play,
make it live with two eyes or in seki or make a ko for life,
given accurate play by the opponent.'
        ['Dragon']='A dragon is a long connected shape spanning large areas of the board.'
        ['Endgame']='The final stage of the game.'
        ['Eye']='An empty space surrounded by one player s stones such that none of them can be brought into atari separately.'
        ['False Eye']='An empty space surrounded by one player s units such that at least one of them can be brought into atari separately.'
        ['Fuseki']='A Japanese go term meaning arraying forces for battle.
it refers to the initial phase of the game,
especially before there are any weak groups.'
        ['Geta']='See Net.'
        ['Gote']='1) A move or sequence of moves that does not have to be answered.
2) a move or sequence of moves that is not answered.'
        ['Group']='One or more stones considered as a unit.'
        ['Hane']='A single stone that \"reaches around\" the outside of an opposing unit diagonally,
adjacent but unconnected to an existing unit.'
        ['Handicap']='Stones that Black (the weaker player) places on the board before White s first move to ensure a more balanced contest.'
        ['Honte']='A solid move.'
        ['Influence']='The effect stones exert at a distance.'
        ['Invasion']='Play made inside an enemy framework with the intention of living or escaping.'
        ['Joseki']='Established sequences of play considered equitable for both players,
especially early moves near a corner.'
        ['Kikashi']='A Japanese go term adopted into English (forcing move) for a sente move that produces a certain effect and can then be abandoned without regret.'
        ['Killing']='Ensuring that a group will ultimately perish and be removed from the board.'
        ['Ko']='A position in which single stones could be captured back and forth
indefinitely were there not a rule forbidding such repetition.'
        ['Ko Threat']='A threatening move played either to provoke an immediate response from the opponent,
allowing the player to recapture the ko on his next move,
or to make a gain if the opponent ignores it.'
        ['Komi']='Points added to a player s score,
normally given to White in compensation for Black s advantage in playing first.'
        ['Ladder']='A technique for capturing stones where at each step,
the attacker reduces the defender s liberties from two to one: especially an attack of this type that proceeds diagonally across the board.'
        ['Liberty']='1) A dame.
2) a move required to capture a stone or group.'
        ['Life']='State where a group has two eyes,
lives in seki or is secure enough to survive any attack.'
        ['Miai']='Two moves that have equivalent effects,
such that if either player plays one,
his opponent will play the other.'
        ['Moyo']='A territorial framework,
an extensive area loosely bounded by one player s stones,
where the other has yet to establish any defensible positions,
and which consequently could become the former s territory.'
        ['Net']='A technique that ensures the capture of one or more stones by blocking their access to open board areas.'
        ['Omoyo']='A large scale Moyo (territorial framework).'
        ['Peep']='A threat to cut (nozoki in Japanese) played directly or diagonally adjacent to a cutting point.'
        ['Point']='The intersection of two lines on the go board.'
        ['Ponnuki']='Capture of a single stone above the first line by four opposing stones,
leaving a diamond shape.'
        ['Sabaki']='Development of a flexible and defensible position in an area of opposing forces,
especially by means of contact plays and sacrifice tactics.'
        ['Sansan']='3-3 point on the goban.'
        ['Seki']='A Japanese go term adopted into English,  meaning 
an impasse in which stones are alive without two eyes 
because the opponent cannot or should not capture them.
Also known as mutual life.'
        ['Semeai']='A Capturing Race.'
        ['Semedori']='A situation in which dead stones must eventually be captured.'
        ['Sente']='1) The initiative.
 2) a play that must be answered.
 3) a play that is answered.'
        ['Shape']='relative positions of stones of one color in close proximity.'
        ['Shicho']='A Ladder.'
        ['Tengen']='The center point of the goban.'
        ['Tenuki']='A Japanese go term adopted into English that denotes playing elsewhere,
especially breaking off from a sequence that remains to be resolved.'
        ['Territory']='1) A region of the board that belongs to one player because it is surrounded 
by stones belonging to a living group,
and in which the opponent cannot make a living group.
2) a region which almost belongs to one player.'
        ['Tesuji']='An astute,
often counter-intuitive tactical play that optimally exploits a defect in the opposing shapes.'
        ['Tsumego']='A life and death problem.'
        ['Vital Point']='A key point (for either player) in the local,
or perhaps less commonly global,
context that will normally either establish a good shape or force the opponent into bad shape.'
        ['Yose']='A Japanese go term adopted into English,
meaning moves that approach fairly stable territory,
typically enlarging one s own territory while reducing the opponent s.'
    )
    rand_char=$(echo ${!goterms[@]} | tr ' ' '\n' | shuf -n1)
    rand_desc=${goterms[$rand_char]}
    echo "${rand_char}"'@'"${rand_desc}"
}
http.get.url.nasa.eo.iotd(){
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

http.get.url.aw.america(){
    dtitle 'aw - aviation weather '
    check_in_path 'convert'
    local URL=http://aviationweather.gov
    local ARGS=data/obs/sat/intl/ir_ICAO-A.jpg
    echo "${URL}/${ARGS}"
}

http.get.url.america.smn(){
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
http.get.url.nasa.msfc(){
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

http.get.url.skymap.astronetru(){
    dtitle 'astronet.ru - skymap'
    check_in_path 'date'
    local year=$(date --utc +%Y) month=$(date --utc +%m) 
    local day=$(date --utc +%d) hour=$(date --utc +%H)
    local BASE_URL='http://www.astronet.ru:8105'
    local ARGS='cgi-bin/skyc.cgi?'\
'ut='${hour}'&day='"${day}"'&month='${month}'&year='${year}\
'&longitude='$((LONGITUDE * (-1)))'&latitude='${LATITUDE}\
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
http.get.url.skymap.heavenabove(){
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

http.get.url.skymap.astrobot(){
    dtitle 'astrobot - skymap'
    local URL='http://www.astrobot.eu/skymapserver'
    local ARGS='skymap?type=gif&size=1000&colorset=0&lang=en&lat='$LATITUDE'&lon='$LONGITUDE'&timezone=UT&deco=15'
    local image_url=${URL}/${ARGS}
    echo "${image_url}"
}

http.get.url.nasa.jpl(){
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
    local rand_page=$(( max_page * RANDOM / 32768 + 1))
    local BASE_URL_PAGE=${BASE_URL}'&page='${rand_page}
    # step 2: download a random page from that category
    local PIC_URL=$(
        curl -A "${USER_AGENT}" -k -s -o- "${BASE_URL_PAGE}" |
        egrep -o 'wallpaper.php\?id=[[:alnum:]]+'  | 
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

http.get.url.calvinandhobbes(){
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
        tr '"' '\n'| 
        grep asset
    )
    [[ ! -z $image_url ]] && {
        echo "${image_url}"
    }
}

# Reference: https://github.com/ondrg/dilbert-downloader
http.get.url.dilbert(){
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

http.get.url.eatthattoast(){
    dtitle 'eatthattoast - comic'
    local page=$((3 * RANDOM / 32768 + 1 ))
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
http.get.url.xkcd.rand(){
    dtitle 'xkcd - comic'
    local page=$((1351 * RANDOM / 32768 + 1 ))
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

http.get.url.simpledesktops(){
    dtitle 'simpledesktops - minimalistic desktops'
    local page=$((46 * RANDOM / 32768 + 1 ))
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
http.get.url.dienet.world(){
    dtitle 'dienet -  Image of earth'
    local proyection=$1
    local BASE_URL='http://static.die.net/earth/'$proyection
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
    if [[ ! -z $image_url ]]; then
        image_url=${image_url/200H/}
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

#BASE_URL_ARRAY+=('http://wallbase.cc/random')

# https://github.com/jabbalaci/Wallpaper-Downloader-and-Rotator-for-Gnome
http.get.url.wallbase(){
    dtitle 'wallbase.cc - random wallpaper, from different topics'
    local -a BASE_URL_ARRAY
    BASE_URL_ARRAY+=('tag=8135&order=random')  # outer-space
    BASE_URL_ARRAY+=('tag=11544&order=random') # cyberpunk
    BASE_URL_ARRAY+=('tag=41408')              # mandelbrot
    BASE_URL_ARRAY+=('tag=17756')              # historic
    BASE_URL_ARRAY+=('tag=12637')              # maps
    BASE_URL_ARRAY+=('tag=20118')              # manga
    BASE_URL_ARRAY+=('tag=8383')               # dc comics
    BASE_URL_ARRAY+=('tag=44153&order=random') # vertigo comics
    BASE_URL_ARRAY+=('tag=8208')               # cityscapes
    BASE_URL_ARRAY+=('tag=8023')               # landscapes
    BASE_URL_ARRAY+=('tag=18787')              # board games
    BASE_URL_ARRAY+=('tag=10896&order=random') # subway
    BASE_URL_ARRAY+=('tag=9620&order=random')  # telescope 
    BASE_URL_ARRAY+=('tag=8911&order=random')  # silhouettes
    BASE_URL_ARRAY+=('tag=11563&order=random') # national geographic
    BASE_URL_ARRAY+=('tag=17339&order=random') # macro
    BASE_URL_ARRAY+=('tag=8664&order=random')  # leaves
    BASE_URL_ARRAY+=('tag=8190&order=random')  # autum

    local BASE_URL='http://wallbase.cc/search?'$(get.array.rand ${BASE_URL_ARRAY[@]})

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

http.get.url.nasa.apod.rand(){
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
http.get.url.nasa.apod(){
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
#    echo "${image_url}"
#     echo 'http://www.smn.gov.ar/vmsr/conae/MCidas/LATEST/goes13_imager_LATEST_argentina_shss_b4_ctt.jpg'
    echo 'http://www.smn.gov.ar/vmsr/conae/MCidas/LATEST/goes13_imager_LATEST_argentina_b4_ctt.jpg'
}

# Reference: http://awesome.naquadah.org/wiki/NASA_IOTD_Wallpaper
# The Content-Encoding returned by this server is not always the same, sometimes returns gzipped data and sometimes in plain text.
# That's why I am using some logic to detect that and "base64" to store the gzip file in a variable.
http.get.url.nasa.iotd(){
    dtitle 'NASA Image of the day'
    check_in_path 'base64'
    local BASE_URL='http://www.nasa.gov/rss/dyn/image_of_the_day.rss'
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

# >>>>>>>>>>> switch-board of flags

while getopts ':hn:a:c:w:m:f:' opt; do
    case $opt in
        m)
	    case $OPTARG in
	        4walled)
		    jpg=$(http.get.url.4walled)
		    ;;
		interfacelift)
		    jpg=$(http.get.url.interfacelift)
		    ;;
		wallbase)
		    jpg=$(http.get.url.wallbase)
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
        f)
            case $OPTARG in
                hiragana)
                    mytext=$(flashcard.hiragana)
                    ;;
                katakana)
                    mytext=$(flashcard.katakana)
                    ;;
                kanji)
                    mytext=$(flashcard.kanji)
                    ;;
                goterms)
                    mytext=$(flashcard.goterms)
                    ;;
                *)
                    help.usage.flashcards
                    exit 1
                    ;;
            esac 
            [[ ! -z $mytext ]] && {
                mytitle=$( echo "${mytext}" | cut -s -f1 -d'@')
                mydesc=$(echo "${mytext}"  | cut -f2 -d'@')
                CONVERT_FCARD=(-font ${FONT_PATH})
                CONVERT_FCARD+=(-interword-spacing 9 -kerning 0)
                # twice to add shadows
                CONVERT_FCARD+=(-pointsize 200 -draw 'gravity center fill black text 3,3 "'"${mytitle}"'"')
                CONVERT_FCARD+=(-pointsize 200 -draw 'gravity center fill white text 0,0 "'"${mytitle}"'"')
                CONVERT_FCARD+=(-pointsize 30 -draw 'gravity center fill black text 2,152 "'"${mydesc}"'"')
                CONVERT_FCARD+=(-pointsize 30 -draw 'gravity center fill white text 0,150 "'"${mydesc}"'"')
            }
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
                    CONVERT_OPT+=(-draw "line 0,0 250,0"       -draw "line 750,0 1000,0")
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
            esac ;;
        \?) 
            help.usage
            exit 1;; 
        h)
            help.usage
            exit 1;;
        :)
            case $OPTARG in
                a) help.usage.astronomy; exit 1;;
                w) help.usage.weather;   exit 1;;
                c) help.usage.comics;    exit 1;;
                m) help.usage.misc;      exit 1;;
                n) help.usage.nature;    exit 1;;
                f) help.usage.flashcards;exit 1;;
            esac ;;
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
    
    echo '[+] Downloading image...' 
    # Reference: http://blog.yjl.im/2012/03/downloading-only-when-modified-using.html
    curl -A "${USER_AGENT}" -k --dump-header - "${jpg}" -z "${filename}" -o "${filename}" -s -L 2>/dev/null
    
    # Apply convert filter to downloaded image
    [[ ! -z $CONVERT_OPT ]] && hash convert &>/dev/null && {
        original_image="$filename"
        filename="${PWD}"'/wp.png'
        echo '[+] Cleaning up downloaded image...'
        convert "${original_image}" "${CONVERT_OPT[@]}" $filename
    }
fi

# Apply flashcard
if [[ ! -z $CONVERT_FCARD ]]; then
        echo '[+] Writing flashcard over image...'
        if [[ ! -z $filename ]]; then
            convert $filename "${CONVERT_FCARD[@]}" $filename
        else
            filename="${PWD}"'/wp.png'
            convert -size 1280x800 xc:black "${CONVERT_FCARD[@]}" $filename
        fi
        echo
fi

if [[ ! -z $filename ]]; then
    set.wallpaper "${filename}"
    [[ ! -z $jpg ]] && echo 'URL:  '"${jpg}"
    echo 'FILE: '"${picname:-$filename}"
fi
