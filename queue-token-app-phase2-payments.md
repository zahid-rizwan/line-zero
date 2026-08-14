# Project Scope — Phase 2: Payments & Subscriptions

**Builds on:** the core Queue Token System (Phase 1 — see `queue-token-app-scope.md`). This document covers adding a free-trial-then-paid-subscription model for shop owners.

**Model:** Every shop gets a 30-day free trial when created. After the trial, the shop owner must subscribe (monthly or yearly) to keep using queue management features. Customers are never charged — only shop owners.

---

## 1. Payment Approach & Why

**Chosen approach: Google Play Billing** (via the Flutter `in_app_purchase` package), not a direct third-party gateway like Razorpay integrated inside the app.

**Why not just integrate Razorpay directly in-app?**
Google Play policy requires that purchases unlocking **in-app digital content or features** go through Play Billing (or the newer "alternative billing" option, where available) — regardless of whether the third-party checkout is shown via a WebView, an external browser redirect, or an SDK. The policy is based on *what* is being purchased (in-app feature access), not *how* the payment technically happens. Using Razorpay directly for this purpose risks app rejection or suspension.

**Where a direct gateway IS allowed:** payments for something consumed **outside** the app in the real world (e.g. a food order, a cab ride) don't need Play Billing. This app's subscription doesn't qualify — it unlocks in-app dashboard features — so Play Billing applies.

💡 **Fee reality (verified current, mid-2026):** subscriptions carry a **10% service fee + 5% billing fee ≈ 15% effective** through Play Billing — not the commonly assumed 30% (that rate applies to one-time in-app purchases, not subscriptions). Where "alternative billing" is available in your region, routing through your own processor drops Google's cut to just the 10% service fee, at the cost of your processor's own fee (~2–3%) and extra implementation complexity. Recommendation for launch: start with standard Play Billing.

---

## 2. Firestore Schema Addition

```
/shops/{shopId}/subscription/current
    status: string              // "trial" | "active" | "expired" | "cancelled"
    plan: string | null         // "monthly" | "yearly" | null
    trialEndsAt: timestamp
    currentPeriodEnd: timestamp | null
    playPurchaseToken: string | null   // from Play Billing, used to verify/manage the subscription
    createdAt: timestamp
    updatedAt: timestamp
```

💡 Keep this as a subcollection document (`/shops/{shopId}/subscription/current`) rather than fields on the shop document itself — it isolates billing data, makes security rules simpler to scope (only the owner + backend functions should read/write this), and keeps the shop document lean for the more frequently-read public fields (name, category, isQueueOpen).

---

## 3. End-to-End Flow

1. **Shop created** → Cloud Function trigger (`onCreate` on `/shops/{shopId}`) automatically creates the subscription doc with `status = "trial"`, `trialEndsAt = now + 30 days`.
2. **Trial reminders** → scheduled Cloud Function (runs daily) checks shops with `trialEndsAt` 5 days or 1 day away, sends an FCM push: "Your free trial ends soon."
3. **Trial expiry** → same daily scheduled function flips `status` to `"expired"` once `trialEndsAt < now` (if still on trial, not yet subscribed).
4. **App checks status on load** → if `status == "expired"`, show a paywall screen; block access to queue management actions (call next / skip / open-close queue) until resolved. Read-only dashboard access can remain if you want a softer paywall.
5. **Owner subscribes** → paywall screen offers monthly/yearly plans → tapping "Subscribe" triggers the native Play Billing purchase dialog (never build a custom checkout UI — Play Billing purchase UI is provided by the OS/Play Store app itself).
6. **Purchase completes** → app receives a purchase token from `in_app_purchase` → sends it to a Cloud Function (`verifyPurchase`).
7. **Server-side verification** → the Cloud Function calls the **Play Developer API** to confirm the token is genuine and active — **never trust the client's "purchase successful" callback alone**, since that can be spoofed. Only after server verification does Firestore get updated to `status = "active"`.
8. **Ongoing lifecycle events** → Play Billing sends **Real-time Developer Notifications (RTDN)** to a Pub/Sub topic on renewal, cancellation, grace period, or payment failure. A Cloud Function subscribed to this topic updates the Firestore subscription doc accordingly (e.g. `status = "expired"` on cancellation, updated `currentPeriodEnd` on renewal).

```
Shop created
    │
    ▼
trial (30 days) ──reminder pushes──► trial ending soon
    │
    ▼ (time passes, no subscription)
expired ──► Paywall screen shown, queue actions blocked
    │
    ▼ (owner subscribes)
Play Billing purchase dialog
    │
    ▼ (purchase token received)
Cloud Function verifies token server-side (Play Developer API)
    │
    ▼
active ──► RTDN events keep status in sync (renew / cancel / fail)
```

---

## 4. Paywall Screen — Design Notes

Following the app's existing design system (Trust Blue `#2C6FB0`, Amber `#D89419`, Coral Red `#D85A30`):

- **Trigger state:** shown when `subscription.status == "expired"`, replacing or overlaying the owner dashboard.
- **Content:** shop name, a clear "Your trial has ended" message, side-by-side monthly vs yearly plan cards (yearly should visually highlight the savings — e.g. a small "Save 20%" badge in Amber), and a single "Subscribe" button per plan.
- **Tone:** informative, not punishing — reassure the owner their data (shop profile, queue history) is safe and will be available immediately after subscribing.
- **Never build a custom payment form here** — the "Subscribe" button's only job is to trigger the native Play Billing flow.

---

## 5. Task Breakdown (Suggested — 2 Weeks)

### Week 1 — Trial Lifecycle & Paywall UI
- [ ] Add `subscription` subcollection schema
- [ ] Cloud Function: `onCreate` trigger on shop creation → auto-assign 30-day trial
- [ ] Cloud Function: scheduled daily job — trial reminder pushes (day 25, day 29) + expiry flip
- [ ] Firestore security rules for the `subscription` subcollection (owner can read their own; only Cloud Functions — via Admin SDK — can write status/plan fields)
- [ ] Paywall screen UI: plan cards, "Subscribe" CTAs, trial-ended messaging
- [ ] Trial status badge on owner dashboard header ("18 days left in trial" / "Trial ended")

### Week 2 — Play Billing Integration
- [ ] Create subscription products in Google Play Console (monthly + yearly), set pricing
- [ ] Add `in_app_purchase` package, wire up purchase stream listener
- [ ] Trigger native purchase flow from paywall "Subscribe" buttons
- [ ] Cloud Function: `verifyPurchase` — server-side token verification via Play Developer API
- [ ] Set up RTDN: Pub/Sub topic + Cloud Function subscriber for renewal/cancellation/failure events
- [ ] Test full flow using Play Console's **license testing** track (sandbox purchases, no real charges)
- [ ] Handle edge cases: purchase pending state, network failure mid-purchase, restoring a previous purchase after reinstall

---

## 6. Testing Checklist

- [ ] New shop → confirm 30-day trial auto-assigned
- [ ] Manually set `trialEndsAt` to a past date (test data) → confirm daily function flips status to `expired`
- [ ] Confirm paywall appears and queue actions are blocked when expired
- [ ] Complete a sandbox purchase (monthly) → confirm `status` flips to `active` only after server verification, not immediately on client callback
- [ ] Cancel the sandbox subscription from Play Store's test environment → confirm RTDN updates Firestore correctly
- [ ] Reinstall the app on a test device with an active subscription → confirm "restore purchases" correctly re-activates access

---

## 7. What to Say About This in an Interview

- **Policy compliance:** "I used Google Play Billing instead of integrating a gateway like Razorpay directly, because Play Store policy ties the requirement to what's being purchased — in-app feature access — not to the technical payment path. A WebView-based Razorpay checkout for the same purpose would still violate the policy."
- **Security:** "Purchase tokens are verified server-side against the Play Developer API in a Cloud Function before any Firestore status update — the client's purchase-success callback is never trusted directly, since it could be spoofed."
- **Event-driven lifecycle:** "Subscription renewals, cancellations, and payment failures are handled via Play Billing's Real-time Developer Notifications rather than polling — the same webhook-driven pattern I used for the queue's real-time updates, applied to billing state."
- **Cost awareness:** "I checked current Play Billing fees rather than assuming the commonly-cited 30% — subscriptions are ~15% effective (10% service + 5% billing fee), which changes the unit economics discussion significantly."
