const video = document.getElementById('video');
const canvas = document.getElementById('canvas');
const captureButton = document.getElementById('capture');
const context = canvas.getContext('2d');

// Access the camera
navigator.mediaDevices.getUserMedia({ video: true, audio: false })
    .then(stream => {
        video.srcObject = stream;
    })
    .catch(err => {
        console.error('Error accessing camera:', err);
    });

captureButton.addEventListener('click', () => {
    // Draw the current frame from the video onto the canvas
    context.drawImage(video, 0, 0, 640, 480);

    // Convert the canvas image to base64
    const imageDataURL = canvas.toDataURL('image/png');

    // Send the image to the server
    fetch('/capture', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ image: imageDataURL })
    })
    .then(response => response.json())
    .then(data => {
        console.log(data.message);
    })
    .catch(error => {
        console.error('Error sending image:', error);
    });
});
