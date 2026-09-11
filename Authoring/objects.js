import * as T from 'three';
import { buildFormStudy } from './forms.js';
import { addReverseLogo } from './brand-mark.js';
import { TextGeometry } from './vendor/TextGeometry.js';
export const BADGES = [{
  id: 'stopwatch',
  name: 'Fastest distance',
  sub: 'Stopwatch',
  color: '#346baf',
  category: 'Precision',
  description: 'A machined case, separate fluted crown, recessed blue enamel dial and sixty individually modeled timing marks.',
  geometry: 'The body and bezel have lathed cross-sections. The crown has 32 physical flutes. Lettering and ticks have actual relief; the rear cap has its own seam.'
}, {
  id: 'hourglass',
  name: 'Longest workout',
  sub: 'Hourglass',
  color: '#2d9b94',
  category: 'Time',
  description: 'Continuous curved glass, a narrow neck, warm granular sand and a compact frame. The chambers remain transparent from behind.',
  geometry: 'A continuous lathed glass volume is flattened into a compact object. Curved rails, separate caps and modeled sand beds are individual components.'
}, {
  id: 'memory',
  name: 'Saved memory',
  sub: 'Photo locket',
  color: '#698cbd',
  category: 'Memory',
  description: 'A softly domed heart shell, recessed image, fine enamel gasket and a clear protective window. Choose a local photo to try it.',
  geometry: 'The heart has a constant-width inset lip, a domed rear and a separate curved lens. The photograph is mapped to the actual inset geometry.'
}, {
  id: 'energy',
  name: 'Biggest burn',
  sub: 'Sculpted flame',
  color: '#d54835',
  category: 'Energy',
  description: 'A continuous fire-red enamel flame with a softly crowned face and a fine satin edge. Light passes across it without an internal metal seam.',
  geometry: 'The concave flame is triangulated as one closed outline, then finely subdivided and bent by a smooth analytic surface. The front has no radial fan or crossing ridge.'
}, {
  id: 'distance',
  name: 'Farthest',
  sub: 'Hexagonal token',
  color: '#2497b9',
  category: 'Distance',
  description: 'The established hexagon, now with a machined edge profile and a gently convex recessed face.',
  geometry: 'A real beveled hexagonal body supports a domed enamel inset. The distance and activity mark are solid relief.'
}, {
  id: 'sunrise',
  name: 'First workout',
  sub: 'Dawn',
  color: '#dcad51',
  category: 'Beginnings',
  description: 'A clear half-disc, five broad rays and a softly raised horizon. Warm dawn color stays within the beginning family.',
  geometry: 'The sun, rays and horizon are separately shaped solids. Each ray has a rounded profile and receives the same light as the face.'
}, {
  id: 'pennant',
  name: 'First distance',
  sub: 'Folded pennant',
  color: '#4daf9a',
  category: 'First milestone',
  description: 'A folded pennant with a raised seam and a readable target distance.',
  geometry: 'A genuine stepped fold changes the face plane. A narrow polished frame follows the pennant contour.'
}, {
  id: 'returning',
  name: 'Comeback',
  sub: 'Return arrow',
  color: '#ca8c43',
  category: 'Returning',
  description: 'One rounded return arrow around a workout symbol, with a clear head and an amber enamel face seated inside its satin casting.',
  geometry: 'The curved shaft, round tail and arrowhead form one united outline. A continuous bevel follows the complete silhouette, including the neck of the arrow.'
}, {
  id: 'week',
  name: 'Perfect week',
  sub: 'Seven completed days',
  color: '#35a56c',
  category: 'Rhythm',
  description: 'A softly domed calendar, fitted metal rim and seven completed days.',
  geometry: 'A rounded calendar shell and raised binding seam make the seven-day meaning explicit. The New forms edition replaces the earlier rosette.'
}, {
  id: 'month',
  name: 'Perfect month',
  sub: 'Calendar leaf',
  color: '#438fc0',
  category: 'Rhythm',
  description: 'A gently curved calendar leaf, a raised top seam and a real July 2026 arrangement.',
  geometry: 'The calendar uses the correct 31-day July 2026 layout, starting on Wednesday. Individual day dots sit above the inset plane.'
}, {
  id: 'halfYear',
  name: 'Active half-year',
  sub: 'Six-month medallion',
  color: '#a25b98',
  category: 'Long commitment',
  description: 'A complete six-lobed medallion, clearly marked 6 MONTHS. Six month markers sit around a calm violet enamel center.',
  geometry: 'Six broad scallops belong to one closed casting with a continuous rounded edge. The number and unit carry the meaning from the first glance.'
}, {
  id: 'year',
  name: 'Active year',
  sub: 'Twelve-lobe seal',
  color: '#9cbb76',
  category: 'Long commitment',
  description: 'A twelve-lobe seal with a quiet central year and twelve precise month markers.',
  geometry: 'Twelve scallops and twelve markers are explicitly modeled. The center is recessed so the year remains the primary detail.'
}, {
  id: 'ribbon',
  name: 'Weekly rhythm',
  sub: 'Folded ribbon',
  color: '#a5ad43',
  category: 'Consistency',
  description: 'A sculpted ribbon with a narrow waist, unequal flowing tails, a turned top and a folded return on the reverse. Porcelain lettering sits above the olive glaze.',
  geometry: 'The inset, binding and letters share the same three-dimensional sweep. Fine tessellation and transformed normals keep highlights continuous over the fold and curled tails.'
}, {
  id: 'activity',
  name: 'Weekly run',
  sub: 'Weekly activity medal',
  color: '#289fac',
  category: 'Activity rhythm',
  description: 'An upright activity medal with a sport symbol, explicit week count and teal enamel. Its rounded track-shaped case replaces the eye silhouette.',
  geometry: 'A softly crowned enamel face sits within one continuous satin case. The top and bottom share the same broad radius; there is no artificial twist.'
}, {
  id: 'frequency',
  name: 'Run rhythm',
  sub: 'Frequency crest',
  color: '#3fa2ae',
  category: 'Activity frequency',
  description: 'A grooved crest that carries the explicit sample threshold, independently of its silhouette.',
  geometry: 'A rounded crest and three shallow grooves support the label. The outline stays stable if a canonical threshold changes.'
}, {
  id: 'collection',
  name: 'Rhythms together',
  sub: 'Layered crest',
  color: '#c3b76c',
  category: 'Collection',
  description: 'Two genuinely layered crests with a clear sample count, and carefully separated edges.',
  geometry: 'The front and rear crests are separate beveled bodies. Their offset and shadows express collection without an extra stack pictogram.'
}];
function random(seed = 127) {
  return () => {
    seed = 1664525 * seed + 1013904223 >>> 0;
    return seed / 4294967296;
  };
}
export function makeMaterials() {
  const surface = (name, repeat = 2) => {
    const texture = new T.TextureLoader().load(`./surfaces/${name}.png`);
    texture.wrapS = texture.wrapT = T.RepeatWrapping;
    texture.repeat.set(repeat, repeat);
    return texture;
  };
  const brushedNormal=surface('brush-4'),glazeNormal=surface('glaze-4'),dialNormal=surface('dial',1);
  const canvas = document.createElement('canvas');
  canvas.width = canvas.height = 512;
  const ctx = canvas.getContext('2d');
  const data = ctx.createImageData(512, 512);
  const rng = random();
  for (let y = 0; y < 512; y++) {
    const grain = rng();
    for (let x = 0; x < 512; x++) {
      const i = (y * 512 + x) * 4;
      const v = 125 + Math.round((rng() - .5) * 22 + (grain - .5) * 7);
      data.data.set([v, v, v, 255], i);
    }
  }
  ctx.putImageData(data, 0, 0);
  const bump = new T.CanvasTexture(canvas);
  bump.wrapS = bump.wrapT = T.RepeatWrapping;
  bump.repeat.set(3, 3);
  const satin = new T.MeshPhysicalMaterial({
    color: 0xa6adb3,
    metalness: 1,
    roughness: .32,
    normalMap: brushedNormal,
    roughnessMap: surface('roughness'),
    envMapIntensity: 1.05
  });
  const polished = new T.MeshPhysicalMaterial({
    color: 0xe0e5e9,
    metalness: 1,
    roughness: .14,
    envMapIntensity: 1.15
  });
  const lettering = new T.MeshStandardMaterial({
    color: 0xd8e4ec,
    metalness: .42,
    roughness: .29
  });
  const ink = new T.MeshStandardMaterial({
    color: 0x12232d,
    metalness: .35,
    roughness: .42
  });
  const glass = new T.MeshPhysicalMaterial({
    color: 0xf5ffff,
    metalness: 0,
    roughness: .065,
    transmission: 1,
    ior: 1.46,
    thickness: .12,
    attenuationColor: 0x8fd9d1,
    attenuationDistance: 1.8,
    envMapIntensity: 1.2,
    clearcoat: 1,
    clearcoatRoughness: .055,
    side: T.DoubleSide
  });
  const sandCanvas = document.createElement('canvas');
  sandCanvas.width = sandCanvas.height = 256;
  const sx = sandCanvas.getContext('2d');
  const pixels = sx.createImageData(256, 256);
  for (let i = 0; i < pixels.data.length; i += 4) {
    const v = 130 + rng() * 120;
    pixels.data.set([v, v * .84, v * .49, 255], i);
  }
  sx.putImageData(pixels, 0, 0);
  const sandMap = new T.CanvasTexture(sandCanvas);
  sandMap.colorSpace = T.SRGBColorSpace;
  sandMap.wrapS = sandMap.wrapT = T.RepeatWrapping;
  sandMap.repeat.set(3, 3);
  const sand = new T.MeshStandardMaterial({
    color: 0xd8b477,
    roughness: .76,
    metalness: 0,
    map: sandMap,
    bumpMap: sandMap,
    bumpScale: .004
  });
  const clay = new T.MeshStandardMaterial({
    color: 0xabb4bc,
    roughness: .65,
    metalness: 0
  });
  const enamels = new Map();
  const enamel = color => {
    if (!enamels.has(color)) enamels.set(color, new T.MeshPhysicalMaterial({
      color,
      metalness: 0,
      roughness: .25,
      clearcoat: .72,
      clearcoatRoughness: .09,
      normalMap: glazeNormal,
      envMapIntensity: .65
    }));
    return enamels.get(color);
  };
  return {
    satin,
    polished,
    lettering,
    ink,
    glass,
    sand,
    clay,
    enamel,
    enamels,
    dialNormal,
    bump
  };
}
function mesh(geometry, material) {
  const m = new T.Mesh(geometry, material);
  m.castShadow = true;
  m.receiveShadow = true;
  return m;
}
function part(parent, object, name, vector = [0, 0, 0]) {
  object.name = name;
  object.userData.rest = object.position.clone();
  object.userData.explode = new T.Vector3(...vector);
  parent.add(object);
  return object;
}
function lathe(profile, material, axis = 'z', segments = 128) {
  const g = new T.LatheGeometry(profile.map(p => new T.Vector2(...p)), segments);
  if (axis === 'z') g.rotateX(Math.PI / 2);
  return mesh(g, material);
}
function tube(points, radius, material, segments = 80) {
  return mesh(new T.TubeGeometry(new T.CatmullRomCurve3(points.map(p => new T.Vector3(...p))), segments, radius, 8, false), material);
}
function ring(radius, tubeRadius, z, material) {
  const m = mesh(new T.TorusGeometry(radius, tubeRadius, 10, 128), material);
  m.position.z = z;
  return m;
}
function text(font, value, size, depth, material, x = 0, y = 0, z = 0) {
  const g = new TextGeometry(value, {
    font,
    size,
    depth,
    curveSegments: 5,
    bevelEnabled: depth > .004,
    bevelThickness: Math.min(.002, depth * .25),
    bevelSize: Math.min(.002, depth * .25),
    bevelSegments: 2
  });
  g.computeBoundingBox();
  const b = g.boundingBox;
  g.translate(-(b.max.x + b.min.x) / 2, -(b.max.y + b.min.y) / 2, 0);
  const m = mesh(g, material);
  m.userData.fixtureInscription = true;
  m.position.set(x, y, z);
  return m;
}
function runner(material, scale = 1) {
  const group = new T.Group();
  group.userData.fixtureInscription = true;
  const paths = [[[.03, .19, 0], [-.04, .04, 0], [.06, -.08, 0], [-.05, -.29, 0]], [[-.04, .04, 0], [-.23, -.09, 0], [-.39, -.07, 0]], [[-.04, .15, 0], [.14, .07, 0], [.25, .17, 0]], [[-.03, .17, 0], [-.2, .21, 0], [-.27, .11, 0]]];
  for (const p of paths) group.add(tube(p, .031, material, 24));
  const head = mesh(new T.SphereGeometry(.058, 20, 16), material);
  head.position.set(.08, .32, 0);
  group.add(head);
  group.scale.setScalar(scale);
  return group;
}
function shapePoints(shape, n = 160) {
  let p = shape.getSpacedPoints(n);
  if (p[0].distanceTo(p.at(-1)) < 1e-6) p.pop();
  let area = 0;
  for (let i = 0; i < p.length; i++) {
    const a = p[i],
      b = p[(i + 1) % p.length];
    area += a.x * b.y - b.x * a.y;
  }
  if (area < 0) p.reverse();
  return p;
}
function pathOf(points) {
  const s = new T.Shape();
  s.moveTo(points[0].x, points[0].y);
  for (const p of points.slice(1)) s.lineTo(p.x, p.y);
  s.closePath();
  return s;
}
const offsetCache = new WeakMap();
function inset(points, width) {
  if (Math.abs(width) < 1e-7) return points.map(p => p.clone());
  let cache = offsetCache.get(points);
  if (!cache) {
    cache = new Map();
    offsetCache.set(points, cache);
  }
  if (cache.has(width)) return cache.get(width);
  const C = window.ClipperLib,
    scale = 100000;
  const path = points.map(p => ({
    X: Math.round(p.x * scale),
    Y: Math.round(p.y * scale)
  }));
  const offset = new C.ClipperOffset(2, .0003 * scale);
  offset.AddPath(path, C.JoinType.jtRound, C.EndType.etClosedPolygon);
  const solution = new C.Paths();
  offset.Execute(solution, -width * scale);
  if (!solution.length) {
    const center = points.reduce((sum, p) => sum.add(p), new T.Vector2()).multiplyScalar(1 / points.length);
    return points.map(p => p.clone().lerp(center, .65));
  }
  let polygon = solution.sort((a, b) => Math.abs(C.Clipper.Area(b)) - Math.abs(C.Clipper.Area(a)))[0].map(p => new T.Vector2(p.X / scale, p.Y / scale));
  let area = 0;
  polygon.forEach((a, i) => {
    const b = polygon[(i + 1) % polygon.length];
    area += a.x * b.y - b.x * a.y;
  });
  if (area < 0) polygon.reverse();
  let start = 0,
    best = Infinity;
  polygon.forEach((p, i) => {
    const d = p.distanceToSquared(points[0]);
    if (d < best) {
      best = d;
      start = i;
    }
  });
  polygon = polygon.slice(start).concat(polygon.slice(0, start));
  const lengths = polygon.map((p, i) => p.distanceTo(polygon[(i + 1) % polygon.length]));
  const total = lengths.reduce((a, b) => a + b, 0);
  const sampled = [];
  let edge = 0,
    walked = 0;
  for (let i = 0; i < points.length; i++) {
    const target = i / points.length * total;
    while (edge < lengths.length - 1 && walked + lengths[edge] < target) {
      walked += lengths[edge++];
    }
    sampled.push(polygon[edge].clone().lerp(polygon[(edge + 1) % polygon.length], (target - walked) / Math.max(1e-9, lengths[edge])));
  }
  cache.set(width, sampled);
  return sampled;
}
function extruded(points, depth, bevel, material, z = 0) {
  const g = new T.ExtrudeGeometry(pathOf(points), {
    depth,
    bevelEnabled: bevel > 0,
    bevelThickness: bevel,
    bevelSize: bevel,
    bevelSegments: 5,
    steps: 1,
    curveSegments: 48
  });
  g.translate(0, 0, z);
  return mesh(softenedNormals(g), material);
}
// Long cap triangles must be subdivided before bending; otherwise their flat spans cut
// across the curved enamel even when their boundary vertices share the same deformation.
function softenedNormals(geometry) {
  const g=geometry.clone(),p=g.attributes.position,n=g.attributes.normal,shared=new Map();
  const key=i=>[p.getX(i),p.getY(i),p.getZ(i)].map(v=>Math.round(v*100000)).join(',');
  for(let i=0;i<p.count;i++) {
    const k=key(i);if(!shared.has(k))shared.set(k,[]);
    shared.get(k).push(new T.Vector3().fromBufferAttribute(n,i));
  }
  const original=n.clone(),sum=new T.Vector3(),direction=new T.Vector3();
  for(let i=0;i<p.count;i++) {
    direction.fromBufferAttribute(original,i);
    // The original planar caps need identical normals before the analytic bend.
    // Averaging their boundary with the bevel projects triangulation into reflections.
    if(Math.abs(direction.z)>.999)continue;
    sum.set(0,0,0);
    for(const neighbor of shared.get(key(i)))if(direction.dot(neighbor)>.64)sum.add(neighbor);
    sum.normalize();n.setXYZ(i,sum.x,sum.y,sum.z);
  }
  return g;
}
function tessellateCaps(geometry, maxEdge = .065) {
  const source = geometry.index ? geometry.toNonIndexed() : geometry;
  const p = source.attributes.position, uv = source.attributes.uv, n = source.attributes.normal;
  const positions = [], coordinates = [], normals = [];
  const vertex = i => [p.getX(i), p.getY(i), p.getZ(i), uv.getX(i), uv.getY(i), n.getX(i), n.getY(i), n.getZ(i)];
  const length = (a, b) => (a[0]-b[0]) ** 2 + (a[1]-b[1]) ** 2 + (a[2]-b[2]) ** 2;
  function triangle(a, b, c, subdivide) {
    const ab = length(a,b), bc = length(b,c), ca = length(c,a);
    if (subdivide && Math.max(ab,bc,ca) > maxEdge ** 2) {
      if (bc > ab && bc >= ca) { triangle(b,c,a,true); return; }
      if (ca > ab && ca > bc) { triangle(c,a,b,true); return; }
      const mid = a.map((value, i) => (value + b[i]) / 2);
      triangle(a,mid,c,true); triangle(mid,b,c,true); return;
    }
    const faceNormal=new T.Vector3(b[0]-a[0],b[1]-a[1],b[2]-a[2])
      .cross(new T.Vector3(c[0]-a[0],c[1]-a[1],c[2]-a[2]));
    if(faceNormal.lengthSq()<1e-20)return;
    faceNormal.normalize();
    for (const v of [a,b,c]) {
      positions.push(...v.slice(0,3)); coordinates.push(...v.slice(3,5));
      const length=Math.hypot(...v.slice(5));
      normals.push(...(length>1e-8?v.slice(5).map(n=>n/length):faceNormal.toArray()));
    }
  }
  for (let i = 0; i < p.count; i += 3) triangle(vertex(i),vertex(i+1),vertex(i+2),
    Math.abs(p.getZ(i)-p.getZ(i+1))<1e-7 && Math.abs(p.getZ(i)-p.getZ(i+2))<1e-7);
  const result = new T.BufferGeometry();
  result.setAttribute('position',new T.Float32BufferAttribute(positions,3));
  result.setAttribute('uv',new T.Float32BufferAttribute(coordinates,2));
  result.setAttribute('normal',new T.Float32BufferAttribute(normals,3));
  return result;
}
// Split each shared cap edge on both incident triangles, including its bevel.
// Independent triangle subdivision leaves T-junctions that can open after bending.
function conformingCaps(geometry, maxEdge = .065) {
  const source = geometry.index ? geometry.toNonIndexed() : geometry;
  const p=source.attributes.position, n=source.attributes.normal, uv=source.attributes.uv;
  const vertex=i=>[p.getX(i),p.getY(i),p.getZ(i),uv.getX(i),uv.getY(i),n.getX(i),n.getY(i),n.getZ(i)];
  const length=(a,b)=>(a[0]-b[0])**2+(a[1]-b[1])**2+(a[2]-b[2])**2;
  const pointKey=v=>v.slice(0,3).map(x=>Math.round(x*1e6)).join(',');
  const edgeKey=(a,b)=>{const x=pointKey(a),y=pointKey(b);return x<y?x+'|'+y:y+'|'+x;};
  const midpoint=(a,b)=>a.map((x,i)=>(x+b[i])/2);
  let triangles=[];
  for(let i=0;i<p.count;i+=3)triangles.push({v:[vertex(i),vertex(i+1),vertex(i+2)],cap:
    Math.abs(p.getZ(i)-p.getZ(i+1))<1e-7&&Math.abs(p.getZ(i)-p.getZ(i+2))<1e-7});
  for(let pass=0;pass<12;pass++) {
    const splits=new Set();
    for(const {v,cap} of triangles)if(cap)for(let j=0;j<3;j++)
      if(length(v[j],v[(j+1)%3])>maxEdge**2)splits.add(edgeKey(v[j],v[(j+1)%3]));
    if(!splits.size)break;
    const next=[];
    for(const {v:[a,b,c],cap} of triangles) {
      const ab=splits.has(edgeKey(a,b)),bc=splits.has(edgeKey(b,c)),ca=splits.has(edgeKey(c,a));
      const d=ab?midpoint(a,b):null,e=bc?midpoint(b,c):null,f=ca?midpoint(c,a):null;
      const add=(...v)=>next.push({v,cap});
      switch(Number(ab)+2*Number(bc)+4*Number(ca)) {
        case 0:add(a,b,c);break;
        case 1:add(a,d,c);add(d,b,c);break;
        case 2:add(b,e,a);add(e,c,a);break;
        case 4:add(c,f,b);add(f,a,b);break;
        case 3:add(d,b,e);add(a,d,c);add(d,e,c);break;
        case 5:add(a,d,f);add(d,b,c);add(d,c,f);break;
        case 6:add(c,f,e);add(a,b,f);add(b,e,f);break;
        case 7:add(a,d,f);add(d,b,e);add(f,e,c);add(d,e,f);break;
      }
    }
    triangles=next;
  }
  const positions=[],normals=[],coordinates=[],indices=[],vertices=new Map();
  for(const {v} of triangles) {
    if(new Set(v.map(point=>point.slice(0,3).map(x=>Math.round(x*1e7)).join(','))).size<3)continue;
    for(const point of v) {
      const magnitude=Math.hypot(...point.slice(5))||1;
      const normal=point.slice(5).map(x=>x/magnitude);
      const key=[...point.slice(0,5),...normal].map(x=>Math.round(x*1e8)).join(',');
      if(!vertices.has(key)) {
        vertices.set(key,positions.length/3);
        positions.push(...point.slice(0,3));coordinates.push(...point.slice(3,5));normals.push(...normal);
      }
      indices.push(vertices.get(key));
    }
  }
  const result=new T.BufferGeometry();
  result.setAttribute('position',new T.Float32BufferAttribute(positions,3));
  result.setAttribute('normal',new T.Float32BufferAttribute(normals,3));
  result.setAttribute('uv',new T.Float32BufferAttribute(coordinates,2));
  result.setIndex(indices);
  return result;
}
function unionOutline(shapes, samples = 320) {
  const C = window.ClipperLib, scale = 100000;
  const paths = shapes.map(points => points.map(p => ({X: Math.round(p.x * scale), Y: Math.round(p.y * scale)})));
  const clip = new C.Clipper(), result = new C.Paths();
  clip.AddPaths(paths, C.PolyType.ptSubject, true);
  clip.Execute(C.ClipType.ctUnion, result, C.PolyFillType.pftNonZero, C.PolyFillType.pftNonZero);
  const largest = result.sort((a,b) => Math.abs(C.Clipper.Area(b)) - Math.abs(C.Clipper.Area(a)))[0];
  return shapePoints(pathOf(largest.map(p => new T.Vector2(p.X/scale,p.Y/scale))), samples);
}
function bendAssembly(group, height) {
  group.updateMatrixWorld(true);
  const point = new T.Vector3(), normal = new T.Vector3(), epsilon = .0001;
  group.traverse(node => {
    if (!node.isMesh) return;
    if (node.geometry.type === 'ExtrudeGeometry') node.geometry = (group.userData.conformingCaps ? conformingCaps : tessellateCaps)(softenedNormals(node.geometry), .045);
    const inverse = node.matrixWorld.clone().invert();
    const normalMatrix = new T.Matrix3().getNormalMatrix(node.matrixWorld), inverseNormal = normalMatrix.clone().invert();
    const positions = node.geometry.attributes.position, normals = node.geometry.attributes.normal;
    for (let i=0;i<positions.count;i++) {
      point.fromBufferAttribute(positions,i).applyMatrix4(node.matrixWorld);
      const x=point.x,y=point.y;
      const dx=(height(x+epsilon,y)-height(x-epsilon,y))/(2*epsilon);
      const dy=(height(x,y+epsilon)-height(x,y-epsilon))/(2*epsilon);
      normal.fromBufferAttribute(normals,i).applyMatrix3(normalMatrix).normalize();
      normal.set(normal.x-dx*normal.z,normal.y-dy*normal.z,normal.z).applyMatrix3(inverseNormal).normalize();
      normals.setXYZ(i,normal.x,normal.y,normal.z);
      point.z+=height(x,y);point.applyMatrix4(inverse);
      positions.setXYZ(i,point.x,point.y,point.z);
    }
    positions.needsUpdate=true;normals.needsUpdate=true;
  });
}
function contourRing(points, width, profile, material) {
  profile = [...profile, profile[0]];
  const positions = [],
    uv = [],
    indices = [];
  const N = points.length;
  for (let j = 0; j < profile.length; j++) {
    const [offset, z] = profile[j];
    const pts = inset(points, offset);
    for (let i = 0; i < N; i++) {
      positions.push(pts[i].x, pts[i].y, z);
      uv.push(i / N, j / profile.length);
    }
  }
  for (let j = 0; j < profile.length - 1; j++) for (let i = 0; i < N; i++) {
    const a = j * N + i,
      b = j * N + (i + 1) % N,
      c = b + N,
      d = a + N;
    indices.push(a, b, d, b, c, d);
  }
  const g = new T.BufferGeometry();
  g.setAttribute('position', new T.Float32BufferAttribute(positions, 3));
  g.setAttribute('uv', new T.Float32BufferAttribute(uv, 2));
  g.setIndex(indices);
  g.computeVertexNormals();
  return mesh(g, material);
}
function dome(points, z, rise, material, warp = null, reverse = false) {
  const N = points.length,
    R = 24;
  const p = [0, 0, z + rise],
    uv = [.5, .5],
    idx = [];
  const box = new T.Box2().setFromPoints(points);
  for (let j = 1; j <= R; j++) {
    const r = j / R;
    for (let i = 0; i < N; i++) {
      const x = points[i].x * r,
        y = points[i].y * r;
      p.push(x, y, z + rise * (1 - r * r) + (warp ? warp(x, y) : 0));
      uv.push((x - box.min.x) / (box.max.x - box.min.x), (y - box.min.y) / (box.max.y - box.min.y));
    }
  }
  for (let i = 0; i < N; i++) idx.push(0, 1 + i, 1 + (i + 1) % N);
  for (let j = 1; j < R; j++) for (let i = 0; i < N; i++) {
    const a = 1 + (j - 1) * N + i,
      b = 1 + (j - 1) * N + (i + 1) % N,
      c = b + N,
      d = a + N;
    idx.push(a, d, b, b, d, c);
  }
  if (reverse) {
    for (let i = 0; i < idx.length; i += 3) [idx[i + 1], idx[i + 2]] = [idx[i + 2], idx[i + 1]];
  }
  const g = new T.BufferGeometry();
  g.setAttribute('position', new T.Float32BufferAttribute(p, 3));
  g.setAttribute('uv', new T.Float32BufferAttribute(uv, 2));
  g.setIndex(idx);
  g.computeVertexNormals();
  return mesh(g, material);
}
function radialHeight(points, z, rise) {
  return (x,y)=>{
    if(Math.hypot(x,y)<1e-8)return z+rise;
    let edge=Infinity;
    for(let i=0;i<points.length;i++) {
      const a=points[i],b=points[(i+1)%points.length],dx=b.x-a.x,dy=b.y-a.y;
      const det=x*dy-y*dx;
      if(Math.abs(det)<1e-10)continue;
      const t=(a.x*dy-a.y*dx)/det,u=(a.x*y-a.y*x)/det;
      if(t>0 && u>=0 && u<=1)edge=Math.min(edge,t);
    }
    return z+rise*Math.max(0,1-1/(edge*edge));
  };
}
function medal(points, color, m, font, {
  label = '',
  sub = '',
  back = 'A MOMENT KEPT',
  rise = .045,
  warp = null
} = {}) {
  const group = new T.Group();
  part(group, extruded(inset(points, .032), .16, .032, m.satin, -.11), 'Satin body');
  const rim = contourRing(points, .06, [[.025, .075], [.002, .095], [.010, .118], [.035, .13], [.074, .099]], m.polished);
  part(group, rim, 'Polished retaining lip', [0, 0, .72]);
  const face = new T.Group();
  const facePoints=inset(points,.077);
  face.add(dome(facePoints, .080, rise, m.enamel(color)));
  if (label) face.add(text(font, label, .39, .007, m.lettering, 0, .05, .15));
  if (sub) face.add(text(font, sub, .069, .003, m.lettering, 0, -.29, .14));
  part(group, face, 'Enamel inset', [0, 0, .32]);
  group.userData.face = face;
  group.userData.faceHeight=radialHeight(facePoints,.080,rise);
  group.userData.warp=warp;
  return group;
}

// A continuous cap also works for concave outlines. A radial triangle fan can
// fold across a flame's notch; constrained outline triangulation cannot.
function castMedal(points, color, m, font, { label = '', sub = '', crown = .045 } = {}) {
  const group = new T.Group();
  group.userData.conformingCaps = true;
  part(group, extruded(inset(points, .018), .15, .034, m.satin, -.09), 'Rounded satin casting');
  const face = new T.Group();
  const enamel = m.enamel(color).clone();
  enamel.normalScale.set(.32, .32);
  enamel.userData.studioRole = 'enamel';
  part(face, extruded(inset(points, .063), .023, .025, enamel, .063), 'Continuous enamel crown');
  if (label) face.add(text(font, label, .44, .004, m.lettering, 0, .08, .115));
  if (sub) face.add(text(font, sub, .095, .002, m.lettering, 0, -.28, .115));
  part(group, face, 'Fitted enamel face', [0, 0, .35]);
  group.userData.face = face;
  group.userData.faceHeight = () => .111;
  // One differentiable height function deforms body, bevel and inscriptions.
  group.userData.warp = (x, y) => crown * (1 - .62*x*x - .30*y*y);
  return group;
}

function seatFaceDetails(group) {
  group.updateMatrixWorld(true);
  group.traverse(owner=>{
    const face=owner.userData.face,height=owner.userData.faceHeight;
    if(!face || !height)return;
    const toFace=face.matrixWorld.clone().invert(),p=new T.Vector3(),n=new T.Vector3(),epsilon=.0001;
    for(const child of face.children.slice(owner.userData.faceStart ?? 1)) {
      const meshes=[];let base=Infinity;
      child.traverse(node=>{
        if(!node.isMesh)return;
        const matrix=toFace.clone().multiply(node.matrixWorld),positions=node.geometry.attributes.position;
        for(let i=0;i<positions.count;i++)base=Math.min(base,p.fromBufferAttribute(positions,i).applyMatrix4(matrix).z);
        meshes.push({node,matrix});
      });
      for(const {node,matrix} of meshes) {
        const inverse=matrix.clone().invert(),nm=new T.Matrix3().getNormalMatrix(matrix),ni=nm.clone().invert();
        const positions=node.geometry.attributes.position,normals=node.geometry.attributes.normal;
        for(let i=0;i<positions.count;i++) {
          p.fromBufferAttribute(positions,i).applyMatrix4(matrix);
          const dx=(height(p.x+epsilon,p.y)-height(p.x-epsilon,p.y))/(2*epsilon);
          const dy=(height(p.x,p.y+epsilon)-height(p.x,p.y-epsilon))/(2*epsilon);
          n.fromBufferAttribute(normals,i).applyMatrix3(nm).normalize();
          n.set(n.x-dx*n.z,n.y-dy*n.z,n.z).applyMatrix3(ni).normalize();
          normals.setXYZ(i,n.x,n.y,n.z);
          p.z+=height(p.x,p.y)+.0015-base;p.applyMatrix4(inverse);
          positions.setXYZ(i,p.x,p.y,p.z);
        }
      }
    }
  });
}
function circlePoints(radius = 1, n = 192, lobes = 0, depth = 0) {
  return Array.from({
    length: n
  }, (_, i) => {
    const a = i / n * Math.PI * 2,
      r = radius + Math.cos(a * lobes) * depth;
    return new T.Vector2(Math.cos(a) * r, Math.sin(a) * r);
  });
}
function regular(n, r = 1, rotation = 0) {
  return Array.from({
    length: n
  }, (_, i) => new T.Vector2(Math.cos(i / n * Math.PI * 2 + rotation) * r, Math.sin(i / n * Math.PI * 2 + rotation) * r));
}
function smoothPolygon(points, cut = .15) {
  const s = new T.Shape();
  const n = points.length;
  for (let i = 0; i < n; i++) {
    const a = points[(i + n - 1) % n],
      b = points[i],
      c = points[(i + 1) % n];
    const start = b.clone().lerp(a, cut),
      end = b.clone().lerp(c, cut);
    if (i === 0) s.moveTo(start.x, start.y);else s.lineTo(start.x, start.y);
    s.quadraticCurveTo(b.x, b.y, end.x, end.y);
  }
  s.closePath();
  return shapePoints(s);
}
function heartPoints() {
  const s = new T.Shape();
  s.moveTo(-.07, .60);
  s.bezierCurveTo(-.49, 1.02, -1.10, .56, -.86, -.03);
  s.bezierCurveTo(-.66, -.38, -.20, -.75, -.06, -.89);
  s.quadraticCurveTo(0, -.96, .06, -.89);
  s.bezierCurveTo(.20, -.75, .66, -.38, .86, -.03);
  s.bezierCurveTo(1.10, .56, .49, 1.02, .07, .60);
  s.quadraticCurveTo(0, .51, -.07, .60);
  return shapePoints(s, 192);
}
export function drawMemory() {
  const c = document.createElement('canvas');
  c.width = c.height = 1024;
  const x = c.getContext('2d');
  const sky = x.createLinearGradient(0, 0, 0, 700);
  sky.addColorStop(0, '#344c78');
  sky.addColorStop(.45, '#b0bcd0');
  sky.addColorStop(.72, '#ecc297');
  sky.addColorStop(1, '#d8a888');
  x.fillStyle = sky;
  x.fillRect(0, 0, 1024, 1024);
  x.save();
  x.filter = 'blur(19px)';
  x.fillStyle = '#f6daba';
  x.beginPath();
  x.arc(405, 368, 52, 0, Math.PI * 2);
  x.fill();
  x.restore();
  x.fillStyle = '#ffedcc';
  x.beginPath();
  x.arc(405, 368, 22, 0, Math.PI * 2);
  x.fill();
  const layers = [{
    c: '#8194ad',
    p: [[0, 520], [90, 352], [164, 419], [256, 255], [355, 413], [485, 500], [603, 311], [724, 371], [844, 250], [973, 445], [1024, 421]]
  }, {
    c: '#556e8b',
    p: [[0, 544], [97, 475], [187, 510], [303, 368], [416, 505], [542, 428], [649, 480], [765, 345], [937, 510], [1024, 435]]
  }, {
    c: '#304b65',
    p: [[0, 590], [119, 548], [189, 568], [291, 489], [352, 510], [446, 568], [611, 529], [739, 464], [871, 503], [1024, 573]]
  }];
  for (const layer of layers) {
    x.fillStyle = layer.c;
    x.beginPath();
    x.moveTo(0, 675);
    layer.p.forEach(p => x.lineTo(...p));
    x.lineTo(1024, 675);
    x.fill();
  }
  const water = x.createLinearGradient(0, 590, 0, 1024);
  water.addColorStop(0, '#9ba4aa');
  water.addColorStop(.35, '#586e80');
  water.addColorStop(1, '#193a53');
  x.fillStyle = water;
  x.fillRect(0, 600, 1024, 424);
  const rand = random(938);
  for (let i = 0; i < 220; i++) {
    const y = 604 + rand() * 420;
    const half = 20 + (y - 600) * .31;
    x.strokeStyle = `rgba(237,205,158,${.06 + rand() * .22})`;
    x.lineWidth = .5 + rand() * 2;
    x.beginPath();
    x.moveTo(405 + (rand() - .5) * half * 2, y);
    x.lineTo(405 + (rand() - .5) * half * 2, y);
    x.stroke();
  }
  for (let side of [-1, 1]) for (let i = 0; i < 14; i++) {
    const xx = side < 0 ? i * 15 : 1024 - i * 15;
    const h = 110 + rand() * 150,
      base = 790 + rand() * 220;
    x.fillStyle = i % 2 ? '#1b3543' : '#203b48';
    x.beginPath();
    x.moveTo(xx, base - h);
    x.lineTo(xx - 30, base);
    x.lineTo(xx + 30, base);
    x.fill();
  }
  const texture = new T.CanvasTexture(c);
  texture.colorSpace = T.SRGBColorSpace;
  return texture;
}
export function buildBadge(id, m, font, photoTexture, study = null) {
  let group;
  const data = BADGES.find(b => b.id === id);
  if (id === 'returning' && (!study || study === 'curved')) {
    const r = .74, half = .135, start = 50*Math.PI/180, end = 330*Math.PI/180;
    const band = [];
    for (let i=0;i<=160;i++) { const a=start+(end-start)*i/160; band.push(new T.Vector2(Math.cos(a)*(r+half),Math.sin(a)*(r+half))); }
    for (let i=160;i>=0;i--) { const a=start+(end-start)*i/160; band.push(new T.Vector2(Math.cos(a)*(r-half),Math.sin(a)*(r-half))); }
    const c = new T.Vector2(Math.cos(end)*r,Math.sin(end)*r);
    const tangent = new T.Vector2(-Math.sin(end),Math.cos(end)), radial = new T.Vector2(Math.cos(end),Math.sin(end));
    const head = [c.clone().addScaledVector(tangent,.41), c.clone().addScaledVector(tangent,-.085).addScaledVector(radial,.30), c.clone().addScaledVector(tangent,-.085).addScaledVector(radial,-.30)];
    const tail = circlePoints(half,64).map(p=>p.add(new T.Vector2(Math.cos(start)*r,Math.sin(start)*r)));
    const united = unionOutline([band,head.reverse(),tail],260);
    const outline = inset(inset(united,.045),-.045);
    group = castMedal(outline, '#b77c29', m, font, { crown:.024 });
  } else if (id === 'returning' || id === 'ribbon') {
    group=buildFormStudy(id,study || (id==='ribbon'?'folded':'curved'),m,font,{part,text,tube,bendAssembly});
  } else if (id === 'stopwatch') {
    group = new T.Group();
    const body = lathe([[.001, -.13], [.88, -.13], [.95, -.12], [.989, -.078], [1, -.025], [1, .045], [.99, .08], [.966, .105], [.93, .111], [.912, .09], [.912, -.08], [.001, -.08]], m.satin);
    part(group, body, 'Lathed titanium case');
    const bezel = lathe([[.905, .082], [.985, .082], [.992, .096], [.969, .123], [.932, .134], [.909, .115], [.905, .082]], m.satin);
    part(group, bezel, 'Polished bezel', [0, 0, .76]);
    const face = new T.Group();
    const dialMaterial=m.enamel('#123766').clone();dialMaterial.userData.studioRole='dial';
    dialMaterial.normalMap=m.dialNormal;dialMaterial.metalness=.20;
    const dial=lathe([[.001,.057],[.90,.057],[.906,.065],[.9,.083],[.001,.083]],dialMaterial);
    dial.updateMatrix();dial.geometry.applyMatrix4(dial.matrix);dial.rotation.set(0,0,0);
    const dp=dial.geometry.attributes.position,duv=dial.geometry.attributes.uv;
    for(let i=0;i<dp.count;i++)duv.setXY(i,dp.getX(i)/1.82+.5,dp.getY(i)/1.82+.5);
    face.add(dial);
    face.add(ring(.965,.0035,.126,m.polished));
    face.add(ring(.887, .006, .093, m.polished));
    face.add(ring(.726, .0025, .086, m.ink));
    for (let i = 0; i < 60; i++) {
      const major = i % 5 === 0;
      const tick = mesh(new T.CapsuleGeometry(major ? .0065 : .0035,major ? .067 : .033,4,8),major ? m.lettering : m.satin);
      tick.scale.z=.42;
      const a = i / 60 * Math.PI * 2;
      tick.position.set(Math.sin(a) * (major ? .801 : .821), Math.cos(a) * (major ? .801 : .821), .089);
      tick.rotation.z = -a;
      face.add(tick);
    }
    face.add(text(font, '5K', .50, .012, m.lettering, 0, .07, .087));
    const run = runner(m.lettering, .38);
    run.position.set(.02, -.39, .10);
    face.add(run);
    part(group, face, 'Blue enamel dial and chapter ring', [0, 0, .33]);
    const crown = new T.Group();
    crown.add(lathe([[.04, 0], [.062, .015], [.062, .13], [.04, .14]], m.satin, 'y', 64));
    const cap = lathe([[.09, .11], [.115, .13], [.117, .25], [.102, .273], [.071, .285], [.001, .288]], m.satin, 'y', 96);
    crown.add(cap);
    for (let i = 0; i < 32; i++) {
      const a = i / 32 * Math.PI * 2;
      const flute = mesh(new T.CylinderGeometry(.006, .006, .112, 6), m.polished);
      flute.position.set(Math.cos(a) * .116, .19, Math.sin(a) * .116);
      crown.add(flute);
    }
    crown.position.y = .972;
    part(group, crown, '32-flute crown', [0, .60, 0]);
    part(group, lathe([[.001, -.145], [.82, -.145], [.89, -.137], [.927, -.12]], m.satin), 'Fitted reverse cap', [0, 0, -.40]);
  } else if (id === 'hourglass') {
    group = new T.Group();
    const profile = [];
    for (let i = 0; i <= 80; i++) {
      const y = -.87 + i / 80 * 1.74;
      const t = Math.abs(y) / .87;
      const r = .048 + .667 * Math.pow(Math.sin(t * Math.PI * .65), 1.18);
      profile.push([r, y]);
    }
    const glass = lathe(profile, m.glass, 'y', 128);
    glass.scale.z = .29;
    glass.castShadow = false;
    part(group, glass, 'Continuous glass chambers', [0, 0, .65]);
    for (const side of [-1, 1]) {
      const cap = lathe([[.001, -.07], [.69, -.07], [.755, -.055], [.787, -.02], [.787, .04], [.755, .067], [.001, .067]], m.satin, 'y', 128);
      cap.position.y = side * .91;
      cap.scale.z = .35;
      part(group, cap, side > 0 ? 'Upper cap' : 'Lower cap', [0, side * .55, 0]);
      const lip = lathe([[.723, -.017], [.78, -.011], [.789, 0], [.78, .015]], m.polished, 'y', 128);
      lip.position.y = side * .853;
      lip.scale.z = .35;
      part(group, lip, 'Polished glass seat', [0, side * .43, 0]);
    }
    for (const side of [-1, 1]) {
      const rail = tube(profile.filter((_, i) => i % 4 === 0).map(([r, y]) => [side * (r + .045), y, -.005]), .042, m.satin, 100);
      rail.scale.z = .72;
      part(group, rail, 'Curved frame shoulder', [side * .48, 0, 0]);
    }
    const lower = lathe([[.001, 0], [.60, 0], [.655, .042], [.59, .07], [.45, .115], [.30, .195], [.15, .29], [.001, .39]], m.sand, 'y', 96);
    lower.scale.z = .27;
    lower.position.y = -.822;
    group.add(lower);
    const upper = lathe([[.025, 0], [.07, .09], [.18, .24], [.36, .43], [.52, .58], [.53, .60], [.001, .60]], m.sand, 'y', 96);
    upper.scale.z = .27;
    upper.position.y = .035;
    group.add(upper);
    const rng = random(47),
      positions = [];
    for (let i = 0; i < 100; i++) positions.push((rng() - .5) * .015, .02 - rng() * .41, (rng() - .5) * .014);
    const pg = new T.BufferGeometry();
    pg.setAttribute('position', new T.Float32BufferAttribute(positions, 3));
    const particles = new T.Points(pg, new T.PointsMaterial({
      color: 0xe9cc90,
      size: .008,
      sizeAttenuation: true
    }));
    group.add(particles);
    group.userData.sand = {
      upper,
      lower,
      particles
    };
    const inscription = new T.Group();
    inscription.position.set(0, -.918, .266);
    inscription.add(text(font, '1:00:00', .072, .002, m.ink));
    part(group, inscription, 'Cap inscription', [0, -.55, 0]);
  } else if (id === 'memory') {
    group = new T.Group();
    const pts = heartPoints();
    part(group, extruded(inset(pts, .050), .16, .032, m.satin, -.12), 'Satin heart shell');
    part(group, dome(inset(pts, .005), -.139, -.055, m.satin, null, true), 'Domed reverse', [0, 0, -.45]);
    part(group, contourRing(pts, .09, [[.019, .067], [.001, .100], [.017, .12], [.047, .13], [.083, .105]], m.polished), 'Polished window lip', [0, 0, .77]);
    part(group, contourRing(inset(pts, .09), .028, [[0, .095], [.006, .105], [.026, .101], [.036, .093]], m.enamel('#174973')), 'Blue enamel gasket', [0, 0, .5]);
    const photoMat = new T.MeshStandardMaterial({
      map: photoTexture,
      roughness: .8,
      metalness: 0,
      color: 0xffffff
    });
    const photo = dome(inset(pts, .128), .103, .012, photoMat);
    photo.castShadow = false;
    group.userData.photoMaterial = photoMat;
    part(group, photo, 'Recessed photograph', [0, 0, .21]);
    const glassMat = m.glass.clone();
    glassMat.attenuationColor.set(0xffffff);
    glassMat.attenuationDistance = 10;
    glassMat.thickness = .045;
    glassMat.roughness = .055;
    const lens = dome(inset(pts, .115), .122, .045, glassMat);
    lens.castShadow = false;
    part(group, lens, 'Curved protective lens', [0, 0, 1.05]);
  } else if (id === 'energy') {
    const s = new T.Shape();
    s.moveTo(0, -1);
    s.bezierCurveTo(-1.14, -.61, -.90, .10, -.48, .42);
    s.bezierCurveTo(-.16, .70, .05, .91, .11, 1.13);
    s.bezierCurveTo(.43, .84, .38, .45, .31, .26);
    s.bezierCurveTo(.52, .37, .66, .52, .63, .68);
    s.bezierCurveTo(1.04, .09, 1.03, -.64, 0, -1);
    group = castMedal(shapePoints(s,260), '#bc3024', m, font, { crown:.072 });
    const run = runner(m.lettering, .4);
    run.position.set(-.19, -.3, .21);
    group.userData.face.add(run);
  } else if (id === 'distance') {
    group = medal(smoothPolygon(regular(6, 1.06, Math.PI / 6), .07), '#137d9e', m, font, {
      label: '12.4',
      sub: 'KM',
      back: 'FARTHEST',
      rise: .055
    });
    const run = runner(m.lettering, .32);
    run.position.set(.02, .5, .13);
    group.userData.face.add(run);
  } else if (id === 'sunrise') {
    const s = new T.Shape();
    s.moveTo(-.76, -.35);
    s.absarc(0, -.35, .76, Math.PI, 0, true);
    s.lineTo(-.76, -.35);
    group = medal(shapePoints(s), '#d69732', m, font, {
      back: 'FIRST WORKOUT',
      rise: .055
    });
    // A sun-centered cap avoids the triangular lighting crease produced by a
    // radial fan centered above the semicircle's flat horizon.
    const sunRadius=.683;
    const sunHeight=(x,y)=>.080+.045*(1-(x*x+(y+.35)**2)/(sunRadius*sunRadius));
    const sunGeometry=group.userData.face.children[0].geometry;
    const sunPositions=sunGeometry.attributes.position,sunNormals=sunGeometry.attributes.normal;
    for(let i=0;i<sunPositions.count;i++) {
      const x=sunPositions.getX(i),y=sunPositions.getY(i);
      sunPositions.setZ(i,sunHeight(x,y));
      const n=new T.Vector3(.090*x/(sunRadius*sunRadius),.090*(y+.35)/(sunRadius*sunRadius),1).normalize();
      sunNormals.setXYZ(i,n.x,n.y,n.z);
    }
    group.userData.faceHeight=sunHeight;
    for (let i = 0; i < 5; i++) {
      const a = (i + 1) / 6 * Math.PI;
      const ray = mesh(new T.CapsuleGeometry(.071, .28, 5, 12), m.polished);
      ray.position.set(Math.cos(a) * .99, Math.sin(a) * .99 - .35, .018);
      ray.rotation.z = a - Math.PI / 2;
      part(group, ray, 'Dawn ray', [Math.cos(a) * .22, Math.sin(a) * .22, .2]);
    }
    const horizon = extruded(smoothPolygon([new T.Vector2(-.94, -.32), new T.Vector2(.94, -.32), new T.Vector2(.84, -.49), new T.Vector2(-.84, -.49)], .16), .16, .03, m.satin, -.065);
    part(group, horizon, 'Raised horizon', [0, -.30, .20]);
    const run = runner(m.lettering, .43);
    run.position.set(0, -.03, .14);
    group.userData.face.add(run);
  } else if (id === 'pennant') {
    const points = [[-.66, .96], [.66, .96], [.62, -.42], [0, -.94], [-.62, -.42]];
    group = medal(smoothPolygon(points.map(p => new T.Vector2(...p)), .065), '#218d72', m, font, {
      label: '5K',
      sub: 'FIRST',
      back: 'FIRST DISTANCE',
      rise: .035
    });
    group.userData.warp=(_,y)=>.05*Math.tanh((y+.38)*12);
    const seam = tube([[-.46, .78, .16], [0, .80, .18], [.46, .78, .16]], .009, m.polished, 50);
    group.userData.face.add(seam);
  } else if (id === 'year') {
    const n = id === 'week' ? 7 : 12;
    const pts = circlePoints(.90, 240, n, id === 'week' ? .105 : .047);
    group = medal(pts, id === 'week' ? '#18784e' : '#819947', m, font, {
      label: id === 'year' ? '2026' : '7',
      sub: id === 'week' ? 'ACTIVE DAYS' : 'ONE YEAR',
      back: id === 'week' ? 'PERFECT WEEK' : 'ACTIVE YEAR',
      rise: .035
    });
    for (let i = 0; i < n; i++) {
      const a = i / n * Math.PI * 2 + Math.PI / 2;
      const marker = mesh(new T.SphereGeometry(id === 'week' ? .060 : .020, 16, 12), id === 'week' ? m.enamel('#38b675') : m.polished);
      marker.scale.set(1, id === 'week' ? 1.65 : 1, .32);
      marker.position.set(Math.cos(a) * .715, Math.sin(a) * .715, .105);
      marker.rotation.z = a - Math.PI / 2;
      group.userData.face.add(marker);
    }
  } else if (id === 'month' || id === 'week') {
    group = medal(smoothPolygon([[-.78, .90], [.78, .90], [.72, -.73], [-.77, -.88]].map(p => new T.Vector2(...p)), .12), id === 'week' ? '#18784e' : '#255f83', m, font, {
      back: id === 'week' ? 'PERFECT WEEK' : 'PERFECT MONTH',
      rise: .045
    });
    group.userData.face.add(text(font, id === 'week' ? '7' : 'JUL 2026', id === 'week' ? .40 : .145, .005, m.lettering, 0, id === 'week' ? .18 : .57, .13));
    if (id === 'week') group.userData.face.add(text(font, 'ACTIVE DAYS', .085, .005, m.lettering, 0, -.15, .13));
    for (let day = 1; day <= (id === 'week' ? 7 : 31); day++) {
      const cell = id === 'week' ? day - 1 : day + 1,
        col = cell % 7,
        row = Math.floor(cell / 7);
      const dot = mesh(new T.CylinderGeometry(.029, .029, .013, 16), m.polished);
      dot.userData.fixtureInscription = true;
      dot.rotation.x = Math.PI / 2;
      dot.position.set((col - 3) * .17, (id === 'week' ? -.43 : .29) - row * .17, .131);
      group.userData.face.add(dot);
    }
    const seam = tube([[-.60, .77, .13], [0, .79, .17], [.60, .77, .13]], .025, m.satin, 50);
    group.userData.face.add(seam);
  } else if (id === 'halfYear') {
    group = castMedal(circlePoints(.88,264,6,.063), '#884b87', m, font, {label:'6',sub:'MONTHS',crown:.05});
    for(let i=0;i<6;i++) {
      const a=Math.PI/2+i*Math.PI/3;
      const marker=mesh(new T.SphereGeometry(.026,20,12),m.polished);
      marker.scale.z=.32; marker.position.set(Math.cos(a)*.68,Math.sin(a)*.68,.115);
      group.userData.face.add(marker);
    }
  } else if (id === 'activity') {
    const s=new T.Shape();
    s.moveTo(-.66,-.29);s.lineTo(-.66,.29);
    s.absarc(0,.29,.66,Math.PI,0,true);s.lineTo(.66,-.29);
    s.absarc(0,-.29,.66,0,-Math.PI,true);s.closePath();
    group = castMedal(shapePoints(s,240), '#248894', m, font, { label:'12', sub:'WEEKS', crown:.045 });
    const run = runner(m.lettering, .43);
    run.position.set(0,.58,.115);
    group.userData.face.add(run);
  } else if (id === 'frequency') {
    group = medal(smoothPolygon([[-.61, .84], [.61, .84], [.84, .08], [.49, -.83], [-.49, -.83], [-.84, .08]].map(p => new T.Vector2(...p)), .18), '#247f87', m, font, {
      label: '3+',
      sub: 'DAYS / WEEK',
      back: 'RUN RHYTHM',
      rise: .045
    });
    for (let i = 0; i < 3; i++) group.userData.face.add(tube([[-.22 + i * .22, -.54, .135], [-.22 + i * .22, -.47, .138]], .015, m.polished, 6));
  } else if (id === 'collection') {
    group = new T.Group();
    const pts = smoothPolygon([[-.67, .7], [.67, .7], [.73, -.1], [.43, -.67], [0, -.85], [-.43, -.67], [-.73, -.1]].map(p => new T.Vector2(...p)), .18);
    for (let i = 0; i < 2; i++) {
      const crest = medal(pts, i === 0 ? '#717341' : '#a69a50', m, font, {
        label: i === 1 ? '2' : '',
        sub: i === 1 ? 'MILESTONES' : '',
        back: i===0?'RHYTHMS KEPT':null,
        rise: .035
      });
      crest.position.set(i === 0 ? -.13 : .10, i === 0 ? .17 : -.07, i * .21);
      part(group, crest, 'Collected crest ' + (i + 1), [(i - .5) * .37, (.5 - i) * .24, i * .30]);
    }
  }
  seatFaceDetails(group);
  group.traverse(node=>{if(node.userData.warp)bendAssembly(node,node.userData.warp);});
  if (id === 'returning') {
    const activity = runner(m.satin,.80);
    activity.position.set(.056,-.035,.14);
    part(group,activity,'Workout symbol');
  }
  addReverseLogo(group,id,m.ink,tessellateCaps);
  group.name = id;
  group.userData.badgeId = id;
  group.userData.meta = group.userData.formDescription ? {...data,description:group.userData.formDescription,geometry:'A continuous indexed shell with a rounded section, real reverse and shaped end caps. Its material and clay views use the same geometry.'} : data;
  group.traverse(o => {
    if (o.isMesh || o.isPoints) {
      o.userData.originalMaterial = o.material;
    }
  });
  return group;
}
export function applyExplode(group, value) {
  group.traverse(o => {
    if (o.userData.rest && o.userData.explode) o.position.copy(o.userData.rest).addScaledVector(o.userData.explode, value);
  });
}
export function applyFinish(group, finish, m, wireframe) {
  group.traverse(o => {
    if (!o.isMesh) return;
    const original = o.userData.originalMaterial;
    if (!original) return;
    o.material = finish === 'clay' ? m.clay : finish === 'satin' ? m.satin : original;
    for (const mat of Array.isArray(o.material) ? o.material : [o.material]) mat.wireframe = wireframe;
  });
}
export function updateSand(group, progress, active) {
  const s = group.userData.sand;
  if (!s) return;
  const shrink = 1 - progress * .38;
  s.upper.scale.set(shrink, shrink, .27 * shrink);
  s.lower.scale.y = .70 + progress * .30;
  s.particles.visible = active;
  if (active) {
    const p = s.particles.geometry.attributes.position;
    for (let i = 0; i < p.count; i++) p.setY(i, .02 - (i / 100 + progress * 5) % 1 * .43);
    p.needsUpdate = true;
  }
}
