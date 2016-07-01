#!/bin/bash

usage() {
  cat <<EOL
USAGE: $(basename $0) [OPTIONS...] source_path destination_path

OPTIONS:
  -h, --help
  --status
  --remove Remove trailing slash from response urls
  --debug
EOL
    exit 1
}

assert_same() {
    if [ "$1" = "$2" ]; then
        return 0;
    fi

    return 1
}

assert_be_ok() {
    assert_same $1 "200"
}

assert_be_multiple_choices() {
    assert_same $1 "300"
}

assert_not_be_found() {
    assert_same $1 "404"
}

assert_be_gone() {
    assert_same $1 "410"
}

fetch() {
    curl_out_non_redirect=`curl -s -w "%{http_code}\t%{redirect_url}" -o /dev/null $source_path`
    curl_out_redirect=`curl -sL -w "%{url_effective}" -o /dev/null $source_path`

    http_code=`echo "$curl_out_non_redirect" | cut -f1`
    redirect_url=`echo "$curl_out_non_redirect" | cut -f2`
    url_effective=`echo "$curl_out_redirect" | cut -f1`

    return 0
}

remove_trailing_slash() {
    echo ${1%/}
}

main() {
    status=""
    remove=false
    debug=false
    local argc=0
    local argv=()

    while [ $# -gt 0 ]; do
        case $1 in
            -h|--help)
                usage
                ;;
            --status)
                status=$2
                shift
                ;;
            --remove)
                remove=true
                ;;
            --debug)
                debug=true
                ;;
            *)
                argc=`expr $argc + 1`
                argv+=($1)
                ;;
        esac
  
        shift
    done

    if [ $argc -lt 1 ]; then
        echo "Too few arguments"
        exit 1
    fi

    source_path=${argv[0]}
    destination_path=${argv[1]}

    fetch

    if $remove; then
        redirect_url=`remove_trailing_slash $redirect_url`
        url_effective=`remove_trailing_slash $url_effective`
    fi

    if $debug; then
        echo "---> $source_path"
        echo "Expected: status: $status url: $destination_path"
        echo "Actual: status: $http_code, url_effective: $url_effective, redirect_url: $redirect_url"
    fi

    case "$status" in
        "200")
            assert_be_ok $http_code && exit 0
            ;;
        "300")
            assert_be_multiple_choices $http_code && exit 0
            ;;
        "404")
            assert_not_be_found $http_code && exit 0
            ;;
        "410")
            assert_be_gone $http_code && exit 0
            ;;
        "301"|"302"|"303")
            assert_same $status $http_code \
            && assert_same $destination_path $redirect_url \
            && assert_same $destination_path $url_effective \
            && exit 0
            ;;
        "")
            case "$http_code" in
                "300")
                    exit 0
                    ;;
                "301"|"302"|"303")
                    assert_same $destination_path $redirect_url \
                    && assert_same $destination_path $url_effective \
                    && exit 0
                    ;;
                *)
                    ;;
            esac
            ;;
        *)
            ;;
    esac

    exit 1
}

main $*
