from flask import Flask, request, jsonify
from azure.cognitiveservices.vision.customvision.prediction import CustomVisionPredictionClient
from msrest.authentication import ApiKeyCredentials
import os

app = Flask(__name__)
# Azure Custom Vision credentials (replace with your actual values)
ENDPOINT = "https://billclassifier-prediction.cognitiveservices.azure.com/"
PREDICTION_KEY = "BXKKiGsfEqHeSP4KSgb09YXpAH36PqCwsIG6hCurmGIDSKMCD8snJQQJ99BGACYeBjFXJ3w3AAAIACOGcA1F"
PROJECT_ID = "9e9fe0ac-3e74-4139-a9fc-b4633d228ae1"
PUBLISH_ITERATION_NAME = "Iteration4"

prediction_credentials = ApiKeyCredentials(in_headers={"Prediction-key": PREDICTION_KEY})
predictor = CustomVisionPredictionClient(ENDPOINT, prediction_credentials)

@app.route('/validate-bill', methods=['POST'])
def validate_bill():
    if 'file' not in request.files:
        return jsonify({'error': 'No file uploaded'}), 400
    file = request.files['file']
    image_bytes = file.read()

    # Use Azure Custom Vision to classify the image
    results = predictor.classify_image(
        PROJECT_ID, PUBLISH_ITERATION_NAME, image_bytes
    )

    # Find the tag with the highest probability
    best_prediction = max(results.predictions, key=lambda p: p.probability)
    return jsonify({
        'result': best_prediction.tag_name,
        'probability': best_prediction.probability
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8001)