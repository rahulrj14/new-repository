# Draft: Family Controls entitlement request

**Submit from:** your Apple Developer account, using the "Family Controls & Personal Device Usage" entitlement request form, linked from the Family Controls framework docs on developer.apple.com.

**Needed for:** TestFlight and App Store builds. Development builds on your own devices can use the capability without approval.

---

**App name:** Lock In

**Entitlement:** `com.apple.developer.family-controls`

**Authorization type:** Individual (`AuthorizationCenter.requestAuthorization(for: .individual)`). The person using the app authorises it for their own device, not a parent for a child.

**How the app uses it:**

> Lock In helps friends in the same room put their phones down together. During a focus session the user chooses to start, we use DeviceActivity to set a single threshold event ("any app used for 1 minute"). When it fires, our DeviceActivityMonitor extension writes a single flag to the app's App Group container. The app uses that flag to mark the user's own session as "interrupted".
>
> We do not shield or block any apps. We do not read, store or transmit app names, tokens or usage history. Nothing leaves the device: the app has no server, no accounts and no analytics. The feature is optional and off by default. Users turn it on in Settings with a plain explanation, and they can turn it off at any time.

**Data handling:** All processing is on the device. The privacy label is "Data Not Collected".

**Audience:** ages 13 and over. The app follows the UK Age Appropriate Design Code.
