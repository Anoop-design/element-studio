import * as T from 'three';

const clamp = (x, a=0, b=1) => Math.max(a, Math.min(b, x));
const smooth = x => { const t=clamp(x); return t*t*(3-2*t); };
const signedPower = (x, p) => Math.sign(x)*Math.abs(x)**p;

// A periodic cross-section with shared seam vertices. Caps connect matching front
// and rear samples, retaining the bookmark's notch instead of filling it with a fan.
function shell(sample, material, sections=280, sides=48, flip=false) {
  const positions=[], uv=[], indices=[];
  for(let i=0;i<=sections;i++)for(let j=0;j<sides;j++) {
    positions.push(...sample(i/sections,j/sides*Math.PI*2).toArray());
    uv.push(i/sections,j/sides);
  }
  const add=(a,b,c)=>{
    const p=i=>new T.Vector3(...positions.slice(i*3,i*3+3));
    if(p(b).sub(p(a)).cross(p(c).sub(p(a))).lengthSq()>1e-18)indices.push(a,b,c);
  };
  for(let i=0;i<sections;i++)for(let j=0;j<sides;j++) {
    const a=i*sides+j,b=(i+1)*sides+j,c=(i+1)*sides+(j+1)%sides,d=i*sides+(j+1)%sides;
    add(a,b,d);add(b,c,d);
  }
  for(const end of [0,sections])for(let j=0;j<sides/2;j++) {
    const a=end*sides+j,b=end*sides+j+1,c=end*sides+(sides-j-1)%sides,d=end*sides+(sides-j)%sides;
    if(end===0){add(a,d,b);add(b,d,c);}else{add(a,b,d);add(b,c,d);}
  }
  if(flip)for(let i=0;i<indices.length;i+=3)[indices[i+1],indices[i+2]]=[indices[i+2],indices[i+1]];
  const g=new T.BufferGeometry();
  g.setAttribute('position',new T.Float32BufferAttribute(positions,3));
  g.setAttribute('uv',new T.Float32BufferAttribute(uv,2));
  g.setIndex(indices);g.computeVertexNormals();
  const object=new T.Mesh(g,material);object.castShadow=object.receiveShadow=true;
  return object;
}

function patch(sample, material, sections=260, across=36, flip=false) {
  const p=[],uv=[],indices=[];
  for(let i=0;i<=sections;i++)for(let j=0;j<=across;j++) {
    p.push(...sample(i/sections,j/across).toArray());uv.push(i/sections,j/across);
  }
  for(let i=0;i<sections;i++)for(let j=0;j<across;j++) {
    const a=i*(across+1)+j,b=a+across+1;
    indices.push(a,b,a+1,b,b+1,a+1);
  }
  if(flip)for(let i=0;i<indices.length;i+=3)[indices[i+1],indices[i+2]]=[indices[i+2],indices[i+1]];
  const g=new T.BufferGeometry();
  g.setAttribute('position',new T.Float32BufferAttribute(p,3));
  g.setAttribute('uv',new T.Float32BufferAttribute(uv,2));
  g.setIndex(indices);g.computeVertexNormals();
  const object=new T.Mesh(g,material);object.castShadow=object.receiveShadow=true;
  return object;
}

function ceramic(m,color) {
  const surface=m.enamel(color).clone();
  surface.userData.studioRole='ceramic';surface.roughness=.34;
  surface.clearcoat=.38;surface.clearcoatRoughness=.19;
  return surface;
}

export function buildFormStudy(id, study, m, font, h) {
  const group=new T.Group();
  const {part,text,tube,bendAssembly}=h;
  if(id==='returning') {
    const folded=study==='folded', porcelain=study==='ceramic';
    const center=t=>{
      const angle=.55+t*5.93;
      const radius=.755+.027*Math.sin(t*Math.PI*2);
      const z=folded?.16*Math.sin(t*Math.PI*2-.5):-.12+.26*smooth(t);
      return new T.Vector3(radius*Math.cos(angle),radius*Math.sin(angle),z);
    };
    const sweep=(t,phi)=>{
      const angle=.55+t*5.93, c=center(t);
      const tangent=center(clamp(t+.0001)).sub(center(clamp(t-.0001))).normalize();
      const radial=new T.Vector3(Math.cos(angle),Math.sin(angle),0);
      const forward=radial.clone().cross(tangent).normalize();
      const twist=folded?.36*Math.sin(t*Math.PI*2):.06*Math.sin(t*Math.PI*2);
      const across=radial.clone().multiplyScalar(Math.cos(twist)).addScaledVector(forward,Math.sin(twist));
      const front=forward.clone().multiplyScalar(Math.cos(twist)).addScaledVector(radial,-Math.sin(twist));
      let width=.30+.045*Math.sin(t*Math.PI);
      if(t>.69 && t<.81)width=T.MathUtils.lerp(width,.66,smooth((t-.69)/.12));
      if(t>=.81)width=.66*Math.cos(clamp((t-.81)/.19)*Math.PI/2);
      if(t<.035)width*=Math.sqrt(Math.max(.0001,1-(1-t/.035)**2));
      width=Math.max(.007,width);
      let depth=porcelain?.24:folded?.066:.16;
      depth*=Math.sqrt(Math.max(.0001,1-(1-clamp(t/.025))**2));
      depth*=Math.sqrt(Math.max(.0001,1-clamp((t-.94)/.06)**2));
      depth=Math.max(.009,depth);
      const exponent=porcelain?1:folded?.32:.62;
      c.addScaledVector(across,signedPower(Math.cos(phi),exponent)*width/2);
      c.addScaledVector(front,signedPower(Math.sin(phi),porcelain?1:.62)*depth/2);
      return c;
    };
    const material=porcelain?ceramic(m,'#d8aa67'):m.satin;
    part(group,shell(sweep,material,420,64),'Continuous rounded loop');
    if(!porcelain) {
      const face=patch((u,v)=>{
        const t=.0005+u*.999,phi=.19*Math.PI+v*.62*Math.PI;
        const p=sweep(t,phi);p.z+=.0035;return p;
      },m.enamel(folded?'#bb8235':'#b87825'));
      part(group,face,'Glazed amber along the sweep',[0,0,.32]);
    }
    group.userData.formDescription=porcelain?'A full ceramic loop with a soft oval section and a naturally widening arrowhead.':folded?'A thin amber band turns through space; its shoulders widen into the arrowhead.':'A continuous rounded casting rises from its tucked tail into a broad arrowhead. Amber glaze follows the curved band.';
  } else {
    const folded=study==='folded',porcelain=study==='ceramic';
    const start=folded?-.58:0;
    const halfDepth=folded?.029:porcelain?.115:.095;
    const width=s=>s<0?.56:.56-.12*Math.sin(s*Math.PI)+.08*s**5;
    const spine=s=>{
      if(folded && s<-.34)return new T.Vector3(0,.93+(s+.34)*.95,-.18+.02*Math.sin((s+.34)*4));
      if(folded && s<0){const a=-s/.34*Math.PI;return new T.Vector3(0,.93+.14*Math.sin(a),-.04+.14*Math.cos(a));}
      return new T.Vector3(0,.93-2.02*s,(folded?.10:.065)*Math.cos(s*Math.PI*2)+.055*s);
    };
    const ribbonPoint=(s,v,depth)=>{
      const p=spine(s),u=clamp(s);
      p.x=v*width(s);
      const notch=(Math.sqrt(v*v+.06**2)-.06)/(Math.sqrt(1+.06**2)-.06);
      // A cubic keeps longitudinal rows ordered at the notch. A high power folds
      // the final rows back over themselves and produces an extra internal V.
      p.y+=.46*Math.pow(Math.max(0,1-notch),1.65)*u**3;
      if(!folded)p.y-=.055*(1-Math.sqrt(Math.max(0,1-v*v)))*(1-u)**6;
      const roll=(folded?.09:.045)*v*v+(folded?.15:.075)*v*u**3;
      p.z+=roll;
      const tangent=spine(s+.0001).sub(spine(s-.0001)).normalize();
      const normal=tangent.clone().cross(new T.Vector3(1,0,0)).normalize();
      p.addScaledVector(normal,depth);
      return p;
    };
    const sample=(t,phi)=>{
      const s=start+t*(1-start),v=Math.cos(phi);
      return ribbonPoint(s,v,signedPower(Math.sin(phi),porcelain?.75:.24)*halfDepth);
    };
    const body=porcelain?ceramic(m,'#b8bd81'):folded?m.enamel('#7e923f'):m.satin;
    part(group,shell(sample,body,280,128,true),'Continuous folded strip');
    if(!folded && !porcelain)part(group,patch((u,v)=>{
      const p=sample(.008+u*.984,.13*Math.PI+v*.74*Math.PI);p.z+=.004;return p;
    },m.enamel('#8f9c43'),260,36,true),'Glazed front',[0,0,.30]);
    if(folded)for(const side of [-1,1]) {
      const path=Array.from({length:180},(_,i)=>ribbonPoint(start+(1-start)*i/179,side,0).toArray());
      part(group,tube(path,.0075,m.satin,280),'Fine edge binding',[side*.20,0,.12]);
    }
    const face=new T.Group();
    const ink=porcelain?m.enamel('#65713c'):ceramic(m,'#e9ecd8');
    face.add(text(font,'12',.47,.006,ink,0,.03,0));
    face.add(text(font,'ACTIVE',.072,.0015,ink,0,-.31,0));
    face.add(text(font,'WEEKS',.072,.0015,ink,0,-.425,0));
    // Solve the longitudinal position for each letter vertex so the relief follows
    // the actual skin, including the beginning of the notch and the transverse roll.
    bendAssembly(face,(x,y)=>{
      let s=clamp((.93-y)/2.02);
      for(let i=0;i<6;i++) {
        const v=clamp(x/width(s),-1,1),p=ribbonPoint(s,v,0);
        s=clamp(s+(p.y-y)/2.02);
      }
      const v=clamp(x/width(s),-.98,.98),p=ribbonPoint(s,v,0);
      const depth=halfDepth*Math.pow(Math.max(0,1-v*v),(porcelain?.75:.24)/2);
      return p.z+depth+.009;
    });
    part(group,face,'Low relief count',[0,0,.30]);
    group.userData.face=face;
    group.userData.formDescription=porcelain?'A softly rounded ceramic bookmark, with olive glaze and restrained low relief lettering.':folded?'One thin strip turns over at the top and flows into two unequal tails. A fine binding follows both edges.':'A rounded cast bookmark with a calm broad face and a slim satin edge.';
  }
  return group;
}
