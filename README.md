daily-pic
=========

Fetch the image of the day from

* Nasa Image of the day
* Nasa Astronomy Picture of the Day
* National Geographic
* fvalk (satellite images of the earth)

Feel free to add you own :)

Usage
-----

Just pass a flag corresponding to the image you want to get.
For example, to get and set the wallpaper from nasa apod:

```
bash do.sh -a
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


Crontab entry
-------------

```
0 */1 * * * cd /home/sendai/projects/daily-pic; bash do.sh -a &> pics/log.txt
```
