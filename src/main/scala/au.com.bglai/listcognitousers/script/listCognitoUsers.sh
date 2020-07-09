#!/bin/sh
#
# List AWS Cognito users as CSV output.
# command example:
# $./listCognitoUsers.sh cognitoUserPollId > allUsers.csv
#

basename="`basename $0`"
if [ $# != 1 ]; then
    echo Usage: "$basename" pool_id >&2
    exit 1
fi

next=''
tmpfile="`mktemp cognitoUsers.json`"
trap 'rm -f "$tmpfile"' EXIT

while :; do
    if ! aws cognito-idp list-users --user-pool-id "$1" --limit 60 "$next" > "$tmpfile"; then
        echo ERROR: list-users failed >&2
        exit 10
    fi
    jq --arg next "${#next}" -r '.Users | map_values((.Attributes | from_entries) + {userName: .Username, userStatus: .UserStatus, enabled: .Enabled, userCreateDate: .UserCreateDate, lastModifiedDate: .UserLastModifiedDate}) | if $next == "0" then (.[0] | to_entries | map(.key)) else empty end, (.[] | [.[]]) | @csv' < $tmpfile
    token="`jq -r '.PaginationToken' "$tmpfile"`"
    if [ "$token" = null ]; then
        break
    fi
    next=--pagination-token="$token"
    sleep 1
done