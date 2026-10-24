# Launch checklist

These are the steps only you can do, because they need your accounts, payments or legal
details. Everything else is already done in the code. Do them roughly in this order.

## 1. Accounts (week 1)

- [ ] **Google Play Console**: sign up at <https://play.google.com/console> ($25 once).
      Pick a *personal* account unless you have a registered business. Google verifies
      your ID, which can take a few days.
- [ ] **Apple Developer Program**: enroll at <https://developer.apple.com/programs/enroll/>
      ($99/year). Use the Apple ID you want the app published under.
- [ ] **AdMob**: sign up at <https://admob.google.com> with the same Google account. Add your
      payment details (Payments > Settings) so you can actually get paid.
- [ ] **Codemagic**: sign up at <https://codemagic.io> with GitHub and add the `BoxFort` repo.
      The free tier is enough to start. This builds the iOS app for you, no Mac needed.

> Important for Play: Google needs a personal account to run a **closed test with at least
> 12 testers for 14 days** before you can publish to everyone. Start collecting 12 friends'
> Gmail addresses now.

## 2. Turn on GitHub Pages (5 minutes)

- [ ] In the repo, go to **Settings > Pages** and set **Source** to **GitHub Actions**.
- [ ] Open `docs/privacy.html` and replace `YOUR-EMAIL@example.com` with a contact email.
- [ ] After the next push, your links will be:
  - Web preview: `https://prishasophatii.github.io/BoxFort/`
  - Privacy policy: `https://prishasophatii.github.io/BoxFort/privacy.html`

  Both stores require the privacy policy link.

## 3. AdMob setup

- [ ] In AdMob, **Apps > Add app**, twice: once for Android, once for iOS (choose "not
      published yet"). Name them "Box Fort".
- [ ] For each app create three ad units: **Banner**, **Interstitial**, **Rewarded**
      (reward: 2 hints).
- [ ] Send me the IDs (they are not secret), or paste them yourself:
  - App IDs (`ca-app-pub-…~…`) go in `android/app/src/main/AndroidManifest.xml` and
    `ios/Runner/Info.plist`, replacing Google's test IDs.
  - Ad unit IDs (`ca-app-pub-…/…`) go in `lib/services/ad_ids.dart`.
- [ ] **Privacy & messaging**: create a **GDPR** message (EU/UK consent) and an **IDFA
      explainer** for iOS. The app already shows them when they're needed.
- [ ] After the app is live, link it to its store listing in AdMob (App settings) and
      create an `app-ads.txt` file. I can add it to GitHub Pages for you.
- [ ] **Never tap your own ads.** Debug builds always use test ads, so you're safe while
      testing.

## 4. Google Play release

- [ ] In Play Console, **Create app**: name "Box Fort", Game, Free, contains ads: **Yes**.
- [ ] Fill in **App content**: privacy policy URL, ads = yes, target audience **13+** (don't
      select under 13, that triggers stricter "Families" ad rules), data safety (see below),
      content rating questionnaire (it's a puzzle game, so you'll get "Everyone").
- [ ] **Data safety** answers: data is collected by the AdMob SDK: *Device or other IDs*
      (advertising), *App interactions* and *Diagnostics*; used for advertising and analytics;
      shared with Google; encrypted in transit; users can't request deletion because there are
      no accounts.
- [ ] **Signing**: in Codemagic, **Team settings > Code signing identities > Android
      keystores**, click *Generate keystore* (or upload one) and name it
      `boxfort_upload_key`. **Download and back it up somewhere safe.** If it's lost,
      updating the app becomes painful.
- [ ] **Upload API access**: create a Google Cloud service account with Play Console access
      (Codemagic's guide: <https://docs.codemagic.io/yaml-distribution/google-play-publishing/>),
      and add its JSON key in Codemagic as `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS` in a variable
      group named `google_play`.
      The very first `.aab` must be uploaded by hand in Play Console. Download it from the
      first Codemagic build.
- [ ] Add the store listing from `docs/STORE_LISTING.md`, the icon (`assets/icon/icon.png`,
      resized to 512×512), a 1024×500 feature graphic and at least 4 phone screenshots.
- [ ] Run the **closed test** (12+ testers, 14 days), then apply for production.

## 5. App Store release

- [ ] In **App Store Connect > Apps > +**, create "Box Fort" with bundle ID
      `com.prishasophatii.boxfort` (register it first under Certificates, Identifiers &
      Profiles > Identifiers if it isn't offered).
- [ ] **Users and Access > Integrations > App Store Connect API**: create a key with
      *App Manager* access. Add it in Codemagic (Team integrations) named `BoxFort ASC key`.
- [ ] In Codemagic, add an environment variable `APP_STORE_APPLE_ID` with the app's Apple ID
      number (App Store Connect > App Information).
- [ ] Fill in the listing from `docs/STORE_LISTING.md`, the privacy policy URL, the App
      Privacy questionnaire (same answers as Play's data safety, plus "used to track you":
      yes, for advertising) and age rating (4+).
- [ ] Screenshots: 6.9" iPhone (1320×2868) is required. I can generate these for you.
- [ ] Build arrives in TestFlight. Test it, then **Submit for Review**. Reviews usually take
      1–3 days.

## 6. Shipping a build

Builds start when you push a version tag:

```sh
git tag v1.0.0 && git push origin v1.0.0
```

Codemagic then builds both apps, sends Android to the Play internal track and iOS to
TestFlight. Bump `version:` in `pubspec.yaml` for each new release.

## Things you might want to change before the first upload

- **App ID** `com.prishasophatii.boxfort`: it can't be changed after the first upload.
- **Name**: "Box Fort" is used in the app, icon label and listings. Search both stores
  first to make sure nobody else uses it for a game.
