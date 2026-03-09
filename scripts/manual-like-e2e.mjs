import assert from 'node:assert/strict';
import { mkdir, writeFile } from 'node:fs/promises';
import { chromium } from 'playwright';
import { createServer } from 'vite';

const BASE_URL = process.argv[2] || process.env.BASE_URL || 'http://localhost:4173';

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

const report = {
  baseUrl: BASE_URL,
  startedAt: new Date().toISOString(),
  finishedAt: null,
  success: false,
  steps: [],
  error: null,
};

function logStep(name, status, details = '') {
  report.steps.push({
    name,
    status,
    details,
    timestamp: new Date().toISOString(),
  });
}

async function writeReport() {
  await mkdir('test-results', { recursive: true });
  report.finishedAt = new Date().toISOString();
  await writeFile('test-results/manual-like-e2e-report.json', JSON.stringify(report, null, 2), 'utf8');
}

async function waitForServer(page) {
  for (let i = 0; i < 80; i += 1) {
    try {
      await page.goto(BASE_URL, { waitUntil: 'domcontentloaded', timeout: 2000 });
      return;
    } catch {
      await sleep(500);
    }
  }
  throw new Error(`Server was not reachable at ${BASE_URL}`);
}

async function startDevServer() {
  const url = new URL(BASE_URL);
  const port = Number(url.port || 4173);
  const host = url.hostname || '127.0.0.1';

  const viteServer = await createServer({
    server: {
      host,
      port,
      strictPort: true,
    },
  });

  await viteServer.listen();
  return viteServer;
}

function getSemesterSection(page, number) {
  return page
    .locator('div.card-hover')
    .filter({ has: page.locator('h2', { hasText: `Semester ${number}` }) })
    .first();
}

async function getLectureNamesInSemester(page, number) {
  const section = getSemesterSection(page, number);
  const names = await section.locator('h3').allTextContents();
  return names.map((name) => name.trim()).filter(Boolean);
}

async function addLecture(page, { name, ects, examDate, season, description }) {
  await page.getByRole('button', { name: 'Veranstaltung' }).click();
  const modal = page
    .locator('div.fixed.inset-0')
    .filter({ has: page.locator('h2', { hasText: /Neue Veranstaltung|Veranstaltung bearbeiten/ }) })
    .first();

  await modal.locator('label:has-text("Name *") + input').fill(name);
  await modal.locator('label:has-text("ECTS *") + input').fill(String(ects));
  await modal.locator('label:has-text("Turnus der Veranstaltung") + select').selectOption(season);
  await modal.locator('label:has-text("Klausurdatum *") + input').fill(examDate);
  await modal.locator('label:has-text("Beschreibung") + textarea').fill(description);
  await modal.getByRole('button', { name: 'Hinzufügen' }).click();
}

async function dragLectureToSemester(page, lectureName, semesterNumber) {
  const lectureHandle = page
    .locator('div.card-hover.mb-3')
    .filter({ has: page.locator('h3', { hasText: lectureName }) })
    .first();
  const dropZone = getSemesterSection(page, semesterNumber).locator('div.border-dashed').first();
  await dragWithMouse(page, lectureHandle, dropZone);
}

async function dragLectureToParking(page, lectureName) {
  const lectureHandle = page
    .locator('div.card-hover.mb-3')
    .filter({ has: page.locator('h3', { hasText: lectureName }) })
    .first();
  const parkingSection = page
    .locator('div.card-hover')
    .filter({ has: page.locator('h2', { hasText: 'Parkplatz' }) })
    .first();
  const parkingZone = parkingSection.locator('div.border-dashed').first();
  await dragWithMouse(page, lectureHandle, parkingZone);
}

async function dragWithMouse(page, sourceLocator, targetLocator) {
  await sourceLocator.scrollIntoViewIfNeeded();
  await targetLocator.scrollIntoViewIfNeeded();

  const sourceBox = await sourceLocator.boundingBox();
  const targetBox = await targetLocator.boundingBox();

  assert.ok(sourceBox, 'Source element bounding box not available');
  assert.ok(targetBox, 'Target element bounding box not available');

  const sourceX = sourceBox.x + sourceBox.width / 2;
  const sourceY = sourceBox.y + sourceBox.height / 2;
  const targetX = targetBox.x + targetBox.width / 2;
  const targetY = targetBox.y + Math.min(targetBox.height / 2, 80);

  await page.mouse.move(sourceX, sourceY);
  await page.mouse.down();
  await page.mouse.move(targetX, targetY, { steps: 20 });
  await page.mouse.up();
  await page.waitForTimeout(250);
}

async function run() {
  const serverProcess = await startDevServer();
  logStep('Dev server start', 'passed', BASE_URL);

  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext();
  const page = await context.newPage();

  try {
    await waitForServer(page);
    logStep('Server erreichbar', 'passed', BASE_URL);

    // Ensure a clean first-run state to test setup modal
    await page.evaluate(() => localStorage.clear());
    await page.reload({ waitUntil: 'domcontentloaded' });
    logStep('Clean start', 'passed', 'localStorage geleert und Seite neu geladen');

    // 1) First-run setup flow
    await page.getByRole('heading', { name: 'Plan einrichten' }).waitFor({ timeout: 10000 });
    const setupModal = page.locator('div.fixed.inset-0').filter({ has: page.getByRole('heading', { name: 'Plan einrichten' }) }).first();
    await setupModal.locator('label:has-text("Planname") + input').fill('QA Studienplan');
    await setupModal.locator('label:has-text("Regelstudienzeit (Semester)") + input').fill('6');
    await setupModal.locator('label:has-text("Startsemester") + select').selectOption('winter');
    await page.getByRole('button', { name: 'Plan starten' }).click();

    const semesterHeadings = page.locator('h2').filter({ hasText: /^Semester \d+$/ });
    assert.equal(await semesterHeadings.count(), 6, 'Expected 6 initialized semesters');
    logStep('Setup modal + 6 Semester', 'passed', 'Plan gestartet mit 6 Semestern');

    // 2) Plan naming in header
    const planNameInput = page.getByLabel('Planname');
    await planNameInput.fill('QA Studienplan 2026');
    await planNameInput.press('Enter');
    await page.waitForTimeout(150);
    logStep('Planname bearbeiten', 'passed', 'Header-Planname erfolgreich aktualisiert');

    // 3) Add and move lectures with advisory WS/SS behavior
    await addLecture(page, {
      name: 'Algebra I',
      ects: 5,
      examDate: '2026-02-15',
      season: 'winter',
      description: 'Grundlagen Algebra',
    });

    await dragLectureToSemester(page, 'Algebra I', 6);
    const semester6 = getSemesterSection(page, 6);
    await semester6.locator('h3', { hasText: 'Algebra I' }).waitFor();
    await semester6
      .locator('p', { hasText: 'Hinweis: Veranstaltung eher im WS' })
      .first()
      .waitFor();
    logStep('WS-Hinweis nur advisory', 'passed', 'WS-Veranstaltung in SS-Semester eingeplant');

    await addLecture(page, {
      name: 'Programmierung I',
      ects: 3,
      examDate: '2026-03-20',
      season: 'summer',
      description: 'Einfuhrung Programmierung',
    });

    await dragLectureToSemester(page, 'Programmierung I', 5);
    const semester5 = getSemesterSection(page, 5);
    await semester5.locator('h3', { hasText: 'Programmierung I' }).waitFor();
    await semester5
      .locator('p', { hasText: 'Hinweis: Veranstaltung eher im SS' })
      .first()
      .waitFor();
    logStep('SS-Hinweis nur advisory', 'passed', 'SS-Veranstaltung in WS-Semester eingeplant');

    await addLecture(page, {
      name: 'Datenbanken',
      ects: 8,
      examDate: '2026-11-15',
      season: 'both',
      description: 'SQL und Modellierung',
    });

    await dragLectureToSemester(page, 'Datenbanken', 5);
    await semester5.locator('h3', { hasText: 'Datenbanken' }).waitFor();

    // 4) Sorting tests in semester 5
    await semester5.getByRole('button', { name: 'Nach Datum sortieren' }).click();
    await page.waitForTimeout(200);
    const afterDateSort = await getLectureNamesInSemester(page, 5);
    assert.deepEqual(
      afterDateSort.slice(0, 2),
      ['Programmierung I', 'Datenbanken'],
      `Date sorting mismatch: ${JSON.stringify(afterDateSort)}`
    );
    logStep('Sortierung nach Datum', 'passed', JSON.stringify(afterDateSort.slice(0, 2)));

    await semester5.getByRole('button', { name: 'Nach ECTS sortieren' }).click();
    await page.waitForTimeout(200);
    const afterEctsSort = await getLectureNamesInSemester(page, 5);
    assert.deepEqual(
      afterEctsSort.slice(0, 2),
      ['Datenbanken', 'Programmierung I'],
      `ECTS sorting mismatch: ${JSON.stringify(afterEctsSort)}`
    );
    logStep('Sortierung nach ECTS', 'passed', JSON.stringify(afterEctsSort.slice(0, 2)));

    // 5) Edit lecture
    const progCard = semester5.locator('div.card-hover').filter({ has: page.locator('h3', { hasText: 'Programmierung I' }) }).first();
    await progCard.getByRole('button', { name: 'Bearbeiten' }).click();
    const editModal = page
      .locator('div.fixed.inset-0')
      .filter({ has: page.locator('h2', { hasText: 'Veranstaltung bearbeiten' }) })
      .first();
    await editModal.locator('label:has-text("Name *") + input').fill('Programmierung I (Update)');
    await editModal.getByRole('button', { name: 'Aktualisieren' }).click();
    await semester5.locator('h3', { hasText: 'Programmierung I (Update)' }).waitFor();
    logStep('Bearbeiten', 'passed', 'Veranstaltung erfolgreich umbenannt');

    // 6) Move between semester and parking
    await dragLectureToSemester(page, 'Programmierung I (Update)', 4);
    const semester4 = getSemesterSection(page, 4);
    await semester4.locator('h3', { hasText: 'Programmierung I (Update)' }).waitFor();

    await dragLectureToParking(page, 'Programmierung I (Update)');
    const parkingSection = page
      .locator('div.card-hover')
      .filter({ has: page.locator('h2', { hasText: 'Parkplatz' }) })
      .first();
    await parkingSection.locator('h3', { hasText: 'Programmierung I (Update)' }).waitFor();
    logStep('Verschieben Semester/Parkplatz', 'passed', 'Drag-and-drop in beide Richtungen funktioniert');

    // 7) Delete lecture
    page.once('dialog', (dialog) => dialog.accept());
    const parkingProgCard = parkingSection
      .locator('div.card-hover')
      .filter({ has: page.locator('h3', { hasText: 'Programmierung I (Update)' }) })
      .first();
    await parkingProgCard.getByRole('button', { name: 'Löschen' }).click();
    await expectCount(parkingSection.locator('h3', { hasText: 'Programmierung I (Update)' }), 0, 5000);
    logStep('Loeschen', 'passed', 'Veranstaltung im Parkplatz geloescht');

    // 8) Add semester and verify count
    await page.getByRole('button', { name: 'Semester' }).click();
    assert.equal(await semesterHeadings.count(), 7, 'Expected 7 semesters after adding one');
    logStep('Semester erweitern', 'passed', 'Auf 7 Semester erweitert');

    // 9) Persistence: reload and validate plan name + semester count + remaining lecture
    await page.reload({ waitUntil: 'domcontentloaded' });
    await page.getByLabel('Planname').waitFor();
    assert.equal(await page.getByLabel('Planname').inputValue(), 'QA Studienplan 2026');
    assert.equal(await semesterHeadings.count(), 7, 'Expected persisted 7 semesters after reload');
    await getSemesterSection(page, 6).locator('h3', { hasText: 'Algebra I' }).waitFor();
    logStep('Persistenz nach Reload', 'passed', 'Planname, Semesterzahl und Inhalte bleiben erhalten');

    report.success = true;
    await writeReport();
    console.log('PASS: Extensive mouse-like E2E flow completed successfully.');
    console.log('Report: test-results/manual-like-e2e-report.json');
  } finally {
    await context.close();
    await browser.close();
    await serverProcess.close();
  }
}

async function expectCount(locator, expected, timeoutMs) {
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    const count = await locator.count();
    if (count === expected) {
      return;
    }
    await sleep(100);
  }
  assert.equal(await locator.count(), expected, 'Locator count did not reach expected value in time');
}

run().catch(async (error) => {
  report.error = {
    message: error instanceof Error ? error.message : String(error),
    stack: error instanceof Error ? error.stack : undefined,
  };
  logStep('Testlauf', 'failed', report.error.message);
  try {
    await writeReport();
  } catch {
    // Ignore report write failures in final error path.
  }
  console.error('FAIL:', error);
  console.error('Report: test-results/manual-like-e2e-report.json');
  process.exit(1);
});
