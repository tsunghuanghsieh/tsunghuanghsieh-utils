#!/bin/bash

HOME_DIR=`pwd`

# use non default separator for sed
fileslist=`find $HOME_DIR -type f -name "*.png" | sed -e s?$HOME_DIR/??`

# back up default internal field separator (IFS)
OriginalIFS=$IFS
# set IFS for splitting the list of filenames
IFS=$'\n'

files=($fileslist)
select file in ${files[@]}
do
    case $file in
        # Good
        # "Screen Shot 2019-07-17 at 2.55.37 PM.png"|"test/Screen Shot 2019-07-17 at 2.55.37 PM.png")
        # Below doesn't work
        # Variable with value "Screen Shot 2019-07-17 at 2.55.37 PM.png|test/Screen Shot 2019-07-17 at 2.55.37 PM.png"
        *"png")
            echo "Selection #:" $REPLY "File: \""$file"\""
            ;;
        *)
            echo "Selection #:" $REPLY "File: \""$file"\""
            echo Goodbye!
            break;;
    esac
done

#restore IFS to the default value
IFS=$OriginalIFS
