burlh() {
	local u="$1" h="$2" proto hostport host port path;
	u="${u#*://}";
	hostport="${u%%/*}";
	path="/${u#*/}";
	[[ "$hostport" == "$u" ]] && path="/";
	host="${hostport%%:*}";
	port="${hostport#*:}";
	[[ "$host" == "$port" ]] && port="${PORT:-80}";
	exec 3<>"/dev/tcp/$host/$port" || return 1;
	printf 'GET %s HTTP/1.0\r\nHost: %s\r\n%s\r\n\r\n' "$path" "$host" "$h" >&3;
	(while IFS= read -r l; do echo >&2 "$l"; [[ $l == $'\r' || -z $l ]] && break; done; cat) <&3;
	exec 3>&-;
}
