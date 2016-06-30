#!/bin/bash

usage() {
  cat <<EOL
USAGE: $(basename $0) [OPTIONS...] source_path destination_path

OPTIONS:
  -h, --help
  --status
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

assert_redirect_with() {
    if [ "$http_code" = $1 ] && [ "$destination_path" = "$redirect_url" ] && [ "$destination_path" = "$url_effective" ]; then
        return 0
    fi

    return 1
}

assert_redirect() {
    if [ "$http_code" = "300" ]; then
        return 0
    elif [ "$http_code" = "301" ] && [ "$destination_path" = "$redirect_url" ] && [ "$destination_path" = "$url_effective" ]; then
        return 0
    elif [ "$http_code" = "302" ] && [ "$destination_path" = "$redirect_url" ] && [ "$destination_path" = "$url_effective" ]; then
        return 0
    elif [ "$http_code" = "303" ] && [ "$destination_path" = "$redirect_url" ] && [ "$destination_path" = "$url_effective" ]; then
        return 0
    fi

    return 1
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

    redirect_url=`remove_trailing_slash $redirect_url`
    url_effective=`remove_trailing_slash $url_effective`

    return 0
}

remove_trailing_slash() {
    echo ${1%/}
}

main() {
    status=""
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

    if [ $debug ]; then
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
            assert_redirect_with $status && exit 0
            ;;
        "")
            assert_redirect && exit 0
            ;;
        *)
            ;;
    esac

    exit 1
}

main $*
