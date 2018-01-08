# Actimerger

A tool for merging subject-level sleep actigraphy output from Action W-2 (AW). 

It is currently only set up to select and merge data that we need in our lab. I hope to set it up so that users will be able to select 
desired variables using a config file. 

## Use case
The need for this program arose when my PI wanted to save only a subset of variables from a subset of intervals for each subject
in an actigraphy study. Unfortunately the way that AW formats output is not conducive to this: one can either copy all of the variables
from a given interval type one subject at a time, or else dump ***all*** of the interval variables one subject at a time. Either necessitates much data cleaning afterwards, especially since the table written to CSV is not particularly tidy: it places summary stats (mean and SD) within CSV in between
each interval type--not something I think beleongs in a raw dataset. 

## Dependencies 
Currently depends on dplyr, magrittr, and chron, although the tidyverse libraries are barely used and may be factored out.

## Usage
actimerger accepts a directory of AW .txt files (which are CSV formatted but given the .txt extension by AW). 
You will want to use only the "ALL_INTERVALS" files, which can easily be moved to their own dir with 

`mv *ALL_INTERVALS* /target/dir/for/data`

Once the data is in its own dir, call

`Rscript actimerge.R /path/to/data`

actimerger will write a timestamped CSV to the data directory. 
