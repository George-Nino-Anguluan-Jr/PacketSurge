// Script to generate adaptive_weights.json
// Run with: node ml_training/gen_weights.js

const fs = require("fs");
const path = require("path");

// Network: 8 inputs -> 6 hidden (ReLU) -> 1 output (sigmoid)

const W1 = [
  [ 1.2,  0.0,  0.0, -0.3,  0.0,  0.0,  0.0,  0.0], // mastered
  [ 0.0, -1.3,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0], // struggling (negative)
  [ 0.0,  0.0,  1.0,  0.0,  0.0,  0.0,  0.0,  0.0], // levels completed
  [ 0.0,  0.0,  0.0,  1.1,  0.0,  0.0,  0.0,  0.0], // stars
  [ 0.0,  0.0,  0.0,  0.0,  0.8,  0.0,  0.0,  0.0], // current level stars
  [ 0.0,  0.0,  0.0,  0.0,  0.0,  0.7,  0.5,  0.3], // towers + levels + waves
];

const b1 = [-0.1, 0.2, -0.1, -0.1, 0.0, -0.3];

const W2 = [[ 0.6, 0.5, 0.5, 0.5, 0.4, 0.3 ]];
const b2 = [-0.8];

const model = { W1, b1, W2, b2 };

const outDir = path.join(__dirname, "..", "models");
fs.mkdirSync(outDir, { recursive: true });
fs.writeFileSync(
  path.join(outDir, "adaptive_weights.json"),
  JSON.stringify(model)
);
console.log("Generated adaptive_weights.json with hand-tuned weights");
