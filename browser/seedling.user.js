// ==UserScript==
// @name         Seedling — pick up ticket
// @namespace    dev.bassiuz.seedling
// @version      1.0.0
// @description  Adds a button to Jira issues and Bitbucket pull requests that drops the ticket onto today's Seedling list.
// @author       Bas de Vaan
// @match        https://*.atlassian.net/*
// @match        https://bitbucket.org/*
// @connect      identitytoolkit.googleapis.com
// @connect      securetoken.googleapis.com
// @connect      firestore.googleapis.com
// @grant        GM_setValue
// @grant        GM_getValue
// @grant        GM_deleteValue
// @grant        GM_xmlhttpRequest
// @grant        GM_registerMenuCommand
// @run-at       document-idle
// ==/UserScript==

/*
 * One userscript instead of two browser extensions: Tampermonkey and
 * Greasemonkey both run this unchanged, which beats maintaining a Chrome
 * manifest and a Firefox one for a single button.
 *
 * It talks straight to Firestore over REST, the same path the app uses, so
 * there is no server in the middle. Sign in once and only a refresh token is
 * kept — the password is used to get it and then dropped.
 */

'use strict';

// Which Firebase project this talks to. Asked for once and remembered, rather
// than baked in: the key identifies a project and grants nothing, but a copy
// of this script that points at somebody else's project by default is a copy
// that quietly writes into it.
//
// Both values are in your app's `lib/firebase_options.dart` after you run
// `flutterfire configure`.
function config() {
  let apiKey = GM_getValue('apiKey');
  let projectId = GM_getValue('projectId');
  if (!apiKey || !projectId) {
    apiKey = prompt('Firebase web API key');
    projectId = prompt('Firebase project id');
    if (!apiKey || !projectId) return null;
    GM_setValue('apiKey', apiKey.trim());
    GM_setValue('projectId', projectId.trim());
  }
  return { apiKey: apiKey.trim(), projectId: projectId.trim() };
}

const firestoreFor = (projectId) =>
  `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents`;

// ---------------------------------------------------------------- pure bits
// Everything below this line is testable without a browser; see test/.

/** The day key the app uses. Local time, because "today" is where you are. */
function todayKey(now = new Date()) {
  const pad = (n) => String(n).padStart(2, '0');
  return `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}`;
}

/**
 * What kind of page this is, and the ids needed to look the title up.
 * Returns null for pages that are neither.
 */
function detectPage(href) {
  let url;
  try {
    url = new URL(href);
  } catch {
    return null;
  }

  if (url.hostname.endsWith('.atlassian.net')) {
    // Both the old /browse/KEY permalink and the board's ?selectedIssue=KEY.
    const fromPath = url.pathname.match(/\/browse\/([A-Z][A-Z0-9_]+-\d+)/);
    const fromQuery = url.searchParams.get('selectedIssue');
    const key = fromPath ? fromPath[1] : fromQuery;
    if (key && /^[A-Z][A-Z0-9_]+-\d+$/.test(key)) {
      return { kind: 'jira', key, origin: url.origin };
    }
    return null;
  }

  if (url.hostname === 'bitbucket.org') {
    const match = url.pathname.match(
      /^\/([^/]+)\/([^/]+)\/pull-requests\/(\d+)/,
    );
    if (match) {
      return {
        kind: 'bitbucket',
        workspace: match[1],
        repo: match[2],
        id: match[3],
        origin: url.origin,
      };
    }
    return null;
  }

  return null;
}

/** The task title, shaped so it reads well in a day list. */
function taskTitle(page, summary) {
  const clean = (summary || '').trim();
  if (page.kind === 'jira') {
    return clean ? `${page.key} ${clean}` : page.key;
  }
  // Reviews say so, because picking one up is a different kind of work.
  const what = clean ? `: ${clean}` : '';
  return `Review ${page.repo}#${page.id}${what}`;
}

/** A Firestore document matching the app's Task model exactly. */
function taskDocument({ title, dayKey, tagId = null }) {
  return {
    fields: {
      title: { stringValue: title },
      date: { stringValue: dayKey },
      createdDate: { stringValue: dayKey },
      tagId: tagId ? { stringValue: tagId } : { nullValue: null },
      time: { nullValue: null },
      completedOnDate: { nullValue: null },
      timeEntries: { mapValue: { fields: {} } },
    },
  };
}

/** Where the same-origin API call for this page's title goes. */
function titleEndpoint(page) {
  if (page.kind === 'jira') {
    return `${page.origin}/rest/api/3/issue/${page.key}?fields=summary`;
  }
  return `${page.origin}/!api/2.0/repositories/${page.workspace}/${page.repo}/pullrequests/${page.id}`;
}

/** Pulls the summary out of whichever API answered. */
function readSummary(page, body) {
  if (!body) return '';
  if (page.kind === 'jira') return body.fields?.summary ?? '';
  return body.title ?? '';
}

if (typeof module !== 'undefined') {
  module.exports = {
    todayKey,
    detectPage,
    taskTitle,
    taskDocument,
    titleEndpoint,
    readSummary,
  };
}

// ------------------------------------------------------------- browser bits

/* global GM_getValue, GM_setValue, GM_deleteValue, GM_xmlhttpRequest,
   GM_registerMenuCommand, document, window, location, MutationObserver, alert,
   prompt, setTimeout */

if (typeof window !== 'undefined') {
  const BUTTON_ID = 'seedling-pick-up';

  /** GM_xmlhttpRequest so Google's endpoints are reached without CORS games. */
  function request(method, url, { headers = {}, body } = {}) {
    return new Promise((resolve, reject) => {
      GM_xmlhttpRequest({
        method,
        url,
        headers: { 'Content-Type': 'application/json', ...headers },
        data: body ? JSON.stringify(body) : undefined,
        onload: (res) => {
          let parsed = null;
          try {
            parsed = JSON.parse(res.responseText);
          } catch {
            /* some endpoints answer empty */
          }
          if (res.status >= 200 && res.status < 300) return resolve(parsed);
          reject(new Error(parsed?.error?.message || `HTTP ${res.status}`));
        },
        onerror: () => reject(new Error('network error')),
      });
    });
  }

  /**
   * Signs in once and keeps only the refresh token. The password never touches
   * storage.
   */
  async function signIn() {
    const email = prompt('Seedling email');
    if (!email) return false;
    const password = prompt('Seedling password');
    if (!password) return false;

    const res = await request(
      'POST',
      `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${config().apiKey}`,
      { body: { email, password, returnSecureToken: true } },
    );
    GM_setValue('refreshToken', res.refreshToken);
    GM_setValue('uid', res.localId);
    GM_deleteValue('idToken');
    return true;
  }

  /** A valid access token, refreshed when the cached one is close to expiry. */
  async function accessToken() {
    const cached = GM_getValue('idToken');
    const expiry = GM_getValue('idTokenExpiry', 0);
    if (cached && Date.now() < expiry - 60_000) return cached;

    const refreshToken = GM_getValue('refreshToken');
    if (!refreshToken) throw new Error('not signed in');

    const res = await request(
      'POST',
      `https://securetoken.googleapis.com/v1/token?key=${config().apiKey}`,
      { body: { grant_type: 'refresh_token', refresh_token: refreshToken } },
    );
    GM_setValue('idToken', res.id_token);
    GM_setValue('idTokenExpiry', Date.now() + Number(res.expires_in) * 1000);
    // Google may hand back a rotated refresh token.
    if (res.refresh_token) GM_setValue('refreshToken', res.refresh_token);
    return res.id_token;
  }

  /** Asks Jira or Bitbucket itself, rather than scraping a DOM that moves. */
  async function fetchSummary(page) {
    try {
      const res = await fetch(titleEndpoint(page), {
        credentials: 'same-origin',
        headers: { Accept: 'application/json' },
      });
      if (!res.ok) throw new Error(String(res.status));
      return readSummary(page, await res.json());
    } catch {
      // Falling back to the tab title beats refusing to add anything.
      return document.title.replace(/\s*[-–|]\s*(Jira|Bitbucket).*$/i, '').trim();
    }
  }

  async function addTask(page, button) {
    const label = button.textContent;
    button.disabled = true;
    button.textContent = 'Adding…';
    try {
      if (!GM_getValue('refreshToken') && !(await signIn())) {
        button.textContent = label;
        button.disabled = false;
        return;
      }

      const token = await accessToken();
      const uid = GM_getValue('uid');
      const title = taskTitle(page, await fetchSummary(page));

      await request('POST', `${firestoreFor(config().projectId)}/users/${uid}/tasks`, {
        headers: { Authorization: `Bearer ${token}` },
        body: taskDocument({
          title,
          dayKey: todayKey(),
          tagId: GM_getValue('tagId', null),
        }),
      });

      button.textContent = '✓ On today';
      setTimeout(() => {
        button.textContent = label;
        button.disabled = false;
      }, 2500);
    } catch (error) {
      button.textContent = '✗ Failed';
      button.disabled = false;
      // eslint-disable-next-line no-console
      console.error('[Seedling]', error);
      alert(`Seedling could not add that task:\n${error.message}`);
      setTimeout(() => (button.textContent = label), 2500);
    }
  }

  function makeButton(page) {
    const button = document.createElement('button');
    button.id = BUTTON_ID;
    button.type = 'button';
    button.textContent =
      page.kind === 'jira' ? '🌱 Pick up' : '🌱 Review today';
    button.title = 'Add this to today in Seedling';
    Object.assign(button.style, {
      position: 'fixed',
      right: '18px',
      bottom: '18px',
      zIndex: '2147483647',
      padding: '10px 14px',
      borderRadius: '999px',
      border: '1.5px solid #2E8B57',
      background: '#F9F5EC',
      color: '#111111',
      font: '600 13px/1.2 -apple-system, system-ui, sans-serif',
      cursor: 'pointer',
      boxShadow: '0 2px 10px rgba(0,0,0,.18)',
    });
    button.addEventListener('click', () => addTask(page, button));
    return button;
  }

  /** Both sites are single-page apps, so the button is re-evaluated on change. */
  function sync() {
    const page = detectPage(location.href);
    const existing = document.getElementById(BUTTON_ID);
    if (!page) {
      existing?.remove();
      return;
    }
    if (existing?.dataset.key === JSON.stringify(page)) return;
    existing?.remove();
    const button = makeButton(page);
    button.dataset.key = JSON.stringify(page);
    document.body.appendChild(button);
  }

  GM_registerMenuCommand('Seedling: sign in again', () => {
    GM_deleteValue('refreshToken');
    GM_deleteValue('idToken');
    signIn().then((ok) => ok && alert('Signed in.'));
  });

  GM_registerMenuCommand('Seedling: set tag id (optional)', () => {
    const current = GM_getValue('tagId', '') || '';
    const next = prompt('Tag id to file these under, e.g. work', current);
    if (next === null) return;
    if (next.trim() === '') GM_deleteValue('tagId');
    else GM_setValue('tagId', next.trim());
  });

  sync();
  new MutationObserver(sync).observe(document.body, {
    childList: true,
    subtree: true,
  });
  window.addEventListener('popstate', sync);
}
