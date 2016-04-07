#!/bin/bash

destination=$1
shift

./downloadAmazonReviews.pl com $*

for product in amazonreviews/com/*;
do ./extractAmazonReviews-DivLayout.pl $product > $destination/$(basename $product).csv;
done