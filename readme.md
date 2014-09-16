relief-map
==========

Converts USGS GridFloat Data to a STL file.


Steps to use:

1. Install ruby.
2. Go to http://viewer.nationalmap.gov/viewer/ and find your area of interest.
3. Click the blue download arrow then click, "Click here to draw and download by bounding box"
4. Draw a box around your area of interest. 
5. Choose "Elevation" in the list asking for what kind of data you want.
6. This script is expecting you to use the GridFloat file format choose the one with the best resulution. \*
7. Go through the download process once you have unzipped the data you will find a file named something like "n41w106_13_meta.html" Open this file.
8. Open the relief.rb file and there are some variables you need to modify for your data. Modify these at the top of the file.
9. Run the script and 





\* USGS GridFloat data seems to come in 1x1 degree tiles and they are broken up very close to the whole number lat/long boundary. If you chose an area that goes across multiple tiles this script is not made to handle that situation as of right now. 