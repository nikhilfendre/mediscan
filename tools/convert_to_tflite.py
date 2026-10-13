"""Convert MediScan EfficientNet-B0 best.pt -> TFLite for the Flutter app.

Input contract (matches Flutter skin_model_service.dart):
    float32 NHWC [1,224,224,3], RGB pixels in [0,1].
    ImageNet normalization is baked into the graph.
Output: float32 [1,7] class probabilities, order = labels.txt.
"""
import os
import numpy as np
import torch
import torch.nn as nn
from torchvision import models

CKPT = "/home/hatch/workspace/mediscan/checkpoints/best.pt"
OUT = "/home/hatch/workspace/mediscan_app/assets/model/skin_model.tflite"

print("loading checkpoint...")
ckpt = torch.load(CKPT, map_location="cpu")

model = models.efficientnet_b0(weights=None)
model.classifier = nn.Sequential(
    nn.Dropout(p=0.3, inplace=True),
    nn.Linear(1280, 7),
)
missing, unexpected = model.load_state_dict(ckpt["model_state_dict"], strict=False), None
print("state_dict loaded; class_codes:", ckpt["class_codes"])
model.eval()


class SkinWrapper(nn.Module):
    """NHWC [0,1] RGB in -> 7-way probabilities out."""

    def __init__(self, backbone: nn.Module):
        super().__init__()
        self.backbone = backbone
        self.register_buffer("mean", torch.tensor([0.485, 0.456, 0.406]).reshape(1, 1, 1, 3))
        self.register_buffer("std", torch.tensor([0.229, 0.224, 0.225]).reshape(1, 1, 1, 3))

    def forward(self, x: torch.Tensor) -> torch.Tensor:  # [1,224,224,3]
        x = (x - self.mean) / self.std
        x = x.permute(0, 3, 1, 2)  # -> NCHW
        return torch.softmax(self.backbone(x), dim=1)


wrapper = SkinWrapper(model).eval()

# deterministic test input resembling real 0..255 pixels scaled to [0,1]
rng = torch.Generator().manual_seed(42)
sample = (torch.rand(1, 224, 224, 3, generator=rng) * 255).round() / 255.0
with torch.no_grad():
    ref = wrapper(sample).numpy()
print("pytorch ref:", np.round(ref[0], 4))

print("converting with litert-torch...")
import litert_torch

edge_model = litert_torch.convert(wrapper, (sample,))
os.makedirs(os.path.dirname(OUT), exist_ok=True)
edge_model.export(OUT)
print("exported:", OUT, os.path.getsize(OUT) / 1e6, "MB")

print("validating the exported .tflite (via clean TF venv)...")
import subprocess, textwrap

check = textwrap.dedent(
    """
    import numpy as np, tensorflow as tf, sys
    itp = tf.lite.Interpreter(model_path=sys.argv[1])
    itp.allocate_tensors()
    inp, outp = itp.get_input_details()[0], itp.get_output_details()[0]
    assert inp['shape'].tolist() == [1,224,224,3], inp['shape']
    assert outp['shape'].tolist() == [1,7], outp['shape']
    x = np.load('tools/valid_input.npy'); ref = np.load('tools/valid_ref.npy')
    itp.set_tensor(inp['index'], x); itp.invoke()
    tfl = itp.get_tensor(outp['index'])
    d = float(np.max(np.abs(ref - tfl)))
    print('max abs diff pytorch-vs-tflite:', d)
    assert d < 1e-4, 'numerical mismatch'
    print('TFLITE VALIDATION PASSED')
    """
)
r = subprocess.run(
    ["/home/hatch/workspace/.tfvalid/bin/python", "-c", check, OUT],
    capture_output=True, text=True,
)
print(r.stdout[-800:] if r.stdout else r.stderr[-800:])
assert r.returncode == 0, "tflite validation failed"
