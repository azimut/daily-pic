daily-pic
=========

Get and set the image of the day from different sites:

* Nasa Image of the day
* Nasa Astronomy Picture of the Day
* National Geographic
* fvalk (satellite images of the earth)
* Servicio Meteorologico Nacional Argentino

Feel free to add your own source :)

Usage
-----

Pass the correspondent flag as argument to the script.
For example, to get and set the wallpaper from nasa apod use the ```-a``` flag:

```
$ bash do.sh -a
  HTTP/1.1 200 OK
  Date: Sun, 09 Mar 2014 20:23:40 GMT
  Server: WebServer/1.0
  Last-Modified: Fri, 07 Mar 2014 00:10:31 GMT
  ETag: "112c9e7-24f66a-4f3f914f74bc0"
  Accept-Ranges: bytes
  Content-Length: 2422378
  Connection: close
  Content-Type: image/jpeg
2014-03-09 17:19:20 URL:http://apod.nasa.gov/apod/image/1403/marshole2_hirise_2560.jpg [2422378] -> "marshole2_hirise_2560.jpg" [1]
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
