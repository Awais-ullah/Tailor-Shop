// Tests for ../firestore.rules. Run with `npm test` in this folder: it
// starts the Firestore emulator, runs these tests, and stops it again.
// The "demo-" project id means nothing ever touches a real project.
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  Timestamp,
  deleteDoc,
  doc,
  getDoc,
  increment,
  serverTimestamp,
  setDoc,
  setLogLevel,
  updateDoc,
  writeBatch,
} from 'firebase/firestore';
import { afterAll, beforeAll, beforeEach, describe, test } from 'vitest';

const OWNER = 'owner-uid';
const rulesPath = fileURLToPath(new URL('../firestore.rules', import.meta.url));

let env;

beforeAll(async () => {
  // Denied writes are the point of most tests; don't log each one.
  setLogLevel('silent');
  env = await initializeTestEnvironment({
    projectId: 'demo-tailor-shop',
    firestore: { rules: readFileSync(rulesPath, 'utf8') },
  });
});

afterAll(async () => env?.cleanup());

beforeEach(async () => env.clearFirestore());

const owner = () => env.authenticatedContext(OWNER).firestore();
const intruder = () => env.authenticatedContext('someone-else').firestore();
const path = (db, ...segments) => doc(db, 'shops', OWNER, ...segments);

const day = (d) => Timestamp.fromDate(new Date(2026, 9, d));

// Documents shaped exactly like the app's toMap() methods.
const customerDoc = (extra = {}) => ({
  name: 'Ali Khan',
  nameLower: 'ali khan',
  phone: '0300-1234567',
  phoneNormalized: '03001234567',
  address: '',
  notes: '',
  isArchived: false,
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
  ...extra,
});

const orderDoc = ({ total = 5000, paid = 0, lastPaymentId, ...extra } = {}) => ({
  customerId: 'c1',
  orderNumber: 1,
  items: [{ name: 'Kurta', quantity: 1, unitPrice: total }],
  measurements: [],
  totalAmount: total,
  totalPaid: paid,
  remainingAmount: total - paid,
  paymentStatus: paid === 0 ? 'unpaid' : paid >= total ? 'paid' : 'partial',
  status: 'booked',
  orderDate: day(1),
  deliveryDate: day(10),
  notes: '',
  ...(lastPaymentId ? { lastPaymentId } : {}),
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
  ...extra,
});

const paymentDoc = (amount, extra = {}) => ({
  orderId: 'o1',
  customerId: 'c1',
  amount,
  method: 'cash',
  note: '',
  paidAt: day(2),
  isVoided: false,
  createdAt: serverTimestamp(),
  ...extra,
});

/** Seeds data with the rules switched off. */
async function seed(write) {
  await env.withSecurityRulesDisabled(async (ctx) => write(ctx.firestore()));
}

/** An unpaid order o1 for customer c1. */
const seedOrder = (fields) =>
  seed((db) => setDoc(path(db, 'orders', 'o1'), orderDoc(fields)));

/** The batch PaymentRepository.recordPayment builds. */
function recordPayment(db, id, amount, { orderDelta = amount } = {}) {
  const batch = writeBatch(db);
  batch.set(path(db, 'payments', id), paymentDoc(amount));
  batch.update(path(db, 'orders', 'o1'), {
    totalPaid: increment(orderDelta),
    remainingAmount: increment(-orderDelta),
    paymentStatus: 'partial',
    lastPaymentId: id,
    updatedAt: serverTimestamp(),
  });
  return batch.commit();
}

/** The batch PaymentRepository.voidPayment builds. */
function voidPayment(db, id, amount) {
  const batch = writeBatch(db);
  batch.update(path(db, 'payments', id), {
    isVoided: true,
    voidedAt: serverTimestamp(),
  });
  batch.update(path(db, 'orders', 'o1'), {
    totalPaid: increment(-amount),
    remainingAmount: increment(amount),
    paymentStatus: 'unpaid',
    lastPaymentId: id,
    updatedAt: serverTimestamp(),
  });
  return batch.commit();
}

describe('ownership', () => {
  test('the owner can read and write their own shop', async () => {
    await assertSucceeds(setDoc(path(owner(), 'customers', 'c1'), customerDoc()));
    await assertSucceeds(getDoc(path(owner(), 'customers', 'c1')));
  });

  test('another user cannot read or write the shop', async () => {
    await seed((db) => setDoc(path(db, 'customers', 'c1'), customerDoc()));
    await assertFails(getDoc(path(intruder(), 'customers', 'c1')));
    await assertFails(setDoc(path(intruder(), 'customers', 'c2'), customerDoc()));
  });
});

describe('document shape', () => {
  test('unknown fields are rejected', async () => {
    await assertFails(
      setDoc(path(owner(), 'customers', 'c1'), customerDoc({ vip: true })),
    );
  });

  test('delivery cannot be before the order date', async () => {
    await assertFails(
      setDoc(
        path(owner(), 'orders', 'o1'),
        orderDoc({ orderDate: day(10), deliveryDate: day(9) }),
      ),
    );
  });

  test('a new order must start as booked', async () => {
    await assertFails(
      setDoc(path(owner(), 'orders', 'o1'), orderDoc({ status: 'ready' })),
    );
  });
});

describe('nothing that owns history can be deleted', () => {
  test('customers, orders and payments are never deleted', async () => {
    await seed(async (db) => {
      await setDoc(path(db, 'customers', 'c1'), customerDoc());
      await setDoc(path(db, 'orders', 'o1'), orderDoc());
      await setDoc(path(db, 'payments', 'p1'), paymentDoc(100));
    });
    await assertFails(deleteDoc(path(owner(), 'customers', 'c1')));
    await assertFails(deleteDoc(path(owner(), 'orders', 'o1')));
    await assertFails(deleteDoc(path(owner(), 'payments', 'p1')));
  });
});

describe('money integrity', () => {
  test('an unpaid order can be created on its own', async () => {
    await assertSucceeds(setDoc(path(owner(), 'orders', 'o1'), orderDoc()));
  });

  test('an order with an advance needs the matching payment in the same batch', async () => {
    const db = owner();
    const batch = writeBatch(db);
    batch.set(path(db, 'orders', 'o1'), orderDoc({ paid: 2000, lastPaymentId: 'p1' }));
    batch.set(path(db, 'payments', 'p1'), paymentDoc(2000));
    await assertSucceeds(batch.commit());
  });

  test('an advance without its payment is rejected', async () => {
    await assertFails(
      setDoc(
        path(owner(), 'orders', 'o1'),
        orderDoc({ paid: 2000, lastPaymentId: 'p1' }),
      ),
    );
  });

  test('recording a payment moves the order total with it', async () => {
    await seedOrder();
    await assertSucceeds(recordPayment(owner(), 'p1', 1500));
  });

  test('totalPaid cannot change without a payment', async () => {
    await seedOrder();
    await assertFails(
      updateDoc(path(owner(), 'orders', 'o1'), {
        totalPaid: increment(1000),
        remainingAmount: increment(-1000),
      }),
    );
  });

  test('the payment amount must equal the change in totalPaid', async () => {
    await seedOrder();
    await assertFails(recordPayment(owner(), 'p1', 1000, { orderDelta: 1500 }));
  });

  test('a payment cannot be more than what is owed', async () => {
    await seedOrder({ total: 1000 });
    await assertFails(recordPayment(owner(), 'p1', 1200));
  });

  test('voiding a payment gives its amount back to the order', async () => {
    await seedOrder();
    await recordPayment(owner(), 'p1', 1500);
    await assertSucceeds(voidPayment(owner(), 'p1', 1500));
  });

  test('a payment cannot be voided twice', async () => {
    await seedOrder();
    await recordPayment(owner(), 'p1', 1500);
    await voidPayment(owner(), 'p1', 1500);
    await assertFails(voidPayment(owner(), 'p1', 1500));
  });

  test("a payment's amount can never be edited", async () => {
    await seedOrder();
    await recordPayment(owner(), 'p1', 1500);
    await assertFails(updateDoc(path(owner(), 'payments', 'p1'), { amount: 1 }));
  });

  test('editing an order keeps its total consistent with what was paid', async () => {
    await seedOrder({ total: 5000 });
    await recordPayment(owner(), 'p1', 3000);
    // Lowering the total below what was already paid is rejected.
    await assertFails(
      updateDoc(path(owner(), 'orders', 'o1'), {
        items: [{ name: 'Kurta', quantity: 1, unitPrice: 2000 }],
        totalAmount: 2000,
        remainingAmount: -1000,
        updatedAt: serverTimestamp(),
      }),
    );
  });

  test('status changes are allowed', async () => {
    await seedOrder();
    await assertSucceeds(
      updateDoc(path(owner(), 'orders', 'o1'), {
        status: 'cutting',
        updatedAt: serverTimestamp(),
      }),
    );
  });
});
