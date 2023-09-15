#!/bin/sh

USERNAME=$(uci -q get daed.config.daed_username)
PASSWORD=$(uci -q get daed.config.daed_password)
PORT=$(echo "$(uci -q get daed.config.listen_addr)" | grep -oE '[0-9]+$' | sed -n '1p')
GRAPHQL_URL="http://127.0.0.1:"$PORT"/graphql"

login() {
	LOGIN=$(curl -s -X POST -H "Content-Type: application/json" -d '{"query":"query Token($username: String!, $password: String!) {\n token(username: $username, password: $password)\n}","variables":{"username":"'"$USERNAME"'","password":"'"$PASSWORD"'"}}' $GRAPHQL_URL)
	JSON=${LOGIN#\"}
	JSON=${LOGIN%\"}
	TOKEN=$(echo $JSON | sed -n 's/.*"token":"\([^"]*\)".*/\1/p')
}

update_subscription() {
	SUBSCRIPTION_ID_LIST=$(curl -s -X POST -H "Authorization: $TOKEN" -d '{"query": "query Subscriptions {\n subscriptions {\nid\ntag\nstatus\nlink\ninfo\nupdatedAt\nnodes {\nedges {\nid\nname\nprotocol\nlink\n}\n}\n}\n}", "operationName": "Subscriptions"}' $GRAPHQL_URL | grep -o '"id":"[^"]*","tag"' | grep -o 'id":"[^"]*' | grep -o '[^"]*$')
	echo "$SUBSCRIPTION_ID_LIST" | while read -r id; do
	curl -X POST -H "Authorization: $TOKEN" -d '{"query":"mutation UpdateSubscription($id: ID!) {\n  updateSubscription(id: $id) {\n    id\n  }\n}","variables":{"id":"'"$id"'"},"operationName":"UpdateSubscription"}' $GRAPHQL_URL
	done
	curl -X POST -H "Authorization: $TOKEN" -d '{"query":"mutation Run($dry: Boolean!) {\n  run(dry: $dry)\n}","variables":{"dry":false},"operationName":"Run"}' $GRAPHQL_URL
}

login && update_subscription
