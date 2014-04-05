daily-pic
=========

Get and set the image of the day from different sites:

* Nasa Image of the day
* Nasa Astronomy Picture of the Day
* National Geographic
* fvalk (satellite images of the earth)
* Servicio Meteorologico Nacional Argentino
* 4walled (4chan/7chan)
* interfacelift
* Nasa goes
* wallbase
* bing(iod)
* reddit(wallpaper/imgur)
* deviantart (iod/24h)
* dienet world map
* imgur albums
* imgur subreddit
* random option!

Feel free to add your own source :)

Usage
-----

Pass the correspondent flag as argument to the script.
For example, to get and set the wallpaper from nasa apod use the ```-a``` flag:

```
$ bash do.sh -a
# NASA - Astronomy picture of the day

  HTTP/1.1 200 OK
  Server: WebServer/1.0
  Last-Modified: Thu, 03 Apr 2014 18:59:08 GMT
  ETag: "7f1f5d-1707cf-4f627fefc3571"
  Accept-Ranges: bytes
  Keep-Alive: timeout=5, max=100
  Content-Type: image/jpeg
  Connection: close     
  Date: Sat, 05 Apr 2014 07:08:45 GMT
  Age: 11018  
  Content-Length: 1509327
2014-04-05 04:08:56 URL:http://apod.nasa.gov/apod/image/1404/farside_lro1600.jpg [1509327] -> "farside_lro1600.jpg" [1]

URL:  http://apod.nasa.gov/apod/image/1404/farside_lro1600.jpg
FILE: /home/user/projects/daily-pic/pics/farside_lro1600.jpg
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
