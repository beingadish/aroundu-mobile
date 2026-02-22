# AroundU Flutter – Manual Testing Checklist

> Run through each journey end-to-end after every full build.
> Mark ✅ / ❌ / ⚠️ (passes with caveat).

---

## Pre-requisites
- [ ] Backend running locally (`docker compose up` or Spring Boot)
- [ ] Test accounts: **Client** and **Worker** registered & verified
- [ ] At least one `Skill` seeded in the database
- [ ] Device/emulator has location services enabled

---

## Journey 1 — Client Posts a Job

| # | Step | Expected | Pass? |
|---|------|----------|-------|
| 1.1 | Client taps "Post Job" → fills form → submits | Job created; lands on job detail; status badge = **Open For Offers** | |
| 1.2 | Worker opens feed → new job appears | Job card shows title, distance, budget | |
| 1.3 | Worker taps job → places bid | Bid sent; confirmation toast; bid appears in list | |
| 1.4 | Client opens job detail → sees bid list | Bid shows worker name, amount, notes | |
| 1.5 | Client taps "Accept" on a bid | Status changes to **Offer Accepted**; other bids disappear or disabled | |
| 1.6 | **Verify chat auto-created**: Client goes to Chat tab | Conversation with the accepted worker is listed | |
| 1.7 | Worker receives notification and taps "Accept Handshake" | Status changes to **Ready to Start** | |
| 1.8 | Client locks escrow (if ESCROW payment) | Payment lock confirmation; status remains **Ready to Start** | |
| 1.9 | Worker taps "Start Task" | Status changes to **In Progress** | |

---

## Journey 2 — Task Completion & Payment

| # | Step | Expected | Pass? |
|---|------|----------|-------|
| 2.1 | Worker taps "Mark Complete" | Status changes to **Pending Payment** | |
| 2.2 | Client sees updated status | Badge = **Pending Payment** (warning color) | |
| 2.3 | Client enters release code / taps "Release Payment" | Payment released; status → **Payment Released** | |
| 2.4 | Client writes review (5 ⭐, comment) | Review submitted; "Review Submitted" confirmation | |
| 2.5 | Worker writes review for client | Review submitted from worker side | |
| 2.6 | Opening reviews page shows both reviews | Ratings & comments visible | |
| 2.7 | **Guard**: Client tries to review again | Error: "review already submitted" | |

---

## Journey 3 — Chat

| # | Step | Expected | Pass? |
|---|------|----------|-------|
| 3.1 | After bid acceptance, open chat tab | Conversation present with correct participants | |
| 3.2 | Client sends message | Message appears in chat; real-time or on refresh | |
| 3.3 | Worker receives and replies | Message thread shows both sides chronologically | |
| 3.4 | Mark-as-read: open conversation | Unread badge disappears | |

---

## Escrow Edge Cases

| # | Step | Expected | Pass? |
|---|------|----------|-------|
| E.1 | Try to lock escrow on OPEN_FOR_BIDS job | Error: "cannot lock before worker assignment" | |
| E.2 | Lock escrow → try locking again | Error: "escrow already exists" | |
| E.3 | Different client tries to lock escrow | Error: "does not own this job" | |
| E.4 | Release without completing task first | Error: "invalid state for release" | |

---

## State Transition Guards (via Worker actions)

| # | Step | Expected | Pass? |
|---|------|----------|-------|
| S.1 | Worker tries to cancel job | Error: "Workers can only transition to IN_PROGRESS or COMPLETED_PENDING_PAYMENT" | |
| S.2 | Worker marks IN_PROGRESS on already completed job | Error: "Invalid status transition" | |
| S.3 | Client tries OPEN_FOR_BIDS → IN_PROGRESS | Error: "Invalid status transition" | |

---

## Review Guards

| # | Step | Expected | Pass? |
|---|------|----------|-------|
| R.1 | Submit review on OPEN_FOR_BIDS job | Error: job not eligible for review | |
| R.2 | Submit duplicate client review | Error: "review already submitted" | |
| R.3 | Worker submits review on COMPLETED job | Review saved; rating visible | |
| R.4 | Check eligibility API before showing review button | Returns `eligible: true` only after PAYMENT_RELEASED / COMPLETED | |

---

## Offline / Error Scenarios

| # | Step | Expected | Pass? |
|---|------|----------|-------|
| O.1 | Kill backend → try any action | Graceful error message; no crash | |
| O.2 | Slow network → submit bid | Loading indicator shown; no double-submit | |
| O.3 | Session expired → any API call | Redirect to login; token cleared | |

---

## Sign-off

| Role | Name | Date | Verdict |
|------|------|------|---------|
| QA | | | |
| Dev | | | |
| PM | | | |
