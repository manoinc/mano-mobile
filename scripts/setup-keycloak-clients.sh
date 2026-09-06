#!/usr/bin/env bash
#
# Registers the two mobile apps as OIDC clients in the local `mano` realm.
#
# These clients belong to the apps, not to the backend: the realm itself is
# provisioned by libmano-backapp/scripts/setup-keycloak-realm.sh, which must
# have been run first.
#
# Idempotent: re-running is a no-op for anything that already exists.
#
# For each of mano-requester-app and mano-provider-app it creates a public
# client that is:
#
#   - PKCE-enforced with S256. These are public clients shipped to devices and
#     hold no secret, so the code challenge is the only thing standing between
#     an intercepted redirect and a stolen token.
#   - direct-access-grants disabled. The password grant would let the app
#     handle the user's password, which is exactly what the system-browser
#     flow exists to avoid.
#   - given an audience mapper for `mano-gateway`. Without one Keycloak issues
#     tokens with no `aud` at all, and the gateway rejects every one of them.
#
# Usage:
#   ./scripts/setup-keycloak-clients.sh
#
# Environment:
#   KEYCLOAK_CONTAINER   container name (default: keycloak)

set -euo pipefail

CONTAINER="${KEYCLOAK_CONTAINER:-keycloak}"
REALM="mano"
GATEWAY_CLIENT="mano-gateway"

if ! docker inspect "$CONTAINER" >/dev/null 2>&1; then
  echo "error: no container named '$CONTAINER'." >&2
  exit 1
fi

if [ "$(docker inspect -f '{{.State.Running}}' "$CONTAINER")" != "true" ]; then
  echo "error: container '$CONTAINER' exists but is not running." >&2
  echo "       Start it with: docker start $CONTAINER" >&2
  exit 1
fi

echo "==> Registering the mobile clients in realm '$REALM'"

docker exec -i \
  -e MANO_REALM="$REALM" \
  -e MANO_GATEWAY_CLIENT="$GATEWAY_CLIENT" \
  "$CONTAINER" bash -s <<'INNER'
set -euo pipefail

KCADM=/opt/keycloak/bin/kcadm.sh

create() {
  local description="$1"; shift
  if output=$("$KCADM" create "$@" 2>&1); then
    echo "    created  $description"
  elif grep -qiE 'already exists|Conflict detected|exists with same' <<<"$output"; then
    echo "    exists   $description"
  else
    echo "    FAILED   $description" >&2
    echo "$output" >&2
    return 1
  fi
}

echo "--> Authenticating as the bootstrap admin"
"$KCADM" config credentials \
  --server http://localhost:8080 \
  --realm master \
  --user "$KC_BOOTSTRAP_ADMIN_USERNAME" \
  --password "$KC_BOOTSTRAP_ADMIN_PASSWORD" >/dev/null
echo "    ok"

if ! "$KCADM" get "realms/$MANO_REALM" >/dev/null 2>&1; then
  echo "    FAILED   realm '$MANO_REALM' does not exist." >&2
  echo "             Run libmano-backapp/scripts/setup-keycloak-realm.sh first." >&2
  exit 1
fi

for app in requester provider; do
  client="mano-${app}-app"
  scheme="com.manoinc.mano.${app}"

  echo "--> $client"
  create "client $client" clients -r "$MANO_REALM" \
    -s "clientId=$client" \
    -s enabled=true \
    -s publicClient=true \
    -s standardFlowEnabled=true \
    -s directAccessGrantsEnabled=false \
    -s "redirectUris=[\"${scheme}:/oauth2redirect\"]" \
    -s 'attributes."pkce.code.challenge.method"=S256'

  uuid=$("$KCADM" get clients -r "$MANO_REALM" \
    -q "clientId=$client" --fields id --format csv --noquotes | tr -d '\r')
  if [ -z "$uuid" ]; then
    echo "    FAILED   could not resolve the id of $client" >&2
    exit 1
  fi

  # Ensure PKCE is set even if the client already existed without it.
  # Nested attributes need kcadm's dotted form; a JSON blob here is accepted
  # and silently ignored, which is how this was wrong the first time.
  "$KCADM" update "clients/$uuid" -r "$MANO_REALM" \
    -s 'attributes."pkce.code.challenge.method"=S256' \
    -s directAccessGrantsEnabled=false >/dev/null

  # Read it back rather than assume: a confirmation printed whether or not the
  # thing happened is worse than no confirmation at all.
  #
  # Deliberately not `--fields attributes`: kcadm renders nested maps as `{ }`
  # under field filtering, so that reads as "unset" for a value that is
  # actually present. Fetch the whole object and look at it.
  method=$("$KCADM" get "clients/$uuid" -r "$MANO_REALM" 2>/dev/null \
    | grep -o '"pkce.code.challenge.method" : "S256"' || true)
  if [ -n "$method" ]; then
    echo "    pkce     S256 enforced, password grant disabled"
  else
    echo "    FAILED   PKCE was not applied to $client" >&2
    exit 1
  fi

  create "audience mapper -> $MANO_GATEWAY_CLIENT" \
    "clients/$uuid/protocol-mappers/models" -r "$MANO_REALM" \
    -s "name=${MANO_GATEWAY_CLIENT}-audience" \
    -s protocol=openid-connect \
    -s protocolMapper=oidc-audience-mapper \
    -s "config.\"included.client.audience\"=$MANO_GATEWAY_CLIENT" \
    -s 'config."access.token.claim"=true' \
    -s 'config."id.token.claim"=false'
done
INNER

cat <<'EOF'

==> Done.

Forward the ports to a connected phone, then run either app:

  adb reverse tcp:8080 tcp:8080
  adb reverse tcp:8082 tcp:8082
  cd apps/requester && flutter run
EOF
