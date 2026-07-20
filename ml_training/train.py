# train.py
# Trains a tiny neural net: 8 inputs -> 6 hidden (ReLU) -> 1 output (sigmoid)
# Output is scaled to 0.4-1.6 difficulty modifier
#
# Usage: python train.py
# Outputs: ../models/adaptive_weights.json

import json
import math
import random

random.seed(42)

# ─── ACTIVATION FUNCTIONS ────────────────────────────────
def sigmoid(x):
    return 1.0 / (1.0 + math.exp(-x))

def relu(x):
    return max(0.0, x)

# ─── FORWARD PASS ────────────────────────────────────────
def forward(X, W1, b1, W2, b2):
    # X: 8 features (list of 8 floats)
    # Returns: (hidden_pre, hidden, output)
    z1 = [sum(W1[i][j] * X[j] for j in range(8)) + b1[i] for i in range(6)]
    h  = [relu(v) for v in z1]
    z2 = sum(W2[0][j] * h[j] for j in range(6)) + b2[0]
    out = sigmoid(z2)
    return z1, h, out

# ─── GENERATE SYNTHETIC TRAINING DATA ───────────────────
def generate_data(count=8000):
    data = []
    for _ in range(count):
        # 8 features, each 0-1 representing player progress/skill
        f = [random.random() for _ in range(8)]

        # Estimate overall skill from features
        # Higher mastered/levels/stars/unlocked -> higher skill
        skill = (
            f[0] * 0.20 +   # topics mastered ratio
            (1 - f[1]) * 0.15 +  # topics struggling (inverted)
            f[2] * 0.15 +   # levels completed
            f[3] * 0.15 +   # average stars
            f[4] * 0.10 +   # level stars for current level
            f[5] * 0.10 +   # unlocked towers ratio
            f[6] * 0.08 +   # max level unlocked
            f[7] * 0.07     # waves completed
        )

        # Add some noise so it's not perfectly linear
        noise = random.gauss(0, 0.08)
        target = min(0.95, max(0.05, skill + noise))

        data.append((f, target))
    return data

# ─── INIT WEIGHTS ────────────────────────────────────────
W1 = [[random.uniform(-0.5, 0.5) for _ in range(8)] for _ in range(6)]
b1 = [0.0] * 6
W2 = [[random.uniform(-0.5, 0.5) for _ in range(6)]]
b2 = [0.0]

# ─── TRAINING ────────────────────────────────────────────
data = generate_data()
lr = 0.02

print("Training...")
for epoch in range(300):
    random.shuffle(data)
    total_loss = 0.0

    for X, y_true in data:
        # Forward
        z1, h, out = forward(X, W1, b1, W2, b2)

        # MSE loss
        diff = out - y_true
        total_loss += diff * diff

        # Backprop
        d_out = 2.0 * diff
        d_z2 = d_out * out * (1.0 - out)

        # Output layer gradients
        d_W2 = [[d_z2 * h[j] for j in range(6)]]
        d_b2 = [d_z2]

        # Hidden layer gradients
        d_h = [d_z2 * W2[0][j] for j in range(6)]
        d_z1 = [d_h[i] if z1[i] > 0 else 0.0 for i in range(6)]

        d_W1 = [[d_z1[i] * X[j] for j in range(8)] for i in range(6)]
        d_b1 = d_z1[:]

        # Update weights
        for i in range(6):
            b1[i] -= lr * d_b1[i]
            for j in range(8):
                W1[i][j] -= lr * d_W1[i][j]
        for j in range(6):
            W2[0][j] -= lr * d_W2[0][j]
        b2[0] -= lr * d_b2[0]

    if epoch % 50 == 0:
        print(f"  Epoch {epoch}, Loss: {total_loss / len(data):.6f}")

print(f"\nFinal loss: {total_loss / len(data):.6f}")

# ─── EXPORT ──────────────────────────────────────────────
model = {
    "W1": W1,
    "b1": b1,
    "W2": W2,
    "b2": b2,
}

import os
out_dir = os.path.join(os.path.dirname(__file__), "..", "models")
os.makedirs(out_dir, exist_ok=True)
out_path = os.path.join(out_dir, "adaptive_weights.json")
with open(out_path, "w") as f:
    json.dump(model, f)
print(f"Model saved to {out_path}")
