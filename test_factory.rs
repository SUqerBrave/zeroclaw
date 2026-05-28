use zeroclaw_providers;

fn main() {
    let result = zeroclaw_providers::create_model_provider("openrouter.default", None);
    match result {
        Ok(_) => println!("✅ Success"),
        Err(e) => println!("❌ Error: {}", e),
    }
}
