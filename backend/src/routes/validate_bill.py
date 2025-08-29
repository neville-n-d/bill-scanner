import os
from flask import Blueprint, request, jsonify
import onnxruntime as ort
from PIL import Image
import numpy as np
import io

validate_bill_bp = Blueprint('validate_bill', __name__)

# Load ONNX model
ONNX_MODEL_PATH = os.path.join(os.path.dirname(__file__), '../../onnx/model.onnx')
session = ort.InferenceSession(ONNX_MODEL_PATH)

# Load labels
LABELS_PATH = os.path.join(os.path.dirname(__file__), '../../onnx/labels.txt')
with open(LABELS_PATH, 'r') as f:
    labels = [line.strip() for line in f.readlines()]

# Preprocessing function (adjust as needed for your model)
def preprocess_image(image_bytes):
    image = Image.open(io.BytesIO(image_bytes)).convert('RGB')
    image = image.resize((224, 224))  # Change to your model's input size
    arr = np.array(image).astype(np.float32)
    arr = arr / 255.0  # Normalize if needed
    arr = np.expand_dims(arr, axis=0)  # Add batch dimension
    arr = np.transpose(arr, (0, 3, 1, 2)) if arr.shape[-1] == 3 else arr  # NCHW if needed
    return arr

@validate_bill_bp.route('/validate-bill', methods=['POST'])
def validate_bill():
    if 'file' not in request.files:
        return jsonify({'error': 'No file uploaded'}), 400
    file = request.files['file']
    image_bytes = file.read()
    input_arr = preprocess_image(image_bytes)
    input_name = session.get_inputs()[0].name
    outputs = session.run(None, {input_name: input_arr})
    prediction = int(np.argmax(outputs[0], axis=1)[0])
    label = labels[prediction] if prediction < len(labels) else str(prediction)
    return jsonify({'result': label}) 