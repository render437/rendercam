import os
import subprocess
import sys

def display_menu():
    print("""
                     _                              
                    | |                             
  _ __ ___ _ __   __| | ___ _ __ ___ __ _ _ __ ___  
 | '__/ _ \ '_ \ / _` |/ _ \ '__/ __/ _` | '_ ` _ \ 
 | | |  __/ | | | (_| |  __/ | | (_| (_| | | | | | |
 |_|  \___|_| |_|\__,_|\___|_|  \___\__,_|_| |_| |_|
                                                    
    """)

def get_num_pictures():
    while True:
        try:
            num_pictures = int(input("Enter the number of pictures to take: "))
            if num_pictures > 0:
                return num_pictures
            else:
                print("Please enter a positive number.")
        except ValueError:
            print("Invalid input. Please enter a number.")

def choose_hosting():
    while True:
        print("\nChoose a hosting method:")
        print("1. localhost")
        print("2. ngrok")  # Removed localxpose
        choice = input("Enter your choice (1-2): ")  # Adjusted range

        if choice in ("1", "2"):  # Adjusted options
            return choice
        else:
            print("Invalid choice. Please enter 1 or 2.")

def setup_localhost():
    print("Setting up localhost...")
    # Instructions for running the Flask server on localhost will be in server.py

def setup_ngrok():
    print("Setting up ngrok...")
    try:
        from pyngrok import ngrok
        # Replace 'YOUR_NGROK_TOKEN' with your actual ngrok token
        ngrok.set_auth_token("YOUR_NGROK_TOKEN")
        public_url = ngrok.connect(5000)
        print(f"Ngrok tunnel URL: {public_url}")
    except Exception as e:
        print(f"Error running ngrok: {e}")

def main():
    display_menu()
    num_pictures = get_num_pictures()
    hosting_choice = choose_hosting()

    if hosting_choice == "1":
        setup_localhost()
    elif hosting_choice == "2":
        setup_ngrok() # removed localxpose

    # Run the Flask server
    print("Starting the Flask server...")
    subprocess.Popen([sys.executable, "scripts/server.py", str(num_pictures)])

if __name__ == "__main__":
    main()
