from flask import Flask, request, jsonify, render_template
import base64
import os
import cv2
import numpy as np
import sys

app = Flask(__name__)
app.static_folder = 'frontend'

# Create a directory to store captured images
UPLOAD_FOLDER = 'captured_images'
if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)

app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

num_pictures = 1  # Default value

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/capture', methods=['POST'])
def capture():
    global num_pictures
    data = request.get_json()
    image_data = data['image'].split(',')[1]  # Remove the data:image/png;base64, prefix
    image_bytes = base64.b64decode(image_data)
    image_array = np.frombuffer(image_bytes, dtype=np.uint8)
    image = cv2.imdecode(image_array, cv2.IMREAD_COLOR)

    # Save the image
    filename = os.path.join(app.config['UPLOAD_FOLDER'], f'captured_image_{capture.counter}.png')
    cv2.imwrite(filename, image)
    print(f"Image saved as {filename}")

    capture.counter += 1
    if capture.counter >= num_pictures:
        print("All pictures captured. Exiting.")
        os._exit(0)  # Forcefully exit the program

    return jsonify({'message': 'Image captured successfully!'})

capture.counter = 0

if __name__ == '__main__':
    if len(sys.argv) > 1:
        num_pictures = int(sys.argv[1])
    app.run(debug=False, host='0.0.0.0') # Disable debug and specify host
