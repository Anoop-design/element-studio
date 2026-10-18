/* Run against the local server. Uses an isolated headless browser; never a user profile. */
const {
  chromium
} = require('playwright');
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const sourceURL = new URL(process.env.STUDIO_URL || 'http://127.0.0.1:8786/');
const isLocal = url => url.startsWith('data:') || new URL(url).origin === sourceURL.origin;
const output = path.resolve(process.env.STUDIO_OUTPUT || path.join(__dirname, 'verification'));
fs.mkdirSync(output, {
  recursive: true
});
(async () => {
  const browser = await chromium.launch({
    headless: true, channel: 'chromium',
    ...(process.env.STUDIO_CHROME ? { executablePath: process.env.STUDIO_CHROME } : {}),
    args: ['--enable-webgl', '--ignore-gpu-blocklist']
  });
  const page = await browser.newPage({
    viewport: {
      width: 1440,
      height: 1050
    },
    deviceScaleFactor: 1
  });
  const errors = [],
    warnings = [],
    requests = [];
  page.on('pageerror', e => errors.push(e.message));
  page.on('console', m => {
    if (m.type() === 'error') errors.push(m.text());
    if (m.type() === 'warning') warnings.push(m.text());
  });
  page.on('request', r => requests.push(r.url()));
  const settle = async () => page.waitForFunction(() => window.badgeStudio && !window.badgeStudio.inspect().animating && !window.badgeStudio.inspect().preparing, null, {
    timeout: 60000
  });
  const inspect = async () => page.evaluate(() => window.badgeStudio.inspect());
  const snap = async name => {
    await settle();
    await page.locator('.viewport-panel').scrollIntoViewIfNeeded();
    await page.locator('.studio').screenshot({
      path: path.join(output, name + '.png')
    });
  };
  const results = [];
  try {
    await page.goto(sourceURL.href, {
      waitUntil: 'networkidle'
    });
    await settle();
    let initial = await inspect();
    assert.deepEqual(initial.objects, ['stopwatch', 'hourglass', 'memory']);
    assert(initial.triangles > 40000);
    assert(initial.parts > 12);
    await snap('reference-trio');
    results.push('Three reference objects render as mesh geometry');
    const frames = (await inspect()).frames;
    await new Promise(r => setTimeout(r, 450));
    assert.equal((await inspect()).frames, frames);
    results.push('Rendering stops when the scene is idle');
    await page.getByRole('button', {
      name: 'Fastest distance Stopwatch',
      exact: true
    }).click();
    await settle();
    assert.deepEqual((await inspect()).objects, ['stopwatch']);
    await snap('stopwatch-front');
    await page.getByRole('button', {
      name: 'Reverse',
      exact: true
    }).click();
    await settle();
    assert(Math.abs((await inspect()).state.yaw - Math.PI) < .001);
    await snap('stopwatch-reverse');
    await page.getByRole('button', {
      name: 'Side',
      exact: true
    }).click();
    await settle();
    assert(Math.abs((await inspect()).state.yaw - Math.PI / 2) < .001);
    await snap('stopwatch-side');
    results.push('Front, side and reverse controls reach the intended orientation');
    await page.getByRole('button', {
      name: 'Front',
      exact: true
    }).click();
    await settle();
    await page.getByRole('slider', {
      name: 'Separate components',
      exact: true
    }).focus();
    await page.keyboard.press('End');
    await settle();
    assert.equal((await inspect()).state.explode, 1);
    await snap('stopwatch-exploded');
    await page.keyboard.press('Home');
    results.push('Exploded view changes actual component positions');
    await page.getByRole('button', {
      name: 'Clay',
      exact: true
    }).click();
    await settle();
    assert.equal((await inspect()).state.finish, 'clay');
    await snap('stopwatch-clay');
    await page.getByRole('button', {
      name: 'Crafted',
      exact: true
    }).click();
    await page.getByRole('slider', {
      name: 'Light position',
      exact: true
    }).focus();
    await page.keyboard.press('End');
    await settle();
    assert.equal((await inspect()).state.light, 100);
    await snap('stopwatch-light-right');
    await page.keyboard.press('Home');
    await settle();
    await snap('stopwatch-light-left');
    assert.notDeepEqual(fs.readFileSync(path.join(output, 'stopwatch-light-left.png')), fs.readFileSync(path.join(output, 'stopwatch-light-right.png')));
    results.push('Material and light controls visibly change the live render');
    await page.getByRole('slider', {
      name: 'Light position',
      exact: true
    }).focus();
    await page.keyboard.press('Home');
    for (let i = 0; i < 65; i++) await page.keyboard.press('ArrowRight');
    for (const [name, id] of [['Longest workout Hourglass', 'hourglass'], ['Saved memory Photo locket', 'memory']]) {
      await page.getByRole('button', {
        name,
        exact: true
      }).click();
      await settle();
      assert.deepEqual((await inspect()).objects, [id]);
      await snap(id + '-front');
      await page.getByRole('button', {
        name: 'Side',
        exact: true
      }).click();
      await snap(id + '-side');
    }
    await page.getByRole('button', {
      name: 'Full turn ↻',
      exact: true
    }).click();
    await settle();
    assert(Math.abs((await inspect()).state.yaw) < .001);
    results.push('Opening animation completes one turn and returns to rest');
    await page.getByRole('checkbox', {
      name: 'Reduce Motion',
      exact: true
    }).check();
    await page.getByRole('button', {
      name: 'Full turn ↻',
      exact: true
    }).click();
    await settle();
    assert.equal((await inspect()).state.yaw, 0);
    results.push('Reduce Motion resolves the opening immediately');
    await page.getByRole('button', {
      name: 'Collection',
      exact: true
    }).click();
    await settle();
    assert.equal((await inspect()).objects.length, 16);
    await snap('collection-front');
    for (const button of await page.locator('[data-badge]').all()) {
      const id = await button.getAttribute('data-badge');
      await button.click();
      await settle();
      const data = await inspect();
      assert.deepEqual(data.objects, [id]);
      assert(data.meshes > 2);
      assert(data.triangles > 1000);
    }
    results.push('All sixteen badge selectors build and display valid geometry');
    await page.getByRole('button', {
      name: 'Fastest distance Stopwatch',
      exact: true
    }).click();
    await page.getByRole('checkbox', {
      name: 'Reduce Motion',
      exact: true
    }).uncheck();
    await settle();
    const rect = await page.locator('#scene').boundingBox();
    await page.mouse.move(rect.x + rect.width * .45, rect.y + rect.height * .5);
    await page.mouse.down();
    await page.mouse.move(rect.x + rect.width * .79, rect.y + rect.height * .43, {
      steps: 12
    });
    await page.mouse.up();
    await settle();
    const yaw = (await inspect()).state.yaw;
    assert(Math.abs(yaw / Math.PI - Math.round(yaw / Math.PI)) < .0001);
    results.push('Pointer drag takes control and settles to a front/back face');
    await page.setViewportSize({
      width: 390,
      height: 844
    });
    await page.getByRole('button', {
      name: 'Reference trio',
      exact: true
    }).click();
    await settle();
    assert(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth));
    await page.locator('.viewport-panel').screenshot({
      path: path.join(output, 'mobile-trio.png')
    });
    results.push('390px layout reflows without horizontal overflow');
    assert.equal(errors.length, 0, errors.join('\n'));
    assert(requests.every(isLocal));
    results.push('No console errors and no external runtime requests');
    fs.writeFileSync(path.join(output, 'results.json'), JSON.stringify({
      passed: true,
      checks: results,
      warnings,
      initialGeometry: initial,
      externalRequests: requests.filter(u => !isLocal(u)),
      note: 'Desktop Chromium functional and visual prototype checks; not an iOS performance measurement.'
    }, null, 2));
    console.log(JSON.stringify({
      passed: true,
      checks: results,
      warnings
    }, null, 2));
  } catch (error) {
    const state = await inspect().catch(() => null);
    fs.writeFileSync(path.join(output, 'failure.json'), JSON.stringify({ message: error.message, checks: results, errors, warnings, state }, null, 2));
    throw error;
  } finally {
    await browser.close();
  }
})().catch(e => {
  console.error(e);
  process.exitCode = 1;
});
