import time
import jwt
import requests
import json

def generate_token(apikey: str, exp_seconds: int):
    id, secret = apikey.split(".")
    payload = {
        "api_key": id,
        "exp": int(round(time.time() * 1000)) + exp_seconds * 1000,
        "timestamp": int(round(time.time() * 1000)),
    }
    # Zhipu requires 'sign_type': 'SIGN' in header
    return jwt.encode(
        payload,
        secret,
        algorithm="HS256",
        headers={"alg": "HS256", "typ": "JWT", "sign_type": "SIGN"},
    )

api_key = "fe519f6bce1644daabfd64d4e69b85dc.419FNlRF0tTvVUdW"
token = generate_token(api_key, 300)

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
