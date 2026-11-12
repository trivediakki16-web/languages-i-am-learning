import requests

# The destination URL provided by your user or third-party service
webhook_url = "https://webhook.site/427db32e-9462-4bdf-9615-444491c058b3"

user_name = input("Enter your username: ")
message = input("Enter your message: ")
recipient_name = input("Enter the username of the person you want to send the message to: ") 

# The data you want to push out
payload = {
    "user": user_name,
    "message": message,
    "recipient": recipient_name
}

# Send the payload via an HTTP POST request
try:
    response = requests.post(webhook_url, json=payload, timeout=5)
    # Check if the client acknowledged it successfully
    if response.status_code == 200:
        print("Webhook sent successfully!")
    else:
        print(f"Failed to send. Server responded with: {response.status_code}")
except requests.exceptions.RequestException as e:
    print(f"An error occurred: {e}")
