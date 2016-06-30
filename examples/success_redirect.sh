#!/bin/sh

cd $(dirname $0)
base=$(pwd)

succeeded=0
failed=0

for source_destination in \
    "http://httpstat.us/300" \
    "http://httpstat.us/301 http://httpstat.us" \
    "http://httpstat.us/302 http://httpstat.us" \
    "http://httpstat.us/303 http://httpstat.us"
do
    source=`echo $source_destination | cut -f1 -d" "`
    destination=`echo $source_destination | cut -f2 -d" "`

    $base/../http_redirect_test.sh $source $destination

    case $? in
        0)
            succeeded=`expr $succeeded + 1`
            ;;
        *)
            failed=`expr $failed + 1`
            ;;
    esac
done

echo "succeeded: $succeeded, failed: $failed"
