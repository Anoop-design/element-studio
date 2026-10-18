/* Export the authored browser geometry into native RealityKit mesh buffers.
 * No badge screenshots, web runtime, or third-party library enters the app.
 * npm ci && npx playwright install chromium; then node export-meshes.cjs --help
 */
const fs = require('node:fs');
const path = require('node:path');
const usage = `Usage: node export-meshes.cjs [http://127.0.0.1:8786/] [--output DIRECTORY] [--overwrite] [--live] [OBJECT_ID ...]
Exports candidate meshes, with photo/sand fixtures. Default output: build/mesh-export.
No IDs means every current variant. Existing files require --overwrite.
Use STUDIO_CHROME for an optional Chromium executable; otherwise install Playwright Chromium.`;
const args = process.argv.slice(2);
if (args.includes('--help') || args.includes('-h')) { console.log(usage); process.exit(0); }
let sourceURL = 'http://127.0.0.1:8786/', output = path.resolve(__dirname, 'build/mesh-export');
let overwrite = false, live = false, gotURL = false;
const onlyIDs = [];
for (let i = 0; i < args.length; i++) {
  const arg = args[i];
  if (arg === '--output') {
    if (!args[i + 1] || args[i + 1].startsWith('--')) throw Error('--output requires a directory');
    output = path.resolve(args[++i]);
  } else if (arg === '--overwrite') overwrite = true;
  else if (arg === '--live') live = true;
  else if (/^https?:\/\//.test(arg) && !gotURL) { sourceURL = arg; gotURL = true; }
  else if (arg.startsWith('-')) throw Error(`Unknown option: ${arg}`);
  else onlyIDs.push(arg);
}
const parsedURL = new URL(sourceURL);
if (!['127.0.0.1', 'localhost', '[::1]'].includes(parsedURL.hostname)) {
  throw Error('Serve the authoring source locally on a loopback host');
}
// Dynamic modules resolve relative to this served directory.
if (!parsedURL.pathname.endsWith('/')) parsedURL.pathname += '/';
sourceURL = parsedURL.href;
const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true, channel: 'chromium',
    ...(process.env.STUDIO_CHROME ? { executablePath: process.env.STUDIO_CHROME } : {}) });
  try {
    const page = await browser.newPage();
    await page.goto(sourceURL);
    await page.waitForFunction(() => window.badgeStudio, null, { timeout: 30000 });
    const exported = await page.evaluate(async ({onlyIDs, live}) => {
      const T = await import('./vendor/three.module.min.js');
      const { FontLoader } = await import('./vendor/FontLoader.js');
      const { BADGES, buildBadge, makeMaterials, drawMemory } = await import('./objects.js');
      const font = new FontLoader().parse(await (await fetch('./vendor/helvetiker_regular.typeface.json')).json());
      const materials = makeMaterials(), photo = drawMemory();
      const roleOf = m => m.userData.studioRole || (m === materials.satin ? 'satin' : m === materials.polished ? 'polished' :
        m === materials.lettering ? 'lettering' : m === materials.ink ? 'ink' :
        m === materials.sand ? 'sand' : m.transmission > 0 ? 'glass' : m.map === photo ? 'photo' : 'enamel');
      const variants=[['returning','folded'],['returning','ceramic'],['ribbon','curved'],['ribbon','ceramic']].map(([id,study])=>({...BADGES.find(b=>b.id===id),id:id+'-'+study,baseID:id,study}));
      const all = [...BADGES, ...variants];
      const unknown = onlyIDs.filter(id => !all.some(meta => meta.id === id));
      if (unknown.length) throw Error(`Unknown object IDs: ${unknown.join(', ')}`);
      const badges = all.filter(meta => !onlyIDs.length || onlyIDs.includes(meta.id)).map(meta => {
        const root = buildBadge(meta.baseID || meta.id, materials, font, photo, meta.study);
        if (live) {
          const removed = [];
          root.traverse(node => { if (node.userData.fixtureInscription) removed.push(node); });
          removed.forEach(node => node.removeFromParent());
        }
        root.updateMatrixWorld(true);
        const batches = new Map();
        root.traverse(node => {
          if (!node.isMesh) return;
          const names = [], offset = new T.Vector3();
          for (let parent = node; parent && parent !== root; parent = parent.parent) {
            if (parent.userData.explode) {
              names.unshift(parent.name);
              const v = parent.userData.explode.clone();
              const a = new T.Vector3().applyMatrix4(parent.parent.matrixWorld);
              v.applyMatrix4(parent.parent.matrixWorld).sub(a);
              offset.add(v);
            }
          }
          const geometry = node.geometry.clone().applyMatrix4(node.matrixWorld);
          const mats = Array.isArray(node.material) ? node.material : [node.material];
          const total = geometry.index?.count ?? geometry.attributes.position.count;
          const groups = Array.isArray(node.material) && geometry.groups.length ? geometry.groups : [{ start: 0, count: total, materialIndex: 0 }];
          for (const group of groups) {
            const material = mats[group.materialIndex], role = roleOf(material);
            const key = names.join('/') + ':' + material.uuid;
            if (!batches.has(key)) batches.set(key, { name: names.at(-1) || 'Fixed details', role,
              color: material.color.clone().convertLinearToSRGB().toArray(), roughness: material.roughness ?? .4,
              metallic: material.metalness ?? 0, explode: offset.toArray(), positions: [], normals: [], uv: [], indices: [] });
            const batch = batches.get(key), remap = new Map();
            for (let i = group.start; i < group.start + group.count; i++) {
              const sourceIndex = geometry.index ? geometry.index.getX(i) : i;
              if (!remap.has(sourceIndex)) {
                remap.set(sourceIndex, batch.positions.length / 3);
                const p = geometry.attributes.position, n = geometry.attributes.normal, uv = geometry.attributes.uv;
                batch.positions.push(p.getX(sourceIndex), p.getY(sourceIndex), p.getZ(sourceIndex));
                batch.normals.push(n.getX(sourceIndex), n.getY(sourceIndex), n.getZ(sourceIndex));
                // Both renderers sample the authored UVs; image orientation is handled by texture upload.
                batch.uv.push(uv?.getX(sourceIndex) || 0, 1 - (uv?.getY(sourceIndex) || 0));
              }
              batch.indices.push(remap.get(sourceIndex));
            }
          }
          geometry.dispose();
        });
        const nativeBatches = [...batches.values()];
        let printSurface;
        if (live) {
          // Project native, data-driven inscriptions onto the actual authored shell.
          // Triangle rasterization runs at export time, never while scrolling history.
          const width=101,height=113,xMin=-1.25,yMin=-1.4,xStep=2.5/(width-1),yStep=2.8/(height-1);
          const front=Array(width*height).fill(null),back=Array(width*height).fill(null);
          for (const batch of nativeBatches) {
            if (batch.role === 'glass') continue;
            const p=batch.positions;
            for(let t=0;t<batch.indices.length;t+=3) {
              const [a,b,c]=batch.indices.slice(t,t+3).map(i=>p.slice(i*3,i*3+3));
              const den=(b[1]-c[1])*(a[0]-c[0])+(c[0]-b[0])*(a[1]-c[1]);
              if(Math.abs(den)<1e-10)continue;
              const loX=Math.max(0,Math.ceil((Math.min(a[0],b[0],c[0])-xMin)/xStep));
              const hiX=Math.min(width-1,Math.floor((Math.max(a[0],b[0],c[0])-xMin)/xStep));
              const loY=Math.max(0,Math.ceil((Math.min(a[1],b[1],c[1])-yMin)/yStep));
              const hiY=Math.min(height-1,Math.floor((Math.max(a[1],b[1],c[1])-yMin)/yStep));
              for(let row=loY;row<=hiY;row++)for(let col=loX;col<=hiX;col++) {
                const x=xMin+col*xStep,y=yMin+row*yStep;
                const u=((b[1]-c[1])*(x-c[0])+(c[0]-b[0])*(y-c[1]))/den;
                const v=((c[1]-a[1])*(x-c[0])+(a[0]-c[0])*(y-c[1]))/den;
                if(u<-.0001||v<-.0001||u+v>1.0001)continue;
                const z=u*a[2]+v*b[2]+(1-u-v)*c[2],i=row*width+col;
                front[i]=front[i]===null?z:Math.max(front[i],z);
                back[i]=back[i]===null?z:Math.min(back[i],z);
              }
            }
          }
          printSurface={width,height,xMin,yMin,xStep,yStep,front,back};
        }
        return { ...meta, id:(live?'live-':'')+meta.id, description:root.userData.meta.description,
          geometry:root.userData.meta.geometry, printSurface, batches: nativeBatches };
      });
      return { badges, photo: photo.image.toDataURL('image/png'), sand: materials.sand.map.image.toDataURL('image/png') };
    }, {onlyIDs, live});
    const names = exported.badges.flatMap(badge => [`ElementStudio-${badge.id}.bin`, `ElementStudio-${badge.id}.json`]);
    names.push('ElementStudio-photo.png', 'ElementStudio-sand.png');
    if (!overwrite) {
      const existing = names.filter(name => fs.existsSync(path.join(output, name)));
      if (existing.length) throw Error(`Refusing to overwrite ${existing.join(', ')}; use a new --output or explicit --overwrite`);
    }
    fs.mkdirSync(output, { recursive: true });
    for (const badge of exported.badges) {
      const chunks = []; let offset = 0;
      for (const batch of badge.batches) {
        for (const key of ['positions', 'normals', 'uv', 'indices']) {
          const values = key === 'indices' ? new Uint32Array(batch[key]) : new Float32Array(batch[key]);
          if ([...values].some(v => !Number.isFinite(v))) throw Error(`${badge.id}: nonfinite ${key}`);
          const buffer = Buffer.alloc(values.length * 4);
          values.forEach((value, index) => key === 'indices' ? buffer.writeUInt32LE(value, index * 4) : buffer.writeFloatLE(value, index * 4));
          batch[key] = { offset, count: values.length };
          chunks.push(buffer); offset += buffer.length;
        }
      }
      fs.writeFileSync(path.join(output, `ElementStudio-${badge.id}.bin`), Buffer.concat(chunks));
      fs.writeFileSync(path.join(output, `ElementStudio-${badge.id}.json`), JSON.stringify(badge));
      console.log(`${badge.id}: ${badge.batches.length} native batches, ${(offset / 1048576).toFixed(2)} MB`);
    }
    for (const texture of ['photo', 'sand']) fs.writeFileSync(path.join(output, `ElementStudio-${texture}.png`), Buffer.from(exported[texture].split(',')[1], 'base64'));
  } finally { await browser.close(); }
})().catch(e => { console.error(e); process.exitCode = 1; });
