#!/usr/bin/env bash
# catch_error.sh

count=0  # The number of times before failing
error=0  # assuming everything initially ran fine

while [ "$error" != 1 ]; do
    # running till non-zero exit

    # writing the error code from the radom_fail script into /tmp/error
    bash ./random_fail.sh 1>/tmp/msg 2>/tmp/error

    # reading from the file, assuming 0 written inside most of the times
    error="$(cat /tmp/error)"

    echo "$error"

    # updating the count
    count=$((count + 1))

done

echo "random_fail.sh failed!: $(cat /tmp/msg)"
echo "Error code: $(cat /tmp/error)"
echo "Ran ${count} times, before failing"

writeProxyStringToGradleProps () {
    local PROXY=$1
    local PROTOCOL=$2
    local FILE=$3

    # Strip the port.
    local HOST=${PROXY%:*}
    # Strip the protocol.
    HOST=${HOST#*//}
    # Extract authentication info.
    local AUTH=${HOST%%@*}
    if [ "$AUTH" != "$HOST" ]; then
        # Strip authentication info.
        HOST=${HOST#$AUTH@}
        # Extract the user.
        local USER=${AUTH%%:*}
        # Extract the password.
        local PASSWORD=${AUTH#*:}
    fi

    local PORT=${PROXY##*:}
    [ "$PORT" -ge 0 ] 2>/dev/null || PORT=80

    grep -qF "systemProp.$PROTOCOL.proxy" $FILE 2>/dev/null && return 1

    mkdir -p $(dirname $FILE)

    cat <<- EOF >> $FILE
	systemProp.$PROTOCOL.proxyHost=$HOST
	systemProp.$PROTOCOL.proxyPort=$PORT
	systemProp.$PROTOCOL.proxyUser=$USER
	systemProp.$PROTOCOL.proxyPassword=$PASSWORD
	EOF
}

writeNoProxyEnvToGradleProps () {
    local HOSTS=$1
    local FILE=$2

    grep -qF "systemProp.http.nonProxyHosts" $FILE 2>/dev/null && return 1

    # Gradle / JVM expects a list separated by pipes instead of the comma that
    # is used in shell environments
    echo "systemProp.http.nonProxyHosts=${HOSTS//,/\|}" >> $FILE
}

writeProxyEnvToGradleProps () {
    local GRADLE_PROPS=$1

    if [ -z "$GRADLE_PROPS" ]; then
        local GRADLE_PROPS="${GRADLE_USER_HOME:-$HOME/.gradle}/gradle.properties"
    fi

    if [ -n "$http_proxy" ]; then
        echo "Setting HTTP proxy $http_proxy for Gradle in file '$GRADLE_PROPS'..."
        if ! writeProxyStringToGradleProps $http_proxy "http" $GRADLE_PROPS; then
            echo "Not replacing existing HTTP proxy."
        fi
    fi

    if [ -n "$https_proxy" ]; then
        echo "Setting HTTPS proxy $https_proxy for Gradle in file '$GRADLE_PROPS'..."
        if ! writeProxyStringToGradleProps $https_proxy "https" $GRADLE_PROPS; then
            echo "Not replacing existing HTTPS proxy."
        fi
    fi

    if [ -n "$no_proxy" ]; then
        echo "Setting proxy exemptions $no_proxy for Gradle in file '$GRADLE_PROPS'..."
        if ! writeNoProxyEnvToGradleProps $no_proxy $GRADLE_PROPS; then
            echo "Not replacing existing proxy exemptions."
        fi
    fi
}

writeProxyEnvToGradleProps $1
