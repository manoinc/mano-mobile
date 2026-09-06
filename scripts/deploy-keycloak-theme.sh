#!/usr/bin/env bash
#
# Installs Mano's login theme into the local Keycloak and points the realm at
# it.
#
# The container has no volume mounted, so the theme is copied in. That survives
# `docker restart` but not `docker rm` -- re-run this after recreating the
# container, exactly as you would re-run setup-keycloak-realm.sh.
#
# Idempotent: copies over whatever is there and re-applies the realm setting.
#
# Usage:
#   ./scripts/deploy-keycloak-theme.sh
#
# Environment:
#   KEYCLOAK_CONTAINER   container name (default: keycloak)
#   MANO_REALM           realm to brand  (default: mano)

set -euo pipefail

CONTAINER="${KEYCLOAK_CONTAINER:-keycloak}"
REALM="${MANO_REALM:-mano}"
THEME="mano"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="$REPO_ROOT/keycloak-theme/$THEME"

if [ ! -d "$SOURCE" ]; then
  echo "error: no theme at $SOURCE" >&2
  exit 1
fi

if ! docker inspect "$CONTAINER" >/dev/null 2>&1; then
  echo "error: no container named '$CONTAINER'." >&2
  exit 1
fi

if [ "$(docker inspect -f '{{.State.Running}}' "$CONTAINER")" != "true" ]; then
  echo "error: container '$CONTAINER' exists but is not running." >&2
  echo "       Start it with: docker start $CONTAINER" >&2
  exit 1
fi

echo "==> Copying the theme into '$CONTAINER'"
docker exec "$CONTAINER" rm -rf "/opt/keycloak/themes/$THEME"
docker cp "$SOURCE" "$CONTAINER:/opt/keycloak/themes/$THEME"
echo "    /opt/keycloak/themes/$THEME"

# Confirm the files actually landed. `docker cp` is quiet about a partial copy,
# and a theme missing its stylesheet renders as unstyled Keycloak rather than
# as an error -- which looks like the theme "not applying" and sends you
# hunting in the wrong place.
missing=0
for f in "login/theme.properties" "login/resources/css/mano.css" "login/resources/fonts/poppins-400.woff2"; do
  if ! docker exec "$CONTAINER" test -f "/opt/keycloak/themes/$THEME/$f"; then
    echo "    MISSING  $f" >&2
    missing=1
  fi
done
[ "$missing" -eq 0 ] || { echo "error: the theme copied incompletely." >&2; exit 1; }
echo "    files verified"

echo "==> Pointing realm '$REALM' at it"
docker exec -i -e MANO_REALM="$REALM" -e MANO_THEME="$THEME" "$CONTAINER" bash -s <<'INNER'
set -euo pipefail
KCADM=/opt/keycloak/bin/kcadm.sh

"$KCADM" config credentials \
  --server http://localhost:8080 --realm master \
  --user "$KC_BOOTSTRAP_ADMIN_USERNAME" --password "$KC_BOOTSTRAP_ADMIN_PASSWORD" >/dev/null

# The theme ships Spanish copy, which Keycloak only serves once the realm has
# internationalisation switched on and Spanish as its default. Without this the
# realm falls back to English and the translations are dead files.
#
# Spanish is the only supported locale, which is deliberate: Mano launches in
# Colombia, and listing a second one makes Keycloak render a language picker
# above the form. It also stops a phone set to English from being served the
# untranslated Keycloak defaults.
"$KCADM" update "realms/$MANO_REALM" \
  -s "loginTheme=$MANO_THEME" \
  -s internationalizationEnabled=true \
  -s 'supportedLocales=["es"]' \
  -s defaultLocale=es >/dev/null

# Read it back. A confirmation printed whether or not the thing happened is
# worse than no confirmation at all.
applied=$("$KCADM" get "realms/$MANO_REALM" --fields loginTheme --format csv --noquotes | tr -d '\r"')
locale=$("$KCADM" get "realms/$MANO_REALM" --fields defaultLocale --format csv --noquotes | tr -d '\r"')
if [ "$applied" = "$MANO_THEME" ]; then
  echo "    loginTheme = $applied"
  echo "    defaultLocale = $locale"
else
  echo "    FAILED   loginTheme is '$applied', expected '$MANO_THEME'" >&2
  exit 1
fi
INNER

cat <<EOF

==> Done.

Keycloak runs in dev mode, so theme caching is off and a reload picks up CSS
changes immediately. Preview the page without going through an app:

  http://localhost:8080/realms/$REALM/protocol/openid-connect/auth\\
?client_id=mano-requester-app\\
&redirect_uri=com.manoinc.mano.requester:/oauth2redirect\\
&response_type=code\\
&scope=openid

EOF
