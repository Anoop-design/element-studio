import * as T from 'three';
import { FontLoader } from './vendor/FontLoader.js';
import { BADGES, makeMaterials, buildBadge, applyExplode, applyFinish, drawMemory, updateSand } from './objects.js';
const $ = id => document.getElementById(id);
const viewport = $('viewport'),
  canvas = $('scene');
const media = matchMedia('(prefers-reduced-motion: reduce)');
const state = {
  selected: 'stopwatch',
  studies: {},
  arrangement: 'trio',
  finish: 'crafted',
  explode: 0,
  wireframe: false,
  roughness: .32,
  light: -35,
  exposure: 1,
  backdrop: 'charcoal',
  yaw: -.17,
  pitch: .055,
  targetYaw: -.17,
  targetPitch: .055,
  velocity: 0,
  pitchVelocity: 0,
  zoom: 1,
  reduced: media.matches
};
const requestedObject = new URLSearchParams(location.search).get('object');
if (BADGES.some(badge => badge.id === requestedObject)) {
  state.selected = requestedObject;
  state.arrangement = 'single';
  state.yaw = state.targetYaw = -.28;
  state.pitch = state.targetPitch = .10;
}
let renderer,
  scene,
  camera,
  materials,
  font,
  photo,
  defaultPhoto,
  active = [],
  cache = new Map(),
  rig,
  shadowPlane;
let raf = 0,
  lastTime = 0,
  spring = false,
  reveal = null,
  pointer = null,
  stopped = false,
  frameCount = 0,
  layoutRevision = 0;
const color = new T.Color();
function studioEnvironment() {
  const room = new T.Scene();
  room.background = new T.Color(.105, .115, .13);
  const sphere = new T.Mesh(new T.SphereGeometry(14, 32, 24), new T.MeshBasicMaterial({
    color: new T.Color(.13, .145, .165),
    side: T.BackSide
  }));
  room.add(sphere);
  const emitter = (w, h, position, energy) => {
    const mat = new T.MeshBasicMaterial({
      color: new T.Color(energy, energy * .98, energy * .94),
      side: T.DoubleSide
    });
    const panel = new T.Mesh(new T.PlaneGeometry(w, h), mat);
    panel.position.set(...position);
    panel.lookAt(0, 0, 0);
    room.add(panel);
  };
  emitter(4.5, 6, [-4.5, 5, 6], 5.5);
  emitter(5, 3, [5, 1, 5], 1.05);
  emitter(.55, 6, [4, 4, -4], 4);
  emitter(6, 1, [-1, -5, 4], .45);
  const pmrem = new T.PMREMGenerator(renderer);
  const target = pmrem.fromScene(room, .035, .1, 50);
  pmrem.dispose();
  room.traverse(o => {
    o.geometry?.dispose();
    o.material?.dispose();
  });
  return target;
}
function initializeLights() {
  const key = new T.DirectionalLight(0xfff4e8, 1.9);
  key.position.set(-3, 4, 5);
  key.castShadow = true;
  key.shadow.mapSize.set(1536, 1536);
  Object.assign(key.shadow.camera, {
    left: -6,
    right: 6,
    top: 6,
    bottom: -6,
    near: .1,
    far: 20
  });
  key.shadow.bias = -.0003;
  key.shadow.normalBias = .03;
  key.shadow.radius = 3;
  scene.add(key);
  const fill = new T.DirectionalLight(0xb6d7ff, .65);
  fill.position.set(4, 1, 4);
  scene.add(fill);
  const rim = new T.DirectionalLight(0xeaf2ff, 1.7);
  rim.position.set(3, 3, -4);
  scene.add(rim);
  const ambient = new T.HemisphereLight(0xb4c9d8, 0x11151a, .3);
  scene.add(ambient);
  rig = {
    key,
    fill,
    rim,
    ambient
  };
  shadowPlane = new T.Mesh(new T.PlaneGeometry(28, 28), new T.ShadowMaterial({
    opacity: .065
  }));
  shadowPlane.position.z = -.50;
  shadowPlane.receiveShadow = true;
  scene.add(shadowPlane);
}
function modelKey(id) {
  const study=state.studies[id] || (id==='ribbon'?'folded':'curved');
  return id+':'+study;
}
function model(id) {
  const key=modelKey(id),study=key.split(':')[1];
  if (!cache.has(key)) {
    const item = buildBadge(id, materials, font, photo,study);
    cache.set(key, item);
  }
  return cache.get(key);
}
function setPressed(selector, attribute, value) {
  document.querySelectorAll(selector).forEach(b => b.setAttribute('aria-pressed', String(b.dataset[attribute] === value)));
}
function displayInfo() {
  const meta = active.find(item=>item.name===state.selected)?.userData.meta || BADGES.find(b => b.id === state.selected);
  if (state.arrangement === 'single') {
    $('object-category').textContent = meta.category;
    $('object-title').textContent = meta.sub;
    $('object-description').textContent = meta.description;
    $('geometry-note').textContent = meta.geometry;
  } else if (state.arrangement === 'trio') {
    $('object-category').textContent = 'Three reference objects';
    $('object-title').textContent = 'Precision. Time. Memory.';
    $('object-description').textContent = 'Three different kinds of construction, connected by carefully controlled materials and light.';
    $('geometry-note').textContent = 'A lathed timing case, curved glass chambers, and a domed heart shell. Rotate the objects to see their construction from every side.';
  } else {
    $('object-category').textContent = 'The complete family';
    $('object-title').textContent = 'Sixteen physical studies.';
    $('object-description').textContent = 'Shared materials and lighting, with individual construction for each story. Select any Highlight below to inspect it closely.';
    $('geometry-note').textContent = 'Each kind has actual depth, a front and reverse, and individually modeled details. The three reference objects set the standard; supporting forms remain shape studies.';
  }
  document.querySelector('.memory-options').hidden = !(state.selected === 'memory' && state.arrangement === 'single');
  $('form-studies').hidden=!(state.arrangement==='single' && ['returning','ribbon'].includes(state.selected));
  setPressed('[data-study]','study',state.studies[state.selected] || (state.selected==='ribbon'?'folded':'curved'));
  setPressed('[data-arrangement]', 'arrangement', state.arrangement);
  document.querySelectorAll('[data-badge]').forEach(b => b.setAttribute('aria-pressed', String(state.arrangement === 'single' && b.dataset.badge === state.selected)));
  canvas.setAttribute('aria-label', state.arrangement === 'single' ? `${meta.sub}: ${meta.description} Drag to rotate or use the orientation buttons.` : `${state.arrangement === 'trio' ? 'Three reference' : 'Sixteen'} live 3D badge objects. Drag to rotate or choose a badge below.`);
}
async function layout() {
  const revision=++layoutRevision;
  const ids = state.arrangement === 'trio' ? ['stopwatch', 'hourglass', 'memory'] : state.arrangement === 'family' ? BADGES.map(b => b.id) : [state.selected];
  try {
    $('error').hidden=true;
    setPressed('[data-arrangement]', 'arrangement', state.arrangement);
    for(const [index,id] of ids.entries()) {
      if(cache.has(modelKey(id)))continue;
      $('loading').textContent=ids.length===1?'Preparing the object…':`Preparing the objects… ${index+1} of ${ids.length}`;
      $('loading').hidden=false;
      canvas.setAttribute('aria-busy','true');
      // Paint progress and accept input between objects. A newer choice cancels
      // this layout before it can replace the scene; completed models stay cached.
      await new Promise(resolve=>requestAnimationFrame(()=>setTimeout(resolve,0)));
      if(revision!==layoutRevision)return;
      model(id);
    }
    if(revision!==layoutRevision)return;
    shadowPlane.visible = state.explode === 0;
    for (const item of active) scene.remove(item);
    active = ids.map(model);
    const w = Math.max(1, viewport.clientWidth),
      h = Math.max(1, viewport.clientHeight),
      aspect = w / h;
    const compact = state.arrangement === 'trio' && aspect < .90;
    active.forEach((item, i) => {
      item.position.set(0, 0, 0);
      item.scale.setScalar(1);
      if (state.arrangement === 'trio') {
        if (compact) {
          const p = [[-1.12, .94], [1.12, .94], [0, -1.19]][i];
          item.position.set(...p, 0);
          item.scale.setScalar(.84);
        } else {
          item.position.x = (i - 1) * 2.52;
          item.position.y = i === 0 ? -.065 : .035;
          item.scale.setScalar(i === 1 ? 1.03 : 1);
        }
      } else if (state.arrangement === 'family') {
        item.position.set((i % 4 - 1.5) * 2.56, (1.5 - Math.floor(i / 4)) * 2.46, 0);
        item.scale.setScalar(.9);
      }
      applyExplode(item, state.explode);
      applyFinish(item, state.finish, materials, state.wireframe);
      scene.add(item);
    });
    $('stage-labels').hidden = state.arrangement !== 'trio' || compact;
    let width = state.arrangement === 'family' ? 10.7 : state.arrangement === 'trio' ? compact ? 4.30 : 7.7 : 2.70;
    let height = state.arrangement === 'family' ? 10.55 : state.arrangement === 'trio' ? compact ? 4.55 : 2.65 : 2.82;
    width += state.explode * .8;
    height += state.explode * 1.1;
    const tan = Math.tan(T.MathUtils.degToRad(camera.fov / 2));
    const d = Math.max(height / 2 / tan, width / 2 / tan / aspect);
    camera.position.set(0, .025, d / state.zoom);
    camera.aspect = aspect;
    camera.lookAt(0, 0, 0);
    camera.updateProjectionMatrix();
    renderer.setSize(w, h, false);
    displayInfo();
    setBackdrop();
    invalidate();
  } catch(error) {
    if(revision!==layoutRevision)return;
    console.error(error);
    $('error').hidden=false;
    $('error').textContent='This arrangement could not be prepared. Choose an object or try this view again.';
  } finally {
    if(revision===layoutRevision) {
      $('loading').hidden=true;
      canvas.setAttribute('aria-busy','false');
    }
  }
}
function setBackdrop() {
  if (state.backdrop === 'charcoal') scene.background = new T.Color('#141b22');else {
    const meta = BADGES.find(b => b.id === state.selected);
    color.set(meta.color).multiplyScalar(.105);
    scene.background = color.clone();
  }
  invalidate();
}
function updateLight() {
  const angle = T.MathUtils.degToRad(state.light);
  rig.key.position.set(Math.sin(angle) * 6, 4.2, Math.cos(angle) * 6);
  scene.environmentRotation.set(0, angle - T.MathUtils.degToRad(-35), 0);
  $('light-out').textContent = `${state.light}°`;
  invalidate();
}
function invalidate() {
  if (!raf && !stopped && !document.hidden) raf = requestAnimationFrame(frame);
}
function frame(time) {
  raf = 0;
  const dt = Math.min(.032, (time - lastTime) / 1000 || .016);
  lastTime = time;
  let moving = false;
  if (reveal) {
    const t = Math.min(1, (time - reveal.start) / 1200);
    const q = t * t * (3 - 2 * t);
    state.yaw = -Math.PI * 2 * (1 - q);
    state.pitch = Math.sin(t * Math.PI) * .105;
    for (const item of active) updateSand(item, q, t > .1 && t < .96);
    if (t >= 1) {
      reveal = null;
      state.yaw = state.targetYaw = 0;
      state.pitch = state.targetPitch = 0;
    } else moving = true;
  } else if (spring) {
    const a = -150 * (state.yaw - state.targetYaw) - 25 * state.velocity;
    state.velocity += a * dt;
    state.yaw += state.velocity * dt;
    const pa = -145 * (state.pitch - state.targetPitch) - 24 * state.pitchVelocity;
    state.pitchVelocity += pa * dt;
    state.pitch += state.pitchVelocity * dt;
    if (Math.abs(state.yaw - state.targetYaw) < .0005 && Math.abs(state.velocity) < .002 && Math.abs(state.pitch - state.targetPitch) < .0005) {
      state.yaw = state.targetYaw;
      state.pitch = state.targetPitch;
      state.velocity = 0;
      state.pitchVelocity = 0;
      spring = false;
    } else moving = true;
  }
  for (const item of active) {
    item.rotation.y = state.yaw;
    item.rotation.x = state.pitch;
  }
  renderer.toneMappingExposure = state.exposure;
  renderer.render(scene, camera);
  frameCount++;
  if (moving) invalidate();
}
function stopReveal() {
  reveal = null;
  spring = false;
  for (const item of active) updateSand(item, 1, false);
}
function pose(yaw, pitch = 0) {
  stopReveal();
  state.targetYaw = yaw;
  state.targetPitch = pitch;
  state.velocity = 0;
  state.pitchVelocity = 0;
  if (state.reduced) {
    state.yaw = yaw;
    state.pitch = pitch;
  } else spring = true;
  invalidate();
}
function replay() {
  stopReveal();
  if (state.reduced) {
    pose(0);
    return;
  }
  reveal = {
    start: performance.now()
  };
  state.yaw = -Math.PI * 2;
  state.pitch = 0;
  invalidate();
}
function choose(id) {
  state.selected = id;
  state.arrangement = 'single';
  state.zoom = 1;
  stopReveal();
  state.yaw = state.targetYaw = -.14;
  state.pitch = state.targetPitch = .045;
  state.explode = 0;
  $('explode').value = 0;
  $('explode-out').textContent = '0%';
  layout();
  document.querySelector('.viewport-panel').scrollIntoView({
    behavior: state.reduced ? 'auto' : 'smooth',
    block: 'start'
  });
}
function wireControls() {
  document.querySelectorAll('[data-study]').forEach(button=>button.addEventListener('click',()=>{
    stopReveal();state.studies[state.selected]=button.dataset.study;layout();
  }));
  const picker = $('badge-picker');
  for (const b of BADGES) {
    const button = document.createElement('button');
    button.dataset.badge = b.id;
    button.style.setProperty('--badge-color', b.color);
    button.setAttribute('aria-pressed', 'false');
    const strong = document.createElement('strong');
    strong.textContent = b.name;
    const small = document.createElement('small');
    small.textContent = b.sub;
    button.append(strong, small);
    button.addEventListener('click', () => choose(b.id));
    picker.append(button);
  }
  document.querySelectorAll('[data-arrangement]').forEach(b => b.addEventListener('click', () => {
    stopReveal();
    state.arrangement = b.dataset.arrangement;
    state.zoom = 1;
    state.yaw = state.targetYaw = -.17;
    state.pitch = state.targetPitch = .055;
    layout();
  }));
  document.querySelectorAll('[data-pose]').forEach(b => b.addEventListener('click', () => pose(b.dataset.pose === 'front' ? 0 : b.dataset.pose === 'edge' ? Math.PI / 2 : Math.PI)));
  $('replay').addEventListener('click', replay);
  document.querySelectorAll('[data-finish]').forEach(b => b.addEventListener('click', () => {
    state.finish = b.dataset.finish;
    setPressed('[data-finish]', 'finish', state.finish);
    for (const item of active) applyFinish(item, state.finish, materials, state.wireframe);
    $('material-note').textContent = state.finish === 'clay' ? 'Neutral clay exposes the actual geometry without colored material or metallic reflections.' : state.finish === 'satin' ? 'The same geometry in one satin material, for a direct assessment of form.' : 'The glass, enamel, bevels and satin body have separate material responses.';
    invalidate();
  }));
  $('roughness').addEventListener('input', e => {
    state.roughness = Number(e.target.value) / 100;
    materials.satin.roughness = state.roughness;
    materials.polished.roughness = Math.max(.07, state.roughness * .44);
    $('roughness-out').textContent = `${state.roughness < .25 ? 'Polished' : 'Satin'} · ${state.roughness.toFixed(2)}`;
    invalidate();
  });
  $('explode').addEventListener('input', e => {
    const next = Number(e.target.value) / 100;
    stopReveal();
    if (state.explode === 0 && next > 0) {
      state.explodePose = {
        yaw: state.yaw,
        pitch: state.pitch
      };
      state.yaw = state.targetYaw = -.72;
      state.pitch = state.targetPitch = .16;
    }
    if (next === 0 && state.explodePose) {
      state.yaw = state.targetYaw = state.explodePose.yaw;
      state.pitch = state.targetPitch = state.explodePose.pitch;
      delete state.explodePose;
    }
    state.explode = next;
    $('explode-out').textContent = `${e.target.value}%`;
    layout();
  });
  $('wireframe').addEventListener('change', e => {
    state.wireframe = e.target.checked;
    for (const item of active) applyFinish(item, state.finish, materials, state.wireframe);
    invalidate();
  });
  $('light-angle').addEventListener('input', e => {
    state.light = Number(e.target.value);
    updateLight();
  });
  $('exposure').addEventListener('input', e => {
    state.exposure = Number(e.target.value) / 100;
    $('exposure-out').textContent = state.exposure.toFixed(2);
    invalidate();
  });
  document.querySelectorAll('[data-backdrop]').forEach(b => b.addEventListener('click', () => {
    state.backdrop = b.dataset.backdrop;
    setPressed('[data-backdrop]', 'backdrop', state.backdrop);
    setBackdrop();
  }));
  $('reduce-motion').checked = state.reduced;
  $('reduce-motion').addEventListener('change', e => {
    state.reduced = e.target.checked;
    if (state.reduced) {
      stopReveal();
      pose(Math.round(state.yaw / Math.PI) * Math.PI);
    }
    invalidate();
  });
  media.addEventListener('change', e => {
    state.reduced = e.matches;
    $('reduce-motion').checked = e.matches;
    if (e.matches) {
      stopReveal();
      pose(0);
    }
  });
  canvas.addEventListener('pointerdown', e => {
    if (e.button !== 0) return;
    stopReveal();
    pointer = {
      id: e.pointerId,
      x: e.clientX,
      y: e.clientY,
      last: performance.now(),
      moved: 0
    };
    state.velocity = 0;
    canvas.setPointerCapture(e.pointerId);
  });
  canvas.addEventListener('pointermove', e => {
    if (!pointer || pointer.id !== e.pointerId) return;
    const now = performance.now(),
      dt = Math.max(.008, (now - pointer.last) / 1000);
    const dx = e.clientX - pointer.x,
      dy = e.clientY - pointer.y;
    const step = dx / viewport.clientWidth * Math.PI * 2;
    state.yaw += step;
    state.pitch = T.MathUtils.clamp(state.pitch + dy / viewport.clientHeight * 1.8, -.65, .65);
    state.velocity = T.MathUtils.clamp(step / dt, -8, 8);
    pointer.moved += Math.abs(dx) + Math.abs(dy);
    pointer.x = e.clientX;
    pointer.y = e.clientY;
    pointer.last = now;
    invalidate();
  });
  const release = e => {
    if (!pointer || pointer.id !== e.pointerId) return;
    pointer = null;
    state.targetYaw = Math.round(state.yaw / Math.PI) * Math.PI;
    state.targetPitch = 0;
    state.pitchVelocity = 0;
    if (state.reduced) {
      state.yaw = state.targetYaw;
      state.pitch = 0;
      state.velocity = 0;
    } else spring = true;
    invalidate();
  };
  canvas.addEventListener('pointerup', release);
  canvas.addEventListener('pointercancel', release);
  canvas.addEventListener('lostpointercapture', release);
  canvas.addEventListener('wheel', e => {
    e.preventDefault();
    state.zoom = T.MathUtils.clamp(state.zoom * Math.exp(-e.deltaY * .001), .65, 2.4);
    layout();
  }, {
    passive: false
  });
  $('photo-input').addEventListener('change', async e => {
    const file = e.target.files?.[0];
    if (!file) return;
    try {
      const bitmap = await createImageBitmap(file);
      const c = document.createElement('canvas');
      c.width = c.height = 1024;
      const ctx = c.getContext('2d');
      const side = Math.min(bitmap.width, bitmap.height);
      ctx.drawImage(bitmap, (bitmap.width - side) / 2, (bitmap.height - side) / 2, side, side, 0, 0, 1024, 1024);
      bitmap.close();
      if (photo !== defaultPhoto) photo.dispose();
      photo = new T.CanvasTexture(c);
      photo.colorSpace = T.SRGBColorSpace;
      model('memory').userData.photoMaterial.map = photo;
      model('memory').userData.photoMaterial.needsUpdate = true;
      invalidate();
    } catch {
      document.querySelector('.memory-options .small').textContent = 'This image could not be opened. Try a JPEG or PNG photo.';
    }
  });
  $('reset-photo').addEventListener('click', () => {
    if (photo !== defaultPhoto) photo.dispose();
    photo = defaultPhoto;
    model('memory').userData.photoMaterial.map = photo;
    model('memory').userData.photoMaterial.needsUpdate = true;
    $('photo-input').value = '';
    invalidate();
  });
  new ResizeObserver(() => {
    if (renderer && camera) layout();
  }).observe(viewport);
  document.addEventListener('visibilitychange', () => {
    if (document.hidden) {
      if (raf) cancelAnimationFrame(raf);
      raf = 0;
      stopReveal();
      spring = false;
    } else invalidate();
  });
  canvas.addEventListener('webglcontextlost', e => {
    e.preventDefault();
    stopped = true;
    if (raf) cancelAnimationFrame(raf);
    raf = 0;
    $('error').hidden = false;
    $('error').textContent = 'The graphics context was interrupted. Reload the page to reopen the studio.';
  });
}
try {
  renderer = new T.WebGLRenderer({
    canvas,
    antialias: true,
    alpha: false,
    powerPreference: 'high-performance'
  });
  renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
  renderer.outputColorSpace = T.SRGBColorSpace;
  renderer.toneMapping = T.ACESFilmicToneMapping;
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = T.PCFSoftShadowMap;
  scene = new T.Scene();
  scene.background = new T.Color('#141b22');
  camera = new T.PerspectiveCamera(32, 1, .1, 100);
  T.DefaultLoadingManager.onLoad = () => { if (font && active.length) invalidate(); };
  materials = makeMaterials();
  const env = studioEnvironment();
  scene.environment = env.texture;
  scene.environmentIntensity = 1.0;
  initializeLights();
  const response = await fetch('./vendor/helvetiker_regular.typeface.json');
  if (!response.ok) throw Error('The local font could not be loaded.');
  font = new FontLoader().parse(await response.json());
  defaultPhoto = photo = drawMemory();
  wireControls();
  await layout();
  updateLight();
  $('loading').hidden = true;
  window.badgeStudio = {
    select: choose,
    arrange(value) {
      state.arrangement = value;
      state.zoom = 1;
      layout();
    },
    replay,
    pose,
    inspect() {
      let meshes = 0,
        triangles = 0,
        parts = 0;
      for (const item of active) item.traverse(o => {
        if (o.isMesh) {
          meshes++;
          triangles += (o.geometry.index?.count ?? o.geometry.attributes.position.count) / 3;
        }
        if (o.userData.explode) parts++;
      });
      return {
        state: {
          ...state
        },
        meshes,
        triangles,
        parts,
        frames: frameCount,
        animating: !!raf || spring || !!reveal,
        objects: active.map(o => o.name),
        preparing: !$('loading').hidden,
        cachedObjects: cache.size,
        webgl: renderer.capabilities.isWebGL2,
        rendererInfo: {
          ...renderer.info.render
        }
      };
    }
  };
} catch (error) {
  console.error(error);
  $('loading').hidden = true;
  $('error').hidden = false;
  $('error').textContent = `The studio could not start: ${error.message}. Open this folder through its local HTTP server in a WebGL2-capable browser.`;
}
