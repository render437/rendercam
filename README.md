# rendercam

A website disguised as Google Meet that secretly captures user's faces.

**Disclaimer:** This project is for educational purposes only. Do not use it for malicious activities.

## Setup

1.  Clone the repository:

    ```bash
    git clone [repository URL]
    cd rendercam
    ```

2.  Run the main script:

    ```bash
    python scripts/main.py
    ```

## Usage

1.  The script will guide you through the setup.
2.  You will be prompted to enter the number of pictures to take.
3.  You will be prompted to choose a hosting method:
    *   `localhost`
    *   `localxpose`
    *   `cloudflare`
    *   `ngrok`
4.  The script will automatically install dependencies and set up the chosen hosting method.
5.  Share the generated URL with the target.
6.  Captured images will be saved in the `captured_images` directory on the attacker's device.

**Note:** Make sure you have Python installed and up-to-date.
