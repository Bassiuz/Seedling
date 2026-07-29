const test = require('node:test');
const assert = require('node:assert/strict');

const {
  todayKey,
  detectPage,
  taskTitle,
  taskDocument,
  titleEndpoint,
  readSummary,
} = require('../seedling.user.js');

test('todayKey matches the app’s day keys', () => {
  assert.equal(todayKey(new Date(2026, 6, 28)), '2026-07-28');
  assert.equal(todayKey(new Date(2026, 0, 5)), '2026-01-05', 'zero padded');
});

test('a Jira permalink is recognised', () => {
  const page = detectPage('https://example.atlassian.net/browse/MED-1234');
  assert.equal(page.kind, 'jira');
  assert.equal(page.key, 'MED-1234');
  assert.equal(page.origin, 'https://example.atlassian.net');
});

test('a Jira board with an issue selected is recognised', () => {
  const page = detectPage(
    'https://example.atlassian.net/jira/software/projects/MED/boards/3?selectedIssue=MED-99',
  );
  assert.equal(page.key, 'MED-99');
});

test('a Jira board with nothing selected is not a ticket page', () => {
  assert.equal(
    detectPage('https://example.atlassian.net/jira/software/projects/MED/boards/3'),
    null,
  );
});

test('something that only looks like a key is rejected', () => {
  assert.equal(detectPage('https://example.atlassian.net/browse/notakey'), null);
});

test('a Bitbucket pull request is recognised, including deep links', () => {
  const page = detectPage(
    'https://bitbucket.org/example/backend/pull-requests/42/some-slug/diff',
  );
  assert.equal(page.kind, 'bitbucket');
  assert.equal(page.workspace, 'example');
  assert.equal(page.repo, 'backend');
  assert.equal(page.id, '42');
});

test('a Bitbucket repo page is not a pull request', () => {
  assert.equal(detectPage('https://bitbucket.org/example/backend/src/main'), null);
});

test('unrelated sites and rubbish are ignored', () => {
  assert.equal(detectPage('https://example.com/browse/MED-1'), null);
  assert.equal(detectPage('not a url'), null);
});

test('a Jira task reads as key then summary', () => {
  const page = { kind: 'jira', key: 'MED-1234' };
  assert.equal(taskTitle(page, 'Fix the login bug'), 'MED-1234 Fix the login bug');
});

test('a Jira task without a summary still names the ticket', () => {
  assert.equal(taskTitle({ kind: 'jira', key: 'MED-1' }, '  '), 'MED-1');
});

test('a Bitbucket task says it is a review', () => {
  const page = { kind: 'bitbucket', repo: 'backend', id: '42' };
  assert.equal(taskTitle(page, 'Add caching'), 'Review backend#42: Add caching');
  assert.equal(taskTitle(page, ''), 'Review backend#42');
});

test('the document matches the app’s Task shape', () => {
  const doc = taskDocument({ title: 'MED-1 Thing', dayKey: '2026-07-28' });

  assert.deepEqual(Object.keys(doc.fields).sort(), [
    'completedOnDate',
    'createdDate',
    'date',
    'tagId',
    'time',
    'timeEntries',
    'title',
  ]);
  assert.equal(doc.fields.title.stringValue, 'MED-1 Thing');
  assert.equal(doc.fields.date.stringValue, '2026-07-28');
  assert.equal(doc.fields.createdDate.stringValue, '2026-07-28');
  // An open, untimed task, so the rollover rule carries it forward.
  assert.ok('nullValue' in doc.fields.completedOnDate);
  assert.ok('nullValue' in doc.fields.time);
  assert.ok('nullValue' in doc.fields.tagId);
});

test('a tag is sent as a string when one is configured', () => {
  const doc = taskDocument({ title: 'x', dayKey: '2026-07-28', tagId: 'work' });
  assert.equal(doc.fields.tagId.stringValue, 'work');
});

test('titles are looked up through each site’s own API', () => {
  assert.equal(
    titleEndpoint({
      kind: 'jira',
      key: 'MED-1',
      origin: 'https://example.atlassian.net',
    }),
    'https://example.atlassian.net/rest/api/3/issue/MED-1?fields=summary',
  );
  assert.equal(
    titleEndpoint({
      kind: 'bitbucket',
      workspace: 'example',
      repo: 'backend',
      id: '42',
      origin: 'https://bitbucket.org',
    }),
    'https://bitbucket.org/!api/2.0/repositories/example/backend/pullrequests/42',
  );
});

test('summaries are read out of either API response', () => {
  assert.equal(
    readSummary({ kind: 'jira' }, { fields: { summary: 'Fix login' } }),
    'Fix login',
  );
  assert.equal(readSummary({ kind: 'bitbucket' }, { title: 'Add caching' }), 'Add caching');
});

test('a response missing the field does not throw', () => {
  assert.equal(readSummary({ kind: 'jira' }, {}), '');
  assert.equal(readSummary({ kind: 'bitbucket' }, null), '');
});
