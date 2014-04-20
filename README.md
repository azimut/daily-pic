daily-pic
=========

Get and set the image of the day from different sites:

![result](http://i.imgur.com/V6oPqpS.gif "example")
![result2](http://i.imgur.com/uJ2W3Zr.gif "example2")

### Astronomy
* nasa.apod
* nasa.apod.rand
* nasa.iod
* nasa.jpl
* skymap.astrobot
* skymap.heavensabove
* skymap.astronetru

### Comics
* dilbert
* calvinandhobbes
* eatthattoast
* xkcd

### Misc
* 4walled
* interfacelift
* wallbase
* imgur.albums
* imgur.subreddit
* reddit
* deviantart
* simpledesktops
    
### Nature    
* bing
* chromecast
* natgeo
* nasa earth observatory iotd
        
### Weather
*  latlong.nasa.msfc
*  america.smn
*  america.nasa.goes
*  america.fvalk
*  america.s.aw
*  america.n.aw
*  globe.dienet.mercator
*  globe.dienet.peters
*  globe.dienet.mollweide
*  globe.dienet.rectangular
*  arg.smn
*  arg.nexsat

Feel free to add your own source :)

Usage
-----

Pass the correspondent flag as argument to the script.
For example, to get and set the wallpaper from nasa apod use the ```-a``` flag:

```
$ bash do.sh -a nasa.jpl
# NASA - Jet Propulsion Laboratory

- Category: universe

HTTP/1.1 200 OK
Date: Fri, 11 Apr 2014 01:32:35 GMT
Server: Apache/2.2.25 (Unix) PHP/5.5.9 JRun/4.0
Last-Modified: Thu, 23 Jun 2011 14:46:19 GMT
ETag: "4647c4f-cd8d-4a66225dba4c0"
Accept-Ranges: bytes
Content-Length: 52621
Content-Type: image/jpeg
X-Pad: avoid browser bug

URL:  http://www.jpl.nasa.gov/spaceimages/images/wallpaper/PIA13066-800x600.jpg
FILE: /home/sendai/projects/daily-pic/pics/PIA13066-800x600.jpg
```

Installation steps
------------------

Go to where you want to save this script:
```
$ cd /home/usernamehere/projects
```
Clone this repo (or just download the zip file):
```
$ git clone 'https://github.com/azimut/daily-pic'
```
Add the following crontab as root or using ```sudo``` (if you are using vixie-cron or if you know how to configure cron you might try to add this as user instead of root):
```
# crontab -e
0 */1 * * * su - usernamehere -c 'cd /home/usernamehere/projects/daily-pic; bash do.sh -a &>> pics/log.txt'
```

TODO
----

* Get more sources: daily random code of the day? (github/gist) daily webcam image of the day/hour?
* Add some kind of heuristic to determine what is the best fit for a wallpaper (what feh option use) based on the resolution of the current monitor.
