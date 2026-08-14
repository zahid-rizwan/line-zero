# Project Scope: Real-Time Queue Token System

**Problem statement:** People waiting outside shops/clinics have no visibility into their queue position, causing physical crowding and wasted time. This app lets a shop owner manage a live digital queue, and lets customers track their position remotely in real time.

**Stack:** Flutter (clean architecture) + Firebase (Firestore, Auth, FCM, Cloud Functions) — zero server cost, deployable to Play Store.

---

## 1. User Roles

| Role | Can do |
|---|---|
| **Shop Owner** | Create shop profile, open/close queue, call next customer, remove/skip a customer, view queue history |
| **Customer** | Browse nearby/saved shops, join a queue, see live position, get notified when their turn is near, leave a queue |

---

## 2. Firestore Schema

```
/shops/{shopId}
    name: string
    category: string           // "clinic", "salon", "repair", etc.
    ownerId: string            // ref to users/{uid}
    address: string
    location: geopoint
    isQueueOpen: boolean
    avgServiceTimeMinutes: number
    createdAt: timestamp

/shops/{shopId}/queue/{ticketId}
    customerId: string
    customerName: string
    tokenNumber: number
    status: string              // "waiting" | "in_service" | "completed" | "skipped" | "cancelled"
    joinedAt: timestamp
    calledAt: timestamp | null

/users/{uid}
    name: string
    role: string                 // "owner" | "customer"
    fcmToken: string
    phone: string

/shops/{shopId}/history/{ticketId}   // completed tokens, for owner analytics (optional/stretch)
    ...same fields as queue, archived on completion
```

💡 **Design notes:**
- `tokenNumber` is a simple incrementing counter per shop per day — use a Firestore transaction when creating a ticket to avoid duplicate numbers under concurrent joins.
- Customers listen to `shops/{shopId}/queue` filtered by `status == waiting`, ordered by `tokenNumber` — their position = index in that ordered list. This is what gives you "3 people ahead of you" without extra computation.
- Use a Cloud Function (Firestore trigger `onUpdate`) to send FCM push when a customer's computed position drops to ≤2 — avoids doing this client-side for every listener.

---

## 3. Feature Breakdown (MVP vs Stretch)

**MVP (build this first — this is what goes on your resume/demo):**
- Phone number auth (Firebase Auth)
- Shop owner: create shop, open/close queue, call next / skip
- Customer: search shop by name, join queue, live position tracker, leave queue
- Push notification when position ≤ 2

**Stretch (add if time allows, mention as "future work" in resume/interview):**
- Geolocation-based "shops near me"
- Estimated wait time (based on `avgServiceTimeMinutes` × people ahead)
- Queue history / analytics for shop owner
- Ratings/reviews for shops
- Multiple queue "counters" per shop (e.g., 2 doctors in a clinic)

---

## 4. Flutter App Structure (Clean Architecture)

```
lib/
├── core/
│   ├── firebase/          # FirebaseAuth, Firestore instance setup
│   └── error/
└── features/
    ├── auth/
    │   ├── domain/  (entities: UserEntity; usecases: SignIn, SignOut)
    │   ├── data/    (FirebaseAuthDataSource, UserRepositoryImpl)
    │   └── presentation/
    ├── shop/
    │   ├── domain/  (entities: ShopEntity; usecases: CreateShop, ToggleQueue)
    │   ├── data/    (ShopRemoteDataSource using Firestore, ShopRepositoryImpl)
    │   └── presentation/ (owner dashboard screens)
    └── queue/
        ├── domain/  (entities: TicketEntity; usecases: JoinQueue, LeaveQueue, WatchQueuePosition)
        ├── data/    (QueueRemoteDataSource — wraps Firestore snapshots() as a Stream)
        └── presentation/ (customer queue screen, live position widget)
```

💡 Same pattern as the REST/WebSocket examples earlier — `QueueRemoteDataSource` wraps Firestore's `snapshots()` stream instead of a WebSocket, but the domain/presentation layers don't care where the stream comes from. This is a good interview point: "I used the same clean architecture regardless of whether real-time data came from WebSockets or Firestore — the abstraction doesn't change."

---

## 5. Task Breakdown (Suggested 4-Week Plan)

### Week 1 — Setup & Auth
- [ ] Create Firebase project, enable Firestore, Auth (Phone), Cloud Messaging
- [ ] Set up Flutter project with clean architecture folder structure
- [ ] Implement phone number auth (OTP flow)
- [ ] Build role selection screen (Owner vs Customer) on first login
- [ ] Set up Firestore security rules (owners can only edit their own shop; customers can only create/cancel their own tickets)

### Week 2 — Shop Owner Side
- [ ] Create shop profile screen (name, category, address)
- [ ] Owner dashboard: live queue list (StreamBuilder on `queue` collection, ordered by `tokenNumber`)
- [ ] "Call Next" button → updates ticket status to `in_service`
- [ ] "Skip" / "Complete" actions on a ticket
- [ ] Open/close queue toggle

### Week 3 — Customer Side
- [ ] Shop search/list screen (simple text search on shop name to start; geolocation is stretch)
- [ ] Shop detail screen with "Join Queue" button
- [ ] Firestore transaction to safely assign next `tokenNumber`
- [ ] Live position tracker screen (Stream showing "X people ahead of you")
- [ ] Leave queue / cancel ticket action

### Week 4 — Notifications, Polish, Deploy
- [ ] Cloud Function: on queue update, compute positions and send FCM when a customer is ≤2 away
- [ ] Handle edge cases: app in background, notification tap → deep link to queue screen
- [ ] Error/empty states, loading states across all screens
- [ ] App icon, splash screen, basic branding
- [ ] Generate signed APK/App Bundle, write Play Store listing (description, screenshots, privacy policy — required even for free apps)
- [ ] Submit for Play Store review

---

## 6. Firestore Security Rules (Starting Point)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    match /shops/{shopId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == resource.data.ownerId;
      allow create: if request.auth != null;

      match /queue/{ticketId} {
        allow read: if request.auth != null;
        allow create: if request.auth != null && request.auth.uid == request.resource.data.customerId;
        allow update: if request.auth != null; // refine: owner OR the ticket's own customer
      }
    }

    match /users/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```

⚠️ Tighten the `queue` update rule before shipping — right now any authenticated user could update any ticket. Restrict it so only the shop's `ownerId` can change `status` to `in_service`/`completed`/`skipped`, and only the ticket's own `customerId` can cancel their own ticket.

---

## 7. Cost Check (Firebase Spark/Free Tier Limits)

| Service | Free tier limit | Should be enough because |
|---|---|---|
| Firestore | 50K reads, 20K writes, 20K deletes / day | Small-scale demo/local shop usage won't come close |
| Cloud Functions | 2M invocations/month (requires Blaze plan to even deploy functions, but usage stays within free quota) | Position-check trigger only fires on queue updates |
| FCM | Unlimited, free | No concern |
| Auth (Phone) | Free tier has a monthly SMS quota (varies by country) | Fine for demo/testing; watch this if you get real users |

⚠️ **Note:** Cloud Functions technically requires upgrading to the **Blaze (pay-as-you-go)** plan to deploy at all, even though usage within free-tier limits costs $0. If you want to stay 100% on Spark with zero risk, skip Cloud Functions for the notification trigger and instead compute position client-side in the customer's app (slightly less clean, but avoids the Blaze requirement entirely) — happy to show that version if you'd prefer it.

---

## 8. UI/UX Design & Color Palette

### Design Principles for a Queue App

💡 A queue app's core job is to **reduce anxiety about waiting** — the UI should constantly answer "where do I stand, and how long more?" without the user having to dig for it. Three principles drive the design choices below:

- **Status clarity over decoration** — the ticket status (waiting / in-service / completed) should be readable at a glance, mainly through color, not just text.
- **Calm, not stressful** — waiting is already mildly stressful; avoid aggressive reds/alarms except for genuine action-needed moments (like "your turn now").
- **High contrast, large numbers** — token numbers and position counts are the most-glanced-at info; they should be the largest, boldest text on screen.

### Recommended Color Palette

| Role | Color | Hex | Usage |
|---|---|---|---|
| Primary (brand) | Teal | `#0F766E` | App bar, primary buttons, active nav, logo |
| Primary Light | Soft Teal | `#CCFBF1` | Card backgrounds, selected states |
| Secondary (accent) | Warm Amber | `#F59E0B` | "In Service" status, highlights, CTA on light backgrounds |
| Success | Green | `#16A34A` | "Completed" status, confirmation states |
| Warning/Urgent | Coral Red | `#EF4444` | "Your turn now!" alert, cancel/skip actions — used sparingly |
| Neutral Dark | Charcoal | `#1F2937` | Primary text |
| Neutral Mid | Slate Gray | `#6B7280` | Secondary text, timestamps, helper text |
| Neutral Light | Off-White | `#F9FAFB` | Screen background |
| Border/Divider | Light Gray | `#E5E7EB` | Card borders, dividers |

💡 **Why teal + amber instead of the generic blue-and-orange most tutorial apps use:** teal reads as trustworthy and calm (good for a "waiting" context — think healthcare/wellness apps) without being as overused as blue. Amber for "in service" sits between the calm teal and urgent red, giving you a natural 3-step visual progression: **teal (waiting) → amber (in service) → green (done)** — the color itself tells the status story, which is a nice detail to point out in an interview.

### Status → Color Mapping (Core UX Pattern)

```
waiting     → Teal badge   (#0F766E)
in_service  → Amber badge  (#F59E0B)
completed   → Green badge  (#16A34A)
skipped     → Gray badge   (#6B7280)
cancelled   → Gray badge, strikethrough text
```

Use this mapping consistently across the queue list (owner side) and the ticket card (customer side) — same color always means the same status, everywhere in the app.

### Typography

- **Font:** a clean geometric sans-serif — `Inter` or `Poppins` (both free on Google Fonts, easy to add via `google_fonts` Flutter package) work well; Poppins feels slightly friendlier, Inter feels slightly more "utility app."
- **Token number display:** largest text on screen, 48–64sp, bold — this is the one thing a waiting customer stares at.
- **Position text** ("3 people ahead of you"): 20–24sp, medium weight.
- **Body/labels:** 14–16sp, regular weight, Charcoal or Slate Gray.

### Dark Mode (Stretch, but easy with this palette)

This palette maps cleanly to dark mode: swap Off-White background for `#111827`, Charcoal text for `#F3F4F6`, and keep the teal/amber/green status colors as-is (they hold enough contrast on dark backgrounds without adjustment) — worth mentioning in an interview as a "designed for theming from day one" detail, even if you only ship light mode initially.

### Screen-Specific Notes

- **Customer live position screen:** teal background card with the token number in white, huge font, centered — make this the visual anchor of the whole app.
- **Owner dashboard queue list:** each row = customer name + token number + status badge (colored per the mapping above) + action buttons; keep the "Call Next" button in solid teal, always visible without scrolling (e.g., pinned bottom button).
- **"Your turn" push notification / in-app banner:** the one place to use the coral red/amber combo more boldly — this is the moment the color should demand attention.

---

## 9. What to Say About This in an Interview

- **Real-time design:** "I used Firestore's `snapshots()` stream instead of polling, so queue position updates push to the client instantly — same real-time principle as WebSockets, but I chose Firestore here since it fit a serverless, zero-cost deployment better than running my own Django Channels server."
- **Concurrency handling:** "Token number assignment uses a Firestore transaction to prevent two customers getting the same number if they join simultaneously."
- **Architecture:** "Domain and presentation layers don't know whether data comes from Firestore or a REST API — only the data source layer does, which made it easy to reason about and test."
- **Design decisions:** "I mapped ticket status directly to a color progression — teal for waiting, amber for in-service, green for completed — so the UI communicates state at a glance without relying on users reading text labels."
