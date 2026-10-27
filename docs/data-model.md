# Data model and security rules

Everything the app stores in Cloud Firestore, and how [firestore.rules](../firestore.rules) protects it. The model classes in `lib/features/*/data/models/` are the source of truth for field names. The rules enforce the exact shape of each document, so **a field added in a model must also be added to the matching `isValid…` function**, or every write is rejected.

## Layout

```text
shops/{shopId}                     shopId == owner's Firebase Auth uid
  ├── customers/{customerId}
  ├── measurements/{measurementId}
  ├── orders/{orderId}
  └── payments/{paymentId}
```

- **Single owner.** The shop id is the owner's uid, so ownership is the path check `request.auth.uid == shopId`. Staff accounts would need a different scheme (for example a `members` map on the shop).
- **Ids are generated on the device** (`collection.doc().id`), so creates work offline and a retried write can never create a duplicate.
- **Money is stored as whole integers** in the shop's currency (no paisa/cents). The display currency is a device setting and does not affect stored values.
- **Dates.** `orderDate`, `deliveryDate` and `paidAt` are whole days stored as local midnight. `createdAt`, `updatedAt` and `voidedAt` are server timestamps; they read as `null` until the server confirms the write.

## `shops/{shopId}`

Model: [shop.dart](../lib/features/shop/data/models/shop.dart). Written by `ShopRepository`.

| Field | Type | Constraints |
|---|---|---|
| `name` | string | 1–60 chars |
| `ownerUid` | string | Must equal the caller's uid on create, can never change |
| `currency` | string | Must be `'PKR'` |
| `createdAt`, `updatedAt` | timestamp | |

Delete: never.

## `customers/{customerId}`

Model: [customer.dart](../lib/features/customers/data/models/customer.dart).

| Field | Type | Constraints / notes |
|---|---|---|
| `name` | string | 1–100 chars; whitespace collapsed by the cubit |
| `nameLower` | string | Derived from `name`; used for ordering |
| `phone` | string | ≤ 30 chars; optional (7–15 digits if given) |
| `phoneNormalized` | string | Derived; used for the duplicate-phone warning |
| `address` | string | ≤ 300 chars |
| `notes` | string | ≤ 1000 chars |
| `isArchived` | bool | Changed only through archive / restore |
| `createdAt`, `updatedAt` | timestamp | `createdAt` can never change |

Delete: never. Customers are archived because they own order history.

## `measurements/{measurementId}`

Model: [measurement.dart](../lib/features/measurements/data/models/measurement.dart). Templates: [measurement_templates.dart](../lib/features/measurements/data/measurement_templates.dart).

| Field | Type | Constraints / notes |
|---|---|---|
| `customerId` | string | Can never change after create |
| `garmentType` | string | `shirt_kurta` · `shalwar_trouser` · `waistcoat` |
| `label` | string | ≤ 60 chars, e.g. "Eid 2026" |
| `values` | map&lt;string, number&gt; | Field key → inches, 1–20 entries (only filled fields), each 0 < v ≤ 150 in the app |
| `styles` | map&lt;string, list&lt;string&gt;&gt; | Style group key → chosen option ids, ≤ 10 groups |
| `notes` | string | ≤ 1000 chars |
| `createdAt`, `updatedAt` | timestamp | `createdAt` can never change |

On update, `values` and `styles` are replaced as a whole, so clearing a field removes it. Delete **is** allowed, because orders keep their own copy.

### Garment templates

| Garment | Measurement keys | Style groups (options) |
|---|---|---|
| `shirt_kurta` | `length` `shoulder` `chest` `waist` `hip` `daman` `sleeve` `armhole` `collar` `cuff` | `collar` (band, shirt_collar, round_neck) · `cuff` (round, square, cuff_link) · `daman` (round, straight) · `pockets`* (front, side) |
| `shalwar_trouser` | `length` `waist` `hip` `thigh` `knee` `bottom` | `type` (shalwar, pajama, trouser) · `pockets`* (side, back) · `bottom` (plain, pleated) |
| `waistcoat` | `length` `shoulder` `chest` `waist` `armhole` | `front` (straight, curved) · `pockets`* (chest, side) |

\* multi-select. Keys and option ids are stored in Firestore: **never rename them**. Add new ones instead.

## `orders/{orderId}`

Models: [order.dart](../lib/features/orders/data/models/order.dart), [order_item.dart](../lib/features/orders/data/models/order_item.dart), [order_measurement.dart](../lib/features/orders/data/models/order_measurement.dart).

| Field | Type | Constraints / notes |
|---|---|---|
| `customerId` | string | Can never change |
| `orderNumber` | int ≥ 1 | Ticket number (`#12`), highest known + 1; can never change |
| `items` | list of `{name, quantity, unitPrice}` | 1–30 items; `unitPrice` > 0 in the app |
| `measurements` | list of snapshots | ≤ 10; each `{sourceId, garmentType, label, values, styles, notes}` copied from a measurement set |
| `totalAmount` | int > 0 | Σ quantity × unitPrice |
| `totalPaid` | int, 0 ≤ paid ≤ total | Changes only together with a payment (see below) |
| `remainingAmount` | int | Must equal `totalAmount - totalPaid` |
| `paymentStatus` | string | `unpaid` · `partial` · `paid`. Recomputed on read, so the stored value is informational |
| `status` | string | `booked` · `cutting` · `stitching` · `ready` · `delivered` · `cancelled`. Must be `booked` on create |
| `orderDate`, `deliveryDate` | timestamp | `deliveryDate >= orderDate` |
| `notes` | string | ≤ 1000 chars |
| `lastPaymentId` | string, optional | The payment that last changed `totalPaid`; the rules use it to find that payment |
| `createdAt`, `updatedAt` | timestamp | `createdAt` can never change |

Delete: never. Orders are cancelled because they own payments.

**Status flow.** The normal flow (`OrderStatus.next`) is Booked → Cutting → Stitching → Ready → Delivered. The order detail screen also has a sheet for picking any status, including going back a step. Cancelling asks for confirmation. Neither the app nor the rules restrict transitions. "Active" means Booked, Cutting, Stitching or Ready; an active order past its delivery date is **overdue**. Delivering an order with money still owing shows a warning first.

**Snapshots.** Attached measurements are copied into the order, so editing or deleting the customer's measurement set later never changes an old order.

## `payments/{paymentId}`

Model: [payment.dart](../lib/features/payments/data/models/payment.dart).

| Field | Type | Constraints / notes |
|---|---|---|
| `orderId` | string | |
| `customerId` | string | Must equal the order's `customerId` |
| `amount` | int > 0 | ≤ the order's remaining amount (checked by the cubit) |
| `method` | string | `cash` · `bank` · `other` |
| `note` | string | ≤ 200 chars; "Advance" for a payment made at booking |
| `paidAt` | timestamp | The day the money was received |
| `isVoided` | bool | `false` on create |
| `voidedAt` | timestamp, optional | Set when voided |
| `createdAt` | timestamp | |

Payments are **never edited or deleted**. The only allowed update is voiding (`isVoided: false → true` plus `voidedAt`). Payments cannot be recorded against a cancelled order.

## Money integrity

The app keeps `orders.totalPaid` equal to the sum of the order's non-voided payments. The rules enforce this independently, so a buggy or tampered client cannot change a balance without a matching payment record.

Every money change is **one batch** that writes both documents:

| Operation | Batch contents | Code |
|---|---|---|
| Create order with advance | `set` order (`totalPaid = advance`, `lastPaymentId = p`) + `set` payment `p` | `PaymentRepository.createOrderWithAdvance` |
| Record payment | `set` payment `p` + `update` order (`totalPaid += amount`, `remainingAmount -= amount`, `lastPaymentId = p`) | `PaymentRepository.recordPayment` |
| Void payment | `update` payment (`isVoided = true`) + `update` order (`totalPaid -= amount`, `remainingAmount += amount`, `lastPaymentId = p`) | `PaymentRepository.voidPayment` |

The rules check each side using `getAfter()`, which reads the document as it will be after the batch:

- **Order create** with `totalPaid > 0`: the payment at `lastPaymentId` must exist after the batch, belong to this order, be non-voided, and have `amount == totalPaid`.
- **Order update** where `totalPaid` changed: the payment at `lastPaymentId` must either be **new** in this batch with `amount == +delta`, or be **voided** in this batch (previously not voided) with `amount == -delta`.
- **Payment create**: after the batch, the order's `lastPaymentId` must point at this payment and its `customerId` must match.
- **Payment void**: only `isVoided` and `voidedAt` may change, and the order's `lastPaymentId` must point at this payment after the batch.

**Increments, not overwrites.** `totalPaid` and `remainingAmount` use `FieldValue.increment`, so two devices recording payments on the same order while offline both count when they sync. The server applies the increment to its own current value, so the `delta` checked by the rules is still exactly the payment amount.

**Cancelled orders** stay in the database but are excluded from balances, outstanding totals, dashboard counts and report income.

## Deploying rules

`firebase.json` points at [firestore.rules](../firestore.rules), so either run `firebase deploy --only firestore:rules --project <your-project>` or paste the file into **Firebase Console → Firestore → Rules** and publish.

Deploy rule changes **before** shipping an app version that writes a new field. Older rules reject unknown keys.

## Testing the rules

[firestore-tests/](../firestore-tests/) runs the rules against the Firestore emulator under a `demo-` project id, so it never touches a real project. It needs Node and Java.

```bash
cd firestore-tests
npm install
npm test        # starts the emulator, runs rules.test.js, stops it
```

The suite builds the same batches as `PaymentRepository` and checks that they pass. It also checks that tampered versions fail: a `totalPaid` change without a payment, a payment that doesn't match the change, voiding twice, editing a payment, deletes, unknown fields, another user's access, and dates out of order. Add a case here whenever you change a rule.
