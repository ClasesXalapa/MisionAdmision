(() => {
  'use strict';

  const DATABASE_NAME = 'mision_admision_notification_state_v1';
  const DATABASE_VERSION = 1;
  const STORE_NAME = 'state';
  const DAILY_PROGRESS_KEY = 'daily_progress';
  const DAILY_DIAGNOSTICS_KEY = 'daily_diagnostics';
  const DAILY_FOLLOW_UP_KEY = 'daily_follow_up';

  let databasePromise = null;

  function isSupported() {
    return typeof globalThis.indexedDB !== 'undefined' &&
      globalThis.indexedDB !== null;
  }

  function localDateKey(value = new Date()) {
    const year = value.getFullYear().toString().padStart(4, '0');
    const month = (value.getMonth() + 1).toString().padStart(2, '0');
    const day = value.getDate().toString().padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  function normalizeDateKey(value) {
    if (typeof value !== 'string') return '';
    const trimmed = value.trim();
    if (!/^\d{4}-\d{2}-\d{2}$/.test(trimmed)) return '';
    const [year, month, day] = trimmed.split('-').map(Number);
    const parsed = new Date(year, month - 1, day);
    if (parsed.getFullYear() !== year ||
        parsed.getMonth() !== month - 1 ||
        parsed.getDate() !== day) {
      return '';
    }
    return trimmed;
  }

  function normalizePendingCount(value) {
    return Number.isInteger(value) && value > 0 ? value : 0;
  }

  function evaluateDailyProgress(progress, now = new Date()) {
    const todayDateKey = localDateKey(now);
    if (!progress || progress.initialized !== true) {
      return {shouldShow: false, decision: 'state_not_initialized', todayDateKey};
    }
    if (progress.challengeAvailable !== true) {
      return {shouldShow: false, decision: 'challenge_unavailable', todayDateKey};
    }
    if (normalizeDateKey(progress.lastCompletedDateKey) === todayDateKey) {
      return {shouldShow: false, decision: 'completed_today', todayDateKey};
    }
    return {shouldShow: true, decision: 'pending', todayDateKey};
  }

  function requestResult(request) {
    return new Promise((resolve, reject) => {
      request.onsuccess = () => resolve(request.result);
      request.onerror = () => reject(
        request.error || new Error('IndexedDB no pudo completar la operación.'),
      );
    });
  }

  function transactionComplete(transaction) {
    return new Promise((resolve, reject) => {
      transaction.oncomplete = () => resolve();
      transaction.onerror = () => reject(
        transaction.error || new Error('IndexedDB no pudo guardar el estado.'),
      );
      transaction.onabort = () => reject(
        transaction.error || new Error('IndexedDB canceló la operación.'),
      );
    });
  }

  function openDatabase() {
    if (!isSupported()) return Promise.resolve(null);
    if (databasePromise) return databasePromise;

    databasePromise = new Promise((resolve, reject) => {
      const request = globalThis.indexedDB.open(DATABASE_NAME, DATABASE_VERSION);
      request.onupgradeneeded = () => {
        const database = request.result;
        if (!database.objectStoreNames.contains(STORE_NAME)) {
          database.createObjectStore(STORE_NAME, {keyPath: 'key'});
        }
      };
      request.onsuccess = () => resolve(request.result);
      request.onerror = () => {
        databasePromise = null;
        reject(request.error || new Error('No fue posible abrir IndexedDB.'));
      };
      request.onblocked = () => {
        databasePromise = null;
        reject(new Error('IndexedDB está bloqueado por otra versión de la aplicación.'));
      };
    });
    return databasePromise;
  }

  async function readRecord(key) {
    const database = await openDatabase();
    if (!database) return null;
    const transaction = database.transaction(STORE_NAME, 'readonly');
    const completion = transactionComplete(transaction);
    const request = transaction.objectStore(STORE_NAME).get(key);
    const value = await requestResult(request);
    await completion;
    return value || null;
  }

  async function writeRecord(record) {
    const database = await openDatabase();
    if (!database) return false;
    const transaction = database.transaction(STORE_NAME, 'readwrite');
    transaction.objectStore(STORE_NAME).put(record);
    await transactionComplete(transaction);
    return true;
  }

  async function updateRecord(key, updater) {
    const database = await openDatabase();
    if (!database) return null;
    const transaction = database.transaction(STORE_NAME, 'readwrite');
    const completion = transactionComplete(transaction);
    const store = transaction.objectStore(STORE_NAME);
    const current = (await requestResult(store.get(key))) || {key};
    const updated = updater({...current, key});
    store.put(updated);
    await completion;
    return updated;
  }

  async function clearFollowUps(reason = 'cleared') {
    if (!isSupported()) return false;
    const now = new Date();
    await writeRecord({
      key: DAILY_FOLLOW_UP_KEY,
      dateKey: localDateKey(now),
      pendingCount: 0,
      lastCreatedAt: '',
      lastClaimedAt: '',
      lastSource: '',
      clearedAt: now.toISOString(),
      clearReason: typeof reason === 'string' ? reason : 'cleared',
    });
    return true;
  }

  async function syncDailyProgress(lastCompletedDateKey, challengeAvailable) {
    if (!isSupported()) return false;
    const normalizedDateKey = normalizeDateKey(lastCompletedDateKey);
    const now = new Date();
    await writeRecord({
      key: DAILY_PROGRESS_KEY,
      initialized: true,
      lastCompletedDateKey: normalizedDateKey || null,
      challengeAvailable: challengeAvailable === true,
      updatedAt: now.toISOString(),
    });

    const completedToday = normalizedDateKey === localDateKey(now);
    if (completedToday || challengeAvailable !== true) {
      await clearFollowUps(completedToday ? 'completed_today' : 'challenge_unavailable');
    }
    return true;
  }

  async function readDailyProgress() {
    return readRecord(DAILY_PROGRESS_KEY);
  }

  async function scheduleFollowUp(source = 'firebase', now = new Date()) {
    if (!isSupported()) return false;
    const todayDateKey = localDateKey(now);
    await updateRecord(DAILY_FOLLOW_UP_KEY, (current) => {
      const currentDateKey = normalizeDateKey(current.dateKey);
      const currentCount = currentDateKey === todayDateKey
        ? normalizePendingCount(current.pendingCount)
        : 0;
      return {
        ...current,
        dateKey: todayDateKey,
        pendingCount: currentCount + 1,
        lastCreatedAt: now.toISOString(),
        lastSource: typeof source === 'string' ? source : 'firebase',
        clearedAt: '',
        clearReason: '',
      };
    });
    return true;
  }

  async function claimFollowUp(now = new Date()) {
    if (!isSupported()) {
      return {
        claimed: false,
        dateKey: localDateKey(now),
        remainingCount: 0,
        source: '',
      };
    }

    let result = {
      claimed: false,
      dateKey: localDateKey(now),
      remainingCount: 0,
      source: '',
    };
    const todayDateKey = localDateKey(now);
    await updateRecord(DAILY_FOLLOW_UP_KEY, (current) => {
      const currentDateKey = normalizeDateKey(current.dateKey);
      const currentCount = currentDateKey === todayDateKey
        ? normalizePendingCount(current.pendingCount)
        : 0;

      if (currentCount <= 0) {
        return {
          ...current,
          dateKey: todayDateKey,
          pendingCount: 0,
          clearedAt: currentDateKey && currentDateKey !== todayDateKey
            ? now.toISOString()
            : current.clearedAt || '',
          clearReason: currentDateKey && currentDateKey !== todayDateKey
            ? 'expired_date'
            : current.clearReason || '',
        };
      }

      result = {
        claimed: true,
        dateKey: todayDateKey,
        remainingCount: currentCount - 1,
        source: typeof current.lastSource === 'string' ? current.lastSource : '',
      };
      return {
        ...current,
        dateKey: todayDateKey,
        pendingCount: currentCount - 1,
        lastClaimedAt: now.toISOString(),
      };
    });
    return result;
  }

  async function readFollowUpState() {
    const followUp = await readRecord(DAILY_FOLLOW_UP_KEY);
    const todayDateKey = localDateKey(new Date());
    const dateKey = normalizeDateKey(followUp?.dateKey);
    return {
      dateKey,
      pendingCount: dateKey === todayDateKey
        ? normalizePendingCount(followUp?.pendingCount)
        : 0,
      lastCreatedAt: typeof followUp?.lastCreatedAt === 'string'
        ? followUp.lastCreatedAt
        : '',
      lastClaimedAt: typeof followUp?.lastClaimedAt === 'string'
        ? followUp.lastClaimedAt
        : '',
      lastSource: typeof followUp?.lastSource === 'string'
        ? followUp.lastSource
        : '',
    };
  }

  async function recordFirebaseWake() {
    if (!isSupported()) return false;
    await updateRecord(DAILY_DIAGNOSTICS_KEY, (current) => ({
      ...current,
      lastFirebaseReceivedAt: new Date().toISOString(),
      lastErrorMessage: '',
    }));
    return true;
  }

  async function recordDecision(
    decision,
    {reminderShown = false, errorMessage = ''} = {},
  ) {
    if (!isSupported()) return false;
    const now = new Date();
    const todayDateKey = localDateKey(now);
    await updateRecord(DAILY_DIAGNOSTICS_KEY, (current) => {
      const previousDateKey = normalizeDateKey(current.reminderCountDateKey);
      const previousCount = Number.isInteger(current.reminderCountForDate)
        ? current.reminderCountForDate
        : 0;
      const nextCount = reminderShown
        ? (previousDateKey === todayDateKey ? previousCount + 1 : 1)
        : previousCount;
      return {
        ...current,
        lastDecision: typeof decision === 'string' ? decision : 'unknown',
        lastDecisionAt: now.toISOString(),
        lastErrorMessage: typeof errorMessage === 'string' ? errorMessage : '',
        lastLocalReminderAt: reminderShown
          ? now.toISOString()
          : current.lastLocalReminderAt || '',
        reminderCountDateKey: reminderShown
          ? todayDateKey
          : current.reminderCountDateKey || '',
        reminderCountForDate: nextCount,
      };
    });
    return true;
  }

  function unsupportedSnapshot() {
    return {
      supported: false,
      stateInitialized: false,
      lastCompletedDateKey: '',
      challengeAvailable: false,
      stateUpdatedAt: '',
      lastFirebaseReceivedAt: '',
      lastLocalReminderAt: '',
      reminderCountDateKey: '',
      reminderCountForDate: 0,
      followUpDateKey: '',
      pendingFollowUpCount: 0,
      followUpLastCreatedAt: '',
      followUpLastClaimedAt: '',
      lastDecision: 'unsupported',
      lastDecisionAt: '',
      errorMessage: '',
    };
  }

  async function readSnapshot() {
    if (!isSupported()) return unsupportedSnapshot();

    try {
      const [progress, diagnostics, followUp] = await Promise.all([
        readRecord(DAILY_PROGRESS_KEY),
        readRecord(DAILY_DIAGNOSTICS_KEY),
        readFollowUpState(),
      ]);
      return {
        supported: true,
        stateInitialized: progress?.initialized === true,
        lastCompletedDateKey: normalizeDateKey(progress?.lastCompletedDateKey),
        challengeAvailable: progress?.challengeAvailable === true,
        stateUpdatedAt: typeof progress?.updatedAt === 'string'
          ? progress.updatedAt
          : '',
        lastFirebaseReceivedAt:
          typeof diagnostics?.lastFirebaseReceivedAt === 'string'
            ? diagnostics.lastFirebaseReceivedAt
            : '',
        lastLocalReminderAt:
          typeof diagnostics?.lastLocalReminderAt === 'string'
            ? diagnostics.lastLocalReminderAt
            : '',
        reminderCountDateKey: normalizeDateKey(
          diagnostics?.reminderCountDateKey,
        ),
        reminderCountForDate:
          Number.isInteger(diagnostics?.reminderCountForDate)
            ? diagnostics.reminderCountForDate
            : 0,
        followUpDateKey: followUp.dateKey,
        pendingFollowUpCount: followUp.pendingCount,
        followUpLastCreatedAt: followUp.lastCreatedAt,
        followUpLastClaimedAt: followUp.lastClaimedAt,
        lastDecision: typeof diagnostics?.lastDecision === 'string'
          ? diagnostics.lastDecision
          : '',
        lastDecisionAt: typeof diagnostics?.lastDecisionAt === 'string'
          ? diagnostics.lastDecisionAt
          : '',
        errorMessage: typeof diagnostics?.lastErrorMessage === 'string'
          ? diagnostics.lastErrorMessage
          : '',
      };
    } catch (error) {
      return {
        ...unsupportedSnapshot(),
        supported: true,
        lastDecision: 'storage_error',
        lastDecisionAt: new Date().toISOString(),
        errorMessage: error instanceof Error ? error.message : String(error),
      };
    }
  }

  globalThis.missionAdmissionNotificationStateStore = Object.freeze({
    isSupported,
    localDateKey,
    normalizeDateKey,
    normalizePendingCount,
    evaluateDailyProgress,
    syncDailyProgress,
    readDailyProgress,
    scheduleFollowUp,
    claimFollowUp,
    clearFollowUps,
    readFollowUpState,
    recordFirebaseWake,
    recordDecision,
    readSnapshot,
  });
})();
