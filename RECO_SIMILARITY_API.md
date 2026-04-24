# Reco & Similarity — Frontend Integration Guide

Integration spec for Phases 1–4 built in `ProductClientService`.
Base URL: `ApiEndpoints.productServiceBase` (default `http://localhost:8081`).
All endpoints accept the usual `Authorization: Bearer <JWT>` via `auth_interceptor.dart`, except where explicitly noted as **guest-allowed**.

Keep mobile payloads ≤10 KB. Always pass `k` (default 20). Handle empty `items: []` gracefully — backend may be in degraded mode during an incident.

---

## Add these to `api_endpoints.dart`

```dart
// ── Tracking (Phase 1) ────────────────────────────────────────────────────
static const String trackInteraction = '/api/v1/track/interaction';

// ── Similarity (Phase 2) ──────────────────────────────────────────────────
static String similarProducts(String productId) =>
    '/api/v1/product/$productId/similar';

// ── Recommendations (Phase 3) ─────────────────────────────────────────────
static const String recoForYou   = '/api/v1/reco/for-you';
static const String recoFeedback = '/api/v1/reco/feedback';
```

---

## Phase 1 — Interaction tracking

### `POST /api/v1/track/interaction`  *(guest-allowed)*

Batch up to **20** events per call. Buffer events client-side and flush every ~5s or on backgrounding.

**Request**
```json
{
  "sessionId": "a1b2c3d4-...",
  "events": [
    {
      "productId": "uuid",
      "type": "VIEW",
      "context": "HOME",
      "source": "home_feed",
      "dwellMs": 1800,
      "ts": "2026-04-24T10:15:32.120Z"
    }
  ]
}
```

**`type` values** (send these exact strings):
`VIEW`, `CLICK`, `ADD_TO_CART`, `REMOVE_FROM_CART`, `WISHLIST`, `SHARE`,
`BEGIN_CHECKOUT`, `PURCHASE_PREPAID`, `PURCHASE_COD`, `CANCEL`, `RETURN`.
COD purchases carry a heavier signal weight than prepaid — send the correct variant.

**`context` values**: `HOME` | `PDP` | `CART` | `SEARCH` | `CATEGORY`.

**`source`** (free-form tag): e.g. `reco:<recoId>` when the click originated from a for-you response; `similar:<variant>` when from a PDP similar rail. See "Attribution" below.

**Response**: `202 Accepted`. Fire-and-forget — do **not** block UI on this.

### What the frontend must do
- Generate `sessionId` once per app launch (UUID v4), persist in memory only.
- Timestamp every event on the client (`DateTime.now().toUtc().toIso8601String()`).
- If offline, queue up to ~200 events and drop oldest; never block user actions.
- Always track `VIEW` with `dwellMs` when the user scrolls a product into view for >500ms.

---

## Phase 2 — Similar products (PDP rails)

### `GET /api/v1/product/{productId}/similar?variant={V}&k=20`

Drives the three PDP rails.

**`variant`** (required):
| Variant           | Rail label suggestion         |
|-------------------|-------------------------------|
| `ALSO_VIEWED`     | "Customers also viewed"       |
| `COMPLETE_LOOK`   | "Complete the look"           |
| `SIMILAR_CHEAPER` | "Similar items, lower price"  |

**Response**
```json
{
  "success": true,
  "data": {
    "productId": "uuid",
    "variant": "ALSO_VIEWED",
    "modelVersion": "mlt_v1",
    "items": [
      {
        "productId": "uuid",
        "title": "…",
        "pricePaise": 129900,
        "discountPct": 12,
        "thumbnailUrl": "https://…",
        "avgRating": 4.3,
        "score": 7.81
      }
    ]
  }
}
```

### Frontend notes
- Call all 3 variants in **parallel** when PDP opens. Render whichever returns first; others populate on arrival.
- Cache in memory for the PDP lifetime — the backend already caches 6h, so re-fetching on nav back is fine.
- When a user taps an item from a similar rail, send tracking with `source: "similar:ALSO_VIEWED"` (etc.) so attribution flows through.
- Empty `items: []` → hide the rail, do not show a skeleton forever.

---

## Phase 3 — Personalised recommendations (Home "For You")

### `GET /api/v1/reco/for-you?context=HOME&k=20`

**Query**
- `context`: `HOME` | `PDP` | `CART` (matches what you pass in tracking).
- `k`: 1–50, default 20.

**Response**
```json
{
  "success": true,
  "data": {
    "recoId": "uuid",
    "modelVersion": "cold_tier2" ,
    "experimentVariant": "A",
    "coldStart": true,
    "items": [
      {
        "productId": "uuid",
        "title": "…",
        "pricePaise": 89900,
        "discountPct": 20,
        "thumbnailUrl": "https://…",
        "avgRating": 4.1,
        "reason": "Trending in your city"
      }
    ]
  }
}
```

### Frontend notes
- **Store `recoId`** with the rendered list. Every click, add-to-cart, or purchase that follows should carry `source: "reco:<recoId>"` in the tracking event. This is how offline CTR is measured.
- `coldStart: true` means the user is new/anonymous — OK to still render; ranking uses session + popularity.
- `experimentVariant` is informational; don't branch UI on it. Just log it so product can compare A vs B.
- `reason` is a short human string — render it as a subtitle chip if space permits.
- On a pull-to-refresh, re-call; response is cached 15 min server-side so rapid refreshes are cheap.

### `POST /api/v1/reco/feedback`

Light-weight dismiss/like signal from the home rail.
```json
{ "recoId": "uuid", "productId": "uuid", "action": "DISMISS" }
```
`action`: `DISMISS` | `LIKE` | `NOT_INTERESTED`. Response: 202.

---

## Phase 4 — Observability (frontend-facing implications)

Nothing new to call; flags that change *server* behaviour you should expect:

| Flag                            | User-visible effect                                      |
|---------------------------------|----------------------------------------------------------|
| `reco.degradedMode=true`        | `/reco/for-you` returns empty fast (no error). Show a fallback (e.g. category grid). |
| `reco.serving.enabled=false`    | Cold-start path serves all users — still 200 OK, just less personalised. |
| `reco.similarity.vectorsEnabled=false` | `modelVersion` comes back as `mlt_v1` instead of `knn_*`. Ignore. |

**Rule of thumb**: never treat `items: []` as an error. Show a silent fallback UI.

---

## End-to-end attribution example

1. User opens Home → `GET /reco/for-you` → render list, remember `recoId = X`.
2. User scrolls product P into view → `POST /track/interaction` with `{type:"VIEW", productId:P, source:"reco:X", context:"HOME"}`.
3. User taps P → `POST /track/interaction` with `{type:"CLICK", productId:P, source:"reco:X"}`.
4. On PDP, parallel `GET /product/P/similar?variant=...` calls.
5. User taps a similar item Q → `track/interaction {type:"CLICK", productId:Q, source:"similar:ALSO_VIEWED"}`.
6. Add-to-cart → `ADD_TO_CART`. Place order COD → `PURCHASE_COD`.

Every event MUST carry `sessionId`; `productId`, `type`, and `ts` are also required. Everything else is optional but improves ranking.

---

## Suggested Dart client skeletons

```dart
// recommendations_api.dart
Future<RecoResponse> forYou({String context = 'HOME', int k = 20}) async {
  final res = await apiClient.get(
    ApiEndpoints.recoForYou,
    query: {'context': context, 'k': k},
  );
  return RecoResponse.fromJson(res.data['data']);
}

Future<SimilarResponse> similar(String productId, String variant, {int k = 20}) async {
  final res = await apiClient.get(
    ApiEndpoints.similarProducts(productId),
    query: {'variant': variant, 'k': k},
  );
  return SimilarResponse.fromJson(res.data['data']);
}

Future<void> trackBatch(String sessionId, List<InteractionEvent> events) async {
  if (events.isEmpty) return;
  await apiClient.post(
    ApiEndpoints.trackInteraction,
    body: {'sessionId': sessionId, 'events': events.map((e) => e.toJson()).toList()},
  );
}
```

Keep `InteractionBuffer` as a singleton provider with a 5s Timer and a flush-on-resume hook.
