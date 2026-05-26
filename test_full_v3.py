import time
import hmac
import hashlib
import base64
import json
import requests

def base64url_encode(data):
    return base64.urlsafe_b64encode(data).decode('utf-8').replace('=', '')

def generate_token(apikey: str, exp_seconds: int):
    id, secret = apikey.split(".")
    
    # Header EXACTLY like ZeroClaw
    header = {"alg": "HS256", "typ": "JWT", "sign_type": "SIGN"}
    header_json = json.dumps(header, separators=(',', ':'))
    header_b64 = base64url_encode(header_json.encode('utf-8'))
    
    now_ms = int(round(time.time() * 1000))
    exp_ms = now_ms + exp_seconds * 1000
    
    # Payload EXACTLY like ZeroClaw
    payload = {"api_key": id, "exp": exp_ms, "timestamp": now_ms}
    payload_json = json.dumps(payload, separators=(',', ':'))
    payload_b64 = base64url_encode(payload_json.encode('utf-8'))
    
    signing_input = f"{header_b64}.{payload_b64}"
    
    signature = hmac.new(
        secret.encode('utf-8'),
        signing_input.encode('utf-8'),
        hashlib.sha256
    ).digest()
    
    sig_b64 = base64url_encode(signature)
    
    return f"{signing_input}.{sig_b64}"

api_key = "fe519f6bce1644daabfd64d4e69b85dc.419FNlRF0tTvVUdW"
token = generate_token(api_key, 210)

url = "https://open.bigmodel.cn/api/paas/v4/chat/completions"
headers = {
    "Content-Type": "application/json",
    "Authorization": f"Bearer {token}"
}
data = {
    "model": "glm-4.6v-flash",
    "messages": [{"role": "user", "content": "hi"}],
    "stream": False
}

response = requests.post(url, headers=headers, data=json.dumps(data))
print(f"Status: {response.status_code}")
print(response.text)
