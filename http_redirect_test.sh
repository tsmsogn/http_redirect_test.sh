#!/bin/bash

usage() {
  cat <<EOL
USAGE: $(basename $0) [OPTIONS...] source_path destination_path

OPTIONS:
  -h, --help
  --status
  --remove Remove trailing slash from response urls
  --debug
  --
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
    case "$1" in
        ""|"301"|"302"|"303")
            curl_out_non_redirect=`curl -s -w "%{http_code}" -o /dev/null $source_path $args`
            curl_out_redirect=`curl -sL -w "%{url_effective}" -o /dev/null $source_path $args`
            ;;
        *)
            curl_out_non_redirect=`curl -s -w "%{http_code}" -o /dev/null $source_path $args`
            ;;
    esac

    http_code=`echo "$curl_out_non_redirect"`
    url_effective=`echo "$curl_out_redirect"`

    return 0
}

remove_trailing_slash() {
    echo ${1%/}
}

main() {
    status=""
    remove=false
    debug=false
    args=""
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
            --)
                shift
                args=$*
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

    fetch $status

    if $remove; then
        url_effective=`remove_trailing_slash $url_effective`
    fi

    if $debug; then
        echo "---> $source_path"
        echo "Expected: status: $status url: $destination_path"
        echo "Actual: status: $http_code, url: $url_effective"
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
            && assert_same $destination_path $url_effective \
            && exit 0
            ;;
        "")
            case "$http_code" in
                "300")
                    exit 0
                    ;;
                "301"|"302"|"303")
                    assert_same $destination_path $url_effective \
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
