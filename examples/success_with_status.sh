#!/bin/sh

cd $(dirname $0)
base=$(pwd)

succeeded=0
failed=0

for source_status_destination in \
    "http://httpstat.us/200 200" \
    "http://httpstat.us/404 404" \
    "http://httpstat.us/410 410" \
    "http://httpstat.us/300 300" \
    "http://httpstat.us/301 301 http://httpstat.us" \
    "http://httpstat.us/302 302 http://httpstat.us" \
    "http://httpstat.us/303 303 http://httpstat.us"
do
    source=`echo $source_status_destination | cut -f1 -d" "`
    status=`echo $source_status_destination | cut -f2 -d" "`
    destination=`echo $source_status_destination | cut -f3 -d" "`

    $base/../http_redirect_test.sh $source $destination --status $status --debug --remove

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
