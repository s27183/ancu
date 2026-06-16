-- 003_charge_idempotency.sql — FirstHomey web shell: make one-time charge recording
-- idempotent under Stripe webhook retries.
--
-- 8-S5f records a one-time add-on (billing.md §9) when checkout.session.completed
-- fires for a mode=payment session. Unlike the subscription path (link/update — an
-- upsert and an UPDATE, idempotent by construction), a charge is an INSERT, and Stripe
-- RETRIES webhook delivery, so the same session.completed can arrive more than once.
-- The Stripe PaymentIntent id is the natural idempotency key: exactly one per payment.
-- A PARTIAL unique index (only over non-null payment-intent ids) lets the recorder
-- `ON CONFLICT DO NOTHING` on a replay, while leaving ledger-only charges (success_fee,
-- REA-paid, stripe_payment_intent_id IS NULL) un-deduplicated — each manual ledger
-- entry is distinct and carries no PaymentIntent.
--
-- Conventions carried from 001/002: forward-only; NO in-file BEGIN/COMMIT (the runner
-- wraps the file in one pgo:transaction).

CREATE UNIQUE INDEX charges_payment_intent_uidx
    ON charges (stripe_payment_intent_id)
    WHERE stripe_payment_intent_id IS NOT NULL;
