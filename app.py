from flask import Flask, request, jsonify
from pdf2image import convert_from_bytes
import base64
from io import BytesIO

app = Flask(__name__)

@app.route('/convert_pdf', methods=['POST'])
def convert_pdf():
      if 'file' not in request.files:
          return jsonify({'error': 'No file uploaded'}), 400
      file = request.files['file']
      pdf_bytes = file.read()
      images = convert_from_bytes(pdf_bytes, dpi=300)
      base64_images = []
      for img in images:
          buffered = BytesIO()
          img.save(buffered, format="JPEG", quality=95)
          img_str = base64.b64encode(buffered.getvalue()).decode()
          base64_images.append(img_str)
      return jsonify({'images': base64_images})

if __name__ == '__main__':
      app.run(host='0.0.0.0', port=5001, debug=True)