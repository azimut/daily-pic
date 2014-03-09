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
```shell
bash do.sh -a


Crontab entry
-------------

```shell
0 */1 * * * cd /home/sendai/projects/daily-pic; bash do.sh -a &> pics/log.txt
