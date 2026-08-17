import * as THREE from 'three'

const renderer = new THREE.WebGLRenderer({ antialias: true })
renderer.setSize(window.innerWidth, window.innerHeight)
document.body.appendChild(renderer.domElement)
const scene = new THREE.Scene()
const camera = new THREE.PerspectiveCamera(62, innerWidth / innerHeight, 0.1, 400)
camera.position.set(0, 2, 5)
scene.add(new THREE.Mesh(new THREE.BoxGeometry(), new THREE.MeshNormalMaterial()))
renderer.render(scene, camera)
;(window as unknown as { __smoke: boolean }).__smoke = true
