#!/usr/bin/env node
'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');

async function main() {
  const context = {console, Date, Promise};
  context.globalThis = context;
  vm.createContext(context);
  vm.runInContext(
    fs.readFileSync('web/notification_state_store.js', 'utf8'),
    context,
  );

  const store = context.missionAdmissionNotificationStateStore;
  assert.equal(typeof store.evaluateDailyProgress, 'function');
  assert.equal(typeof store.scheduleFollowUp, 'function');
  assert.equal(typeof store.claimFollowUp, 'function');
  assert.equal(typeof store.clearFollowUps, 'function');
  assert.equal(store.normalizePendingCount(3), 3);
  assert.equal(store.normalizePendingCount(-1), 0);
  assert.equal(store.isSupported(), false);
  assert.equal(store.normalizeDateKey('2026-07-16'), '2026-07-16');
  assert.equal(store.normalizeDateKey('2026-02-30'), '');

  const now = new Date(2026, 6, 16, 12, 0, 0);
  assert.equal(
    store.evaluateDailyProgress(null, now).decision,
    'state_not_initialized',
  );
  assert.equal(
    store.evaluateDailyProgress({
      initialized: true,
      challengeAvailable: false,
      lastCompletedDateKey: null,
    }, now).decision,
    'challenge_unavailable',
  );
  assert.equal(
    store.evaluateDailyProgress({
      initialized: true,
      challengeAvailable: true,
      lastCompletedDateKey: '2026-07-16',
    }, now).decision,
    'completed_today',
  );
  const pending = store.evaluateDailyProgress({
    initialized: true,
    challengeAvailable: true,
    lastCompletedDateKey: '2026-07-15',
  }, now);
  assert.equal(pending.decision, 'pending');
  assert.equal(pending.shouldShow, true);
  assert.equal(pending.todayDateKey, '2026-07-16');

  assert.equal(await store.scheduleFollowUp('firebase'), false);
  const unsupportedClaim = await store.claimFollowUp(now);
  assert.equal(unsupportedClaim.claimed, false);
  assert.equal(unsupportedClaim.dateKey, '2026-07-16');
  assert.equal(unsupportedClaim.remainingCount, 0);
  assert.equal(unsupportedClaim.source, '');
  assert.equal(await store.clearFollowUps(), false);

  const snapshot = await store.readSnapshot();
  assert.equal(snapshot.supported, false);
  assert.equal(snapshot.lastDecision, 'unsupported');

  console.log(
    'Estado inteligente validado: reto pendiente, cola de seguimiento y degradación sin IndexedDB.',
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
