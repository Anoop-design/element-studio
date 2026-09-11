import * as T from 'three';

// Exact onboarding SVG paths from Daywake/Assets.xcassets, 600 × 600.
// The cage rises by 5.5% exactly as in DaywakeIconMark.
const brandLayers=[{"path":"M134.108 548.382C122.3 563.107 100.627 565.597 87.3343 552.196C59.8103 524.449 37.8718 491.527 22.8533 455.21C3.46797 408.332 -3.7598 357.317 1.84094 306.899C7.44167 256.482 25.6894 208.296 54.8901 166.816C84.0908 125.336 123.298 91.9052 168.872 69.6277C214.446 47.3502 264.91 36.9478 315.579 39.3862C366.248 41.8246 415.48 57.0247 458.704 83.5756C501.929 110.127 537.745 147.167 562.827 191.26C582.26 225.42 594.762 262.955 599.749 301.718C602.158 320.439 586.88 336.011 568.007 336.284C549.134 336.557 533.869 321.394 530.838 302.764C526.406 275.526 517.15 249.201 503.415 225.057C484.027 190.974 456.341 162.341 422.929 141.818C389.517 121.294 351.461 109.544 312.294 107.66C273.127 105.775 234.118 113.816 198.89 131.036C163.661 148.256 133.354 174.098 110.782 206.162C88.2101 238.226 74.1047 275.473 69.7754 314.446C65.446 353.418 71.0331 392.853 86.0178 429.089C96.6328 454.758 111.72 478.233 130.49 498.462C143.329 512.297 145.917 533.657 134.108 548.382Z","cage":true},{"path":"M300.138 41.272C465.779 41.272 600 175.769 600 341.41C600 421.061 569.132 493.546 517.317 548.116C503.813 562.723 480.661 561.621 467.432 548.667C454.203 535.438 457.235 513.39 471.015 497.129C508.222 456.339 530.822 401.217 530.822 341.134C530.822 212.701 428.571 109.899 300.138 109.899C171.704 109.899 69.4534 212.701 69.4534 341.134C69.4534 401.217 92.0533 456.339 128.985 497.129C143.041 513.39 146.073 535.438 132.843 548.667C119.339 561.621 96.463 562.723 82.9582 548.116C30.8682 493.546 0 421.061 0 341.41C0 175.769 134.497 41.272 300.138 41.272Z","cage":true},{"path":"M299.854 210.791C287.842 189.111 265.869 171.826 235.986 171.826C191.748 171.826 158.057 205.811 158.057 254.736C158.057 333.545 245.947 397.412 284.619 421.436L284.717 421.493C289.684 424.415 296.074 428.174 300.439 428.174C304.834 428.174 310.693 424.365 315.381 421.436C354.053 397.119 441.943 333.545 441.943 254.736C441.943 205.811 408.252 171.826 364.014 171.826C334.424 171.826 312.158 189.111 299.854 210.791Z","cage":false}];

function shapeFromPath(path, side, rise) {
  const tokens=path.match(/[A-Za-z]|[-+]?(?:\d*\.)?\d+(?:[eE][-+]?\d+)?/g);
  const shape=new T.Shape();let i=0;
  const x=()=> (Number(tokens[i++])/600-.5)*side;
  const y=()=> (.5-Number(tokens[i++])/600)*side+rise;
  while(i<tokens.length) {
    const command=tokens[i++];
    if(command==='M')shape.moveTo(x(),y());
    else if(command==='L')shape.lineTo(x(),y());
    else if(command==='C')shape.bezierCurveTo(x(),y(),x(),y(),x(),y());
    else if(command==='Z')shape.closePath();
    else throw Error('Unsupported brand path command: '+command);
  }
  return shape;
}

export function reverseLogoPlacement(id) {
  const narrow={returning:[-.47,-.60,.18],hourglass:[0,-.918,.10],halfYear:[0,-.48,.13],
    sunrise:[0,-.02,.26],activity:[0,0,.30],ribbon:[0,.10,.34],collection:[.13,.17,.34],memory:[0,-.02,.34]};
  return narrow[id] || [0,0,.38];
}

export function addReverseLogo(root,id,material,tessellate) {
  const [viewX,y,side]=reverseLogoPlacement(id),x=-viewX;
  const xmin=x-side*.6,xmax=x+side*.6,ymin=y-side*.6,ymax=y+side*.65;
  // Only query triangles underneath this part of the mark. Scanning the whole
  // surface for every duplicate extrusion vertex blocked Collection for seconds.
  const cells=32, bins=Array.from({length:cells*cells},()=>[]);
  const column=px=>Math.max(0,Math.min(cells-1,Math.floor((px-xmin)/(xmax-xmin)*cells)));
  const row=py=>Math.max(0,Math.min(cells-1,Math.floor((py-ymin)/(ymax-ymin)*cells)));
  root.updateMatrixWorld(true);
  const p=new T.Vector3();
  root.traverse(node=>{
    if(!node.isMesh)return;
    const source=node.geometry.attributes.position,indices=node.geometry.index;
    const points=Array.from({length:source.count},(_,i)=>p.fromBufferAttribute(source,i).applyMatrix4(node.matrixWorld).toArray());
    for(let i=0;i<(indices?.count??source.count);i+=3) {
      const [a,b,c]=[0,1,2].map(j=>points[indices?indices.getX(i+j):i+j]);
      if(Math.max(a[0],b[0],c[0])<xmin||Math.min(a[0],b[0],c[0])>xmax||
         Math.max(a[1],b[1],c[1])<ymin||Math.min(a[1],b[1],c[1])>ymax)continue;
      const den=(b[1]-c[1])*(a[0]-c[0])+(c[0]-b[0])*(a[1]-c[1]);
      if(Math.abs(den)<=1e-10)continue;
      const triangle={a,b,c,den};
      // Include the same barycentric edge tolerance used by height(), including
      // points just across a cell boundary. This changes lookup cost, not shape.
      const padX=.0002*(Math.max(a[0],b[0],c[0])-Math.min(a[0],b[0],c[0]));
      const padY=.0002*(Math.max(a[1],b[1],c[1])-Math.min(a[1],b[1],c[1]));
      for(let r=row(Math.min(a[1],b[1],c[1])-padY);r<=row(Math.max(a[1],b[1],c[1])+padY);r++)
        for(let c0=column(Math.min(a[0],b[0],c[0])-padX);c0<=column(Math.max(a[0],b[0],c[0])+padX);c0++)
          bins[r*cells+c0].push(triangle);
    }
  });
  const height=(x,y)=>{
    let nearest=Infinity;
    for(const {a,b,c,den} of bins[row(y)*cells+column(x)]) {
      const u=((b[1]-c[1])*(x-c[0])+(c[0]-b[0])*(y-c[1]))/den;
      const v=((c[1]-a[1])*(x-c[0])+(a[0]-c[0])*(y-c[1]))/den;
      if(u<-.0001||v<-.0001||u+v>1.0001)continue;
      nearest=Math.min(nearest,u*a[2]+v*b[2]+(1-u-v)*c[2]);
    }
    if(!Number.isFinite(nearest))throw Error(id+': hallmark must sit on solid geometry');
    return nearest;
  };
  const logo=new T.Group();logo.name='Monochrome onboarding logo';
  // Live Highlight content uses the same app assets at runtime. Omitting this
  // fixture logo from the live export prevents two coincident markings.
  logo.userData.fixtureInscription=true;
  // Unite overlapping cage arcs before extrusion, so the monochrome mark has
  // one surface rather than coincident caps that flicker under a moving light.
  const C=window.ClipperLib,scale=1e7,tree=new C.PolyTree(),clip=new C.Clipper();
  const paths=brandLayers.map(({path,cage})=>shapeFromPath(path,side,cage?side*.055:0)
    .getPoints(24).map(p=>({X:Math.round(p.x*scale),Y:Math.round(p.y*scale)})));
  for(const path of paths)if(!C.Clipper.Orientation(path))path.reverse();
  clip.AddPaths(paths,C.PolyType.ptSubject,true);
  clip.Execute(C.ClipType.ctUnion,tree,C.PolyFillType.pftNonZero,C.PolyFillType.pftNonZero);
  const contour=(node,Path)=>{
    const result=new Path(),points=node.Contour();
    points.forEach((p,i)=>i?result.lineTo(p.X/scale,p.Y/scale):result.moveTo(p.X/scale,p.Y/scale));
    result.closePath();return result;
  };
  const shapes=[];
  const visit=node=>{
    if(!node.IsHole()) {
      const shape=contour(node,T.Shape);
      shape.holes=node.Childs().filter(child=>child.IsHole()).map(child=>contour(child,T.Path));
      shapes.push(shape);
    }
    node.Childs().forEach(visit);
  };
  tree.Childs().forEach(visit);
  const samples=new Map(),normal=new T.Vector3();
  const surface=(px,py)=>{
    const key=px+':'+py;
    if(!samples.has(key)) {
      const epsilon=.0005;
      samples.set(key,{
        z:height(px,py),
        dx:(height(px+epsilon,py)-height(px-epsilon,py))/(2*epsilon),
        dy:(height(px,py+epsilon)-height(px,py-epsilon))/(2*epsilon)
      });
    }
    return samples.get(key);
  };
  for(const shape of shapes) {
    const geometry=tessellate(new T.ExtrudeGeometry(shape,
      {depth:.0015,bevelEnabled:false,curveSegments:12,steps:1}),side/28);
    geometry.rotateY(Math.PI);geometry.translate(x,y,0);
    const positions=geometry.attributes.position,normals=geometry.attributes.normal;
    for(let i=0;i<positions.count;i++) {
      const px=positions.getX(i),py=positions.getY(i),z=positions.getZ(i);
      const sample=surface(px,py);
      normal.set(normals.getX(i)-sample.dx*normals.getZ(i),normals.getY(i)-sample.dy*normals.getZ(i),normals.getZ(i)).normalize();
      normals.setXYZ(i,normal.x,normal.y,normal.z);
      positions.setZ(i,sample.z-.0015+z);
    }
    const mesh=new T.Mesh(geometry,material);mesh.castShadow=false;mesh.receiveShadow=true;
    logo.add(mesh);
  }
  root.add(logo);
}
