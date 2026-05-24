# Fraud Analytics — Findings & Recommendations

**Dataset:** 590,540 credit card transactions, December 2017 – June 2018
**Prepared by:** Shenbaga Arun
**Purpose:** Identify where fraud concentrates and assess rule-based detection

---

## Executive Summary

Fraud affects **3.5% of transactions** but is far from evenly spread. It concentrates
sharply in specific, identifiable conditions — and two transaction profiles alone account
for roughly **two-thirds of all fraud**. A simple rule-based engine built on these patterns
recovers an estimated **$245,722 in net value** even before any machine-learning investment,
and points clearly to where tighter controls would pay off most.

---

## The Five Findings That Matter

**1. Online and card-not-present purchases carry the most fraud.**
Transactions where the physical card isn't required — online checkouts and card-not-present
payments — show dramatically higher fraud than in-person retail or travel bookings. This is
the modern fraud reality: criminals need only the card number, not the card.

**2. Free webmail addresses are the common thread.**
Purchases made with free email providers (Gmail, Yahoo, Hotmail, etc.) appear in the
overwhelming majority of fraud cases. Anonymous/privacy email domains are even riskier per
transaction — about **11 times** the baseline fraud rate — though they appear less often.

**3. Two profiles contain ~66% of all fraud.**
- Card-not-present purchases with a free webmail address
- Online ("web purchase") transactions with a free webmail address

Focusing controls on just these two profiles would put two-thirds of all fraud within reach.

**4. The single highest-risk profile runs at 26% fraud.**
Card-not-present + credit card + free webmail + high transaction value carries a **26.3%
fraud rate — 7.5× the average**. Better than 1 in 4 such transactions is fraudulent.

**5. Both very small and very large transactions are riskier than mid-range.**
Fraud is elevated at both ends of the amount spectrum — small amounts (likely card-testing)
and large amounts (maximizing the payoff) — while mid-range transactions are safest.

---

## What a Rule-Based Engine Achieves Today

Using six rules drawn directly from the patterns above, a detection engine was built and
measured:

| Outcome | Result |
|---------|--------|
| Fraud caught | 4,525 cases |
| Fraud missed | 16,138 cases |
| Legitimate transactions flagged for review | 19,268 |
| Estimated net benefit | **$245,722** |

The engine is tuned to **maximize business value, not statistical accuracy.** Because a
missed fraud costs the full transaction amount while a false alarm costs only a few dollars
of review time, the right strategy is to **flag generously for human review** rather than
auto-block. Under that model, the engine pays for itself many times over.

---

## Recommendations

**1. Apply step-up authentication to the highest-risk profile.**
Require additional verification (one-time passcode, 3-D Secure) for card-not-present credit
purchases from free webmail domains above the high-value threshold. This single profile runs
at 26% fraud — friction here is justified.

**2. Route the two dominant profiles to a review queue.**
Card-not-present and online purchases paired with free webmail should feed a human review
queue rather than being auto-approved. These two profiles hold two-thirds of all fraud.

**3. Add velocity monitoring at the real-card level.**
This dataset's anonymization prevented per-card velocity analysis — yet velocity (rapid
bursts of transactions on one card) is the strongest fraud signal in the industry. A
production system with access to true card identifiers should monitor it directly.

**4. Treat this engine as a first-pass filter, not the final answer.**
The rule engine recovers meaningful value now and requires no model training. It should be
the first layer, complemented over time by a machine-learning model trained on richer
behavioral signals to close the gap on the fraud it currently misses.

---

## A Note on What This Analysis Could and Couldn't Do

The strongest fraud signal available to real banks — how fast a single card is being used —
was deliberately removed from this dataset to protect privacy. As a result, detection here
relies only on categorical attributes (purchase type, email, card type, amount), which
separate fraud from legitimate activity only weakly. The 22% detection rate reflects that
data limitation, not a flaw in the approach. With real-card behavioral data, the same
analytical framework would perform substantially better.