#!/bin/bash

usage() {
  cat <<EOL
USAGE: $(basename $0) [OPTIONS...] source_path destination_path

OPTIONS:
  -h, --help
  --status
EOL
    exit 1
}

assert_not_redirect() {
    if [ "$http_code" = "200" ]; then
        return 0
    fi

    return 1
}

assert_redirect_with() {
    if [ "$http_code" = $1 ] && [ "$destination_path" = "$redirect_url" ] && [ "$destination_path" = "$url_effective" ]; then
        return 0
    fi

    return 1
}

assert_redirect() {
    if [ "$http_code" = "300" ] && [ "$destination_path" = "$redirect_url" ] && [ "$destination_path" = "$url_effective" ]; then
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
    if [ "$http_code" = "404" ]; then
        return 0
    fi

    return 1
}

assert_be_gone() {
    if [ "$http_code" = "410" ]; then
        return 0
    fi

    return 1
}

fetch() {
    curl_out_non_redirect=`curl -s -w "%{http_code}\t%{redirect_url}" -o /dev/null $source_path`
    curl_out_redirect=`curl -sL -w "%{url_effective}" -o /dev/null $source_path`

    http_code=`echo "$curl_out_non_redirect" | cut -f1`
    redirect_url=`echo "$curl_out_non_redirect" | cut -f2`
    url_effective=`echo "$curl_out_redirect" | cut -f1`

    return 0
}

main() {
    status=""
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

    case "$status" in
        "200")
            assert_not_redirect && exit 0
            ;;
        "404")
            assert_not_be_found && exit 0
            ;;
        "410")
            assert_be_gone && exit 0
            ;;
        "300"|"301"|"302"|"303")
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
