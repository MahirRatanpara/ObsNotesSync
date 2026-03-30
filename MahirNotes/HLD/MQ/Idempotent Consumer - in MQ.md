# 💳 Handling Worker Crashes in Message Queue Systems (Money Deduction Use Case)

## 🧠 Problem Statement

You are building a system where:
- A message is produced: **"Deduct ₹500 from User A"**
- A worker consumes this message from a queue and performs the deduction

### ❗ Critical Failure Scenario
What happens if:
- Worker **deducts the money**
- But **crashes before sending ACK to the queue**

👉 The queue will **retry the message**, leading to:
- **Duplicate processing**
- **Double deduction ❌**

---

## ⚠️ Core Principle

> **Message queues provide *at-least-once delivery*, NOT exactly-once**

This means:
- Messages **can be delivered multiple times**
- Duplicate processing is **expected behavior**

---

## 🎯 Goal

Ensure that:
> **Even if the same message is processed multiple times, the result remains correct**

This is achieved via:

# ✅ Idempotency

---

## 🔐 Idempotent Consumer Design

### 📌 Step 1: Add a Unique Transaction ID

Every message must include a unique identifier:

```json
{
  "transactionId": "txn-123",
  "userId": "A",
  "amount": 500
}
```

---

### 📌 Step 2: Maintain a Transaction Log / Ledger

Create a table:

```sql
CREATE TABLE transactions (
    transaction_id VARCHAR PRIMARY KEY,
    user_id VARCHAR,
    amount INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

### 📌 Step 3: Processing Logic

#### Pseudocode

```java
if (transactionId already exists in DB) {
    // Duplicate message
    return SUCCESS;
} else {
    process deduction;
    insert transaction record;
}
```

---

## 🔥 Correct Implementation (Atomic DB Transaction)

This is **VERY IMPORTANT** to avoid race conditions.

```sql
BEGIN;

-- Step 1: Insert transaction (fails if duplicate)
INSERT INTO transactions(transaction_id, user_id, amount)
VALUES ('txn-123', 'A', 500);

-- Step 2: Deduct balance
UPDATE users
SET balance = balance - 500
WHERE user_id = 'A';

COMMIT;
```

### ✅ Key Guarantee
- `transaction_id` has a **UNIQUE constraint**
- If duplicate message arrives:
  - INSERT fails ❌
  - Deduction does NOT happen again ✅

---

## 🔁 What Happens in Failure Scenario Now?

### Scenario:
- Worker deducts money
- Crashes before ACK

### Retry Flow:
1. Message is re-delivered
2. Worker checks `transaction_id`
3. Finds it already exists
4. Skips processing
5. Sends ACK

✅ **No double deduction**

---

## ⚙️ Message Processing Flow (Correct)

1. Consume message
2. Start DB transaction
3. Try inserting `transaction_id`
4. If success:
   - Deduct balance
5. Commit
6. Send ACK

---

## ❌ Common Mistakes

### 1. Assuming Queue Prevents Duplicates
- ❌ Wrong
- Queues retry messages → duplicates are normal

---

### 2. ACK Before Processing

```
ACK → Process
```

- ❌ Risk: Message lost if worker crashes after ACK

---

### 3. No Idempotency Key
- ❌ Leads to double deduction

---

### 4. Using Distributed Locks
- ❌ Complex
- ❌ Doesn't solve crash recovery properly

---

## 🧩 Advanced Concepts

### 1. Idempotency Key Storage Strategy

- Store in DB (preferred for financial systems)
- Can use Redis (with TTL) for high throughput systems

---

### 2. TTL for Idempotency Records

- Keep transaction IDs for a fixed duration (e.g., 24–72 hours)
- Tradeoff:
  - Memory vs safety window

---

### 3. Retry + Dead Letter Queue (DLQ)

If processing fails repeatedly:
- Move message to DLQ
- Manual inspection required

---

### 4. Exactly-Once Semantics (Reality Check)

> **Exactly-once is NOT truly achievable for external side effects**

Even systems like Kafka:
- Provide exactly-once for **stream processing**
- NOT for DB updates

---

## 🏦 Real-World Systems

### Payment Gateways (Stripe, Razorpay)
- Use **Idempotency Keys**
- Maintain **transaction ledger**
- Ensure:
  > Same request → same result

---

## 🧠 Mental Model

> “Queues guarantee delivery.  
> YOU guarantee correctness.”

---

## 🗣️ Interview Answer (Crisp Version)

> "Since message queues provide at-least-once delivery, I would design the consumer to be idempotent by using a unique transaction ID and enforcing a database constraint. This ensures that even if the message is processed multiple times due to retries, the deduction happens only once."

---

## 🧱 Summary

| Concern                  | Solution                          |
|-------------------------|----------------------------------|
| Duplicate messages      | Idempotency                      |
| Worker crash            | Retry + safe reprocessing        |
| Double deduction        | Unique transaction ID            |
| Race conditions         | DB transaction + constraints     |
| Infinite retries        | DLQ                              |

---

## 🚀 Key Takeaway

> **Never rely on the queue for correctness.  
Design your consumer to be idempotent.**
