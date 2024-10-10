Simple RSS feed viewer on CUI
=============================

A simple RSS feed viewer for CUI.

Just preview the RSS feed.



## Installation
### Depends
- Ruby 3.*


### How to install
```sh
$ curl -L https://raw.githubusercontent.com/mitsu-ksgr/rss-viewer/refs/heads/main/rssv.rb -o ./rssv.rb
$ ./rssv.rb
```


## Dev
### serve sample rss files
```sh
$ ./serve.sh
*** RSS Sample Server ***

- http://localhost:8000/atom.xml
- http://localhost:8000/rss2.xml
- http://localhost:8000/rss1.rdf

-------------------------
Serving HTTP on 0.0.0.0 port 8000 (http://0.0.0.0:8000/) ...

```


## Todo
- Accepts a URL as a commandline argument.
- Supports Atom feed with some flaws.


