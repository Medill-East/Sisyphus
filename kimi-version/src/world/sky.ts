import * as THREE from 'three'

/** Gradient sky dome with a sun disc and soft clouds, plus matched fog. */
export class Sky {
  readonly mesh: THREE.Mesh
  private readonly topDay = new THREE.Color(0x6f9fd0)
  private readonly bottomDay = new THREE.Color(0xe8e2d2)
  private readonly topWarm = new THREE.Color(0x8a7ab0)
  private readonly bottomWarm = new THREE.Color(0xf5c57e)
  private readonly mat: THREE.ShaderMaterial

  constructor(private readonly scene: THREE.Scene) {
    this.mat = new THREE.ShaderMaterial({
      side: THREE.BackSide,
      depthWrite: false,
      uniforms: {
        top: { value: this.topDay.clone() },
        bottom: { value: this.bottomDay.clone() },
        sunDir: { value: new THREE.Vector3(0.45, 0.5, 0.35).normalize() },
        sunColor: { value: new THREE.Color(0xfff3d0) },
      },
      vertexShader: `varying vec3 vP; void main(){ vP = position; gl_Position = projectionMatrix * modelViewMatrix * vec4(position,1.0); }`,
      fragmentShader: `
        uniform vec3 top; uniform vec3 bottom; uniform vec3 sunDir; uniform vec3 sunColor;
        varying vec3 vP;
        void main(){
          vec3 d = normalize(vP);
          float t = clamp(d.y * 0.5 + 0.5, 0.0, 1.0);
          vec3 col = mix(bottom, top, t);
          float s = max(dot(d, sunDir), 0.0);
          col += sunColor * (pow(s, 600.0) * 1.2 + pow(s, 24.0) * 0.22); // disc + halo
          // two soft cloud bands
          float cl = sin(d.x * 9.0 + d.y * 22.0) * sin(d.z * 7.0 - d.y * 18.0);
          float band = smoothstep(0.05, 0.25, d.y) * smoothstep(0.75, 0.45, d.y);
          col = mix(col, vec3(0.96, 0.95, 0.94), smoothstep(0.55, 0.9, cl) * band * 0.35);
          gl_FragColor = vec4(col, 1.0);
        }`,
    })
    this.mesh = new THREE.Mesh(new THREE.SphereGeometry(900, 32, 16), this.mat)
    scene.add(this.mesh)
    scene.fog = new THREE.Fog(this.bottomDay.clone(), 70, 900)
  }

  /** t = 0 day → 1 golden-hour descent. */
  setWarmth(t: number): void {
    ;(this.mat.uniforms.top.value as THREE.Color).copy(this.topDay).lerp(this.topWarm, t)
    ;(this.mat.uniforms.bottom.value as THREE.Color).copy(this.bottomDay).lerp(this.bottomWarm, t)
    if (this.scene.fog) (this.scene.fog as THREE.Fog).color.copy(this.mat.uniforms.bottom.value as THREE.Color)
  }
}
