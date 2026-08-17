import * as THREE from 'three'

/** Gradient sky dome + matched fog. Warmth shifts both for the descent beat. */
export class Sky {
  readonly mesh: THREE.Mesh
  private readonly topDay = new THREE.Color(0x7fa8c9)
  private readonly bottomDay = new THREE.Color(0xd8e4ea)
  private readonly topWarm = new THREE.Color(0x9a86b8)
  private readonly bottomWarm = new THREE.Color(0xf2c98a)
  private readonly mat: THREE.ShaderMaterial

  constructor(private readonly scene: THREE.Scene) {
    this.mat = new THREE.ShaderMaterial({
      side: THREE.BackSide,
      depthWrite: false,
      uniforms: {
        top: { value: this.topDay.clone() },
        bottom: { value: this.bottomDay.clone() },
      },
      vertexShader: `varying vec3 vP; void main(){ vP = position; gl_Position = projectionMatrix * modelViewMatrix * vec4(position,1.0); }`,
      fragmentShader: `uniform vec3 top; uniform vec3 bottom; varying vec3 vP;
        void main(){ float t = clamp(normalize(vP).y * 0.5 + 0.5, 0.0, 1.0); gl_FragColor = vec4(mix(bottom, top, t), 1.0); }`,
    })
    this.mesh = new THREE.Mesh(new THREE.SphereGeometry(600, 24, 12), this.mat)
    scene.add(this.mesh)
    scene.fog = new THREE.Fog(this.bottomDay.clone(), 60, 420)
  }

  /** t = 0 day → 1 golden-hour descent. */
  setWarmth(t: number): void {
    ;(this.mat.uniforms.top.value as THREE.Color).copy(this.topDay).lerp(this.topWarm, t)
    ;(this.mat.uniforms.bottom.value as THREE.Color).copy(this.bottomDay).lerp(this.bottomWarm, t)
    if (this.scene.fog) (this.scene.fog as THREE.Fog).color.copy(this.mat.uniforms.bottom.value as THREE.Color)
  }
}
