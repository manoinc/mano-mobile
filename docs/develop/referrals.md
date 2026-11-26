# Referrals

Professionals bring in professionals. A Proveedor shares an invite link from
Mano Profesionales. The colleague who signs up with it is recorded as their
referral. Once that colleague passes the identity check, the inviter earns
Mano coins, credited once per colleague.

The requester's "¿Tienes un código?" is a different flow. There a client saves
a professional with `linkWorkerByReferralCode` (see [Profiles](profiles.md)).
This page covers provider-to-provider referrals only.

## The link

    https://manoapp.co/r/<code>

Codes are minted by mano-profiles as `RP-` plus eight lowercase hex digits,
for example `RP-bb2cde6b`. `ReferralCode` (mano_domain) parses one from typed
text, from an invite link and from a Play install referrer. It trims the input
and normalises the case, because the backend matches codes exactly. Anything
else is null.

The link base is `ManoConfig.inviteLinkBase`, `https://manoapp.co/r/` by
default. `ManoConfig.inviteLink(code)` builds the link.

## Sharing (provider app)

Perfil → "Invita a un colega" opens the referral sheet:

- **Compartir mi código** (primary) opens the system share sheet
  (`textSharerProvider`, share_plus) with a short invitation, the code and the
  link.
- **Copiar código** copies the code.
- The card offers "Gana N Mano coins por cada colega verificado" whenever a
  reward runs, even with no invites yet. When there is at least one invite, the
  card and the sheet add "N colegas invitados · M verificados".

## Opening the link

| | What happens |
|---|---|
| Provider app installed (Android) | App Link: `autoVerify` intent filter on `https://manoapp.co` with path prefix `/r/`, verified against `/.well-known/assetlinks.json` |
| Provider app installed (iOS) | Universal Link: `applinks:manoapp.co` in `Runner.entitlements`, verified against `/.well-known/apple-app-site-association` |
| Not installed | mano-landing serves `/r/<code>` as a page with the code and a Google Play button carrying `referrer=ref%3D<code>` |
| Installed from that Play button (Android) | On launch the app reads the Play install referrer (`ref=<code>`) |

The app reads links with `app_links`, not with go_router deep links. The link
has to be caught while the onboarding is on screen, and the onboarding sits
outside go_router. The code must also be kept until the account exists, which
go_router has no place for. Flutter's own deep linking is turned off
(`flutter_deeplinking_enabled` and `FlutterDeepLinkingEnabled`), so the
platform does not also push `/r/<code>` as a route.

## Keeping and redeeming the code

`referralInviteProvider` (mano_session) holds the code. The provider app's root
listens to it from the first frame. Its sources are:

1. an invite link (`InviteLinkSource`, adapter `AppLinksInviteLinkSource`),
   whether it launched the app or arrived while the app was running;
2. the Play install referrer (`InstallReferrerSource`, adapter
   `PlayInstallReferrerSource`), Android only. It returns null on iOS, without
   Play services, or when the plugin is missing. A link wins over it;
3. a code typed on the onboarding's review step: "¿Te invitó un colega?
   Escribe su código". A typed code replaces the kept one.

The review step shows the kept code as "Te invitó un colega". Once "Enviar a
revisión" succeeds, the worker profile exists and the onboarding redeems the
code without waiting on it: `WorkerReferralRedeemer.redeem` calls the gateway's
`redeemWorkerReferral`. Success is silent. A refusal shows once as a snackbar
from the root, and the code is then dropped. A refusal never blocks the
onboarding.

| `extensions.code` | `ReferralRedemptionFailure` | Snackbar |
|---|---|---|
| `REFERRAL_NOT_FOUND` | `unknownCode` | No encontramos el código de tu colega. |
| `REFERRAL_SELF` | `ownCode` | Ese código es el tuyo; no cuenta como invitación. |
| `REFERRAL_ALREADY_REDEEMED` | `alreadyRedeemed` | Ya tienes registrado al colega que te invitó. |
| anything else, or an outage | `notSaved` | No pudimos registrar el código de tu colega. |

An existing professional who opens an invite link sees nothing happen. The code
is only redeemed by a new account's onboarding.

## Backend contract

| Call | Used by |
|---|---|
| `mutation redeemWorkerReferral(code: String!): WorkerProfile!` | `GatewayWorkerReferralRedeemer` |
| `WorkerProfile.referralsCount: Int!`, `WorkerProfile.verifiedReferralsCount: Int!` | `ReferralProgram.invited`, `.verified` |
| `Query.referralReward { coinsPerColleague: Int! }` (billing config, default 10) | `ReferralProgram.coinsPerColleague` |
| `CoinMovement.type = REFERRAL_BONUS` | Billetera: "Bono por referido" |

The referral fields are read by a query of their own
(`GatewayProviderProfileRepository.referral`). A gateway without them loses only
the referral card, not the profile. Offline, `MockWorkerReferralRedeemer`
accepts `RP-c011ea9e`, refuses `RP-0000a11e` as your own code, and reports any
other code as unknown.

## Before it works live

- **Deploy mano-landing** with `/r/*`, `public/.well-known/` and the `_headers`
  rule. Until then, Android cannot verify the App Link. A tapped link then opens
  the browser, or a chooser on older Android.
- **Release signing.** `assetlinks.json` carries only the debug keystore's
  SHA-256. Add the release key's SHA-256 and the Play App Signing key's
  SHA-256 (Play Console → App integrity) before launch.
- **Apple Team ID.** `apple-app-site-association` has `TEAMID_PLACEHOLDER`.
  Replace it with the Team ID and set the team in Xcode, or iOS will not open
  the app from the link.
- **Store listings.** The Play button points at
  `com.manoInc.manoprofesional`, which must be published, at least on a testing
  track, before the install referrer carries anything. The App Store button
  appears once `appStoreUrl` is set in mano-landing's `src/data/referral.ts`.
- **Backend.** The mobile app needs `redeemWorkerReferral`, the two counts and
  `referralReward` on the gateway. Ship the gateway first.

## Testing on the A36

Install a debug build of the provider app, then:

```bash
# Opens the app straight away; works before the landing is deployed.
adb shell am start -a android.intent.action.VIEW \
  -d https://manoapp.co/r/RP-bb2cde6b com.manoInc.manoprofesional

# Once the landing is deployed: is the domain verified?
adb shell pm get-app-links com.manoInc.manoprofesional
adb shell pm verify-app-links --re-verify com.manoInc.manoprofesional

# Without the package name, the system decides; "verified" opens the app.
adb shell am start -a android.intent.action.VIEW -d https://manoapp.co/r/RP-bb2cde6b
```

Walk the onboarding to the review step. It should show "Te invitó un colega ·
RP-bb2cde6b". The install referrer can only be tested with an install from
Play, for example from an internal testing track.
