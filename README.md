QuickStart Guide
================

These bash tools allow you to get data (in csv format) for any flat at idealista.com, provided the flat ID.
It can also automatically find out all the flat IDs for a given search page at idealista.com.


Example
-------

Browse to idealista.com, and do a search, and insert the resulting http URL to command line as shown below. You can use any number of search URLs, like this:

./idealistaFlat.sh $(./idealistaSearch.sh "URL" "URL2" "URL3")

Only the first 5 pages of paginated results for each URL will be parsed.

In general, just run the commands and you'll be told what to do if you didn't do it right (that's the idea at least...).


Contributing
------------

Feel free to contribute, and let the author know so that he can integrate your improvements, please :-D


Author
------

The author is STenyaK (aka Bruno Gonzalez), who can be reached via email at stenyak@stenyak.com

