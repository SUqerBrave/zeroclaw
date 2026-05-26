fn base64url_no_pad(data: &[u8]) -> String {
    let mut s = base64::Engine::encode(&base64::engine::general_purpose::URL_SAFE_NO_PAD, data);
    s
}

fn main() {
    let credential = "fe519f6bce1644daabfd64d4e69b85dc.419FNlRF0tTvVUdW";
    let (id, secret) = credential.split_once('.').unwrap();

    let now_ms = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap()
        .as_millis() as u64;
    let exp_ms = now_ms + 210_000;

    let header_b64 = base64url_no_pad(br#"{"alg":"HS256","typ":"JWT","sign_type":"SIGN"}"#);
    let payload = format!(r#"{{"api_key":"{}","exp":{},"timestamp":{}}}"#, id, exp_ms, now_ms);
    let payload_b64 = base64url_no_pad(payload.as_bytes());

    let signing_input = format!("{}.{}", header_b64, payload_b64);
    let key = ring::hmac::Key::new(ring::hmac::HMAC_SHA256, secret.as_bytes());
    let sig = ring::hmac::sign(&key, signing_input.as_bytes());
    let sig_b64 = base64url_no_pad(sig.as_ref());

    let token = format!("{}.{}", signing_input, sig_b64);
    println!("{}", token);
}
