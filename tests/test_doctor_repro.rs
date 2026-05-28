use zeroclaw_config::schema::Config;
use std::path::Path;

#[cfg(test)]
mod tests {
    use super::*;
    use zeroclaw_providers;

    fn provider_validation_error(name: &str) -> Option<String> {
        match zeroclaw_providers::create_model_provider(name, None) {
            Ok(_) => None,
            Err(err) => Some(
                err.to_string()
                    .lines()
                    .next()
                    .unwrap_or("invalid model_provider")
                    .into(),
            ),
        }
    }

    #[test]
    fn test_doctor_validation_repro() {
        let config_path = Path::new("test_config_dir/config.toml");
        let config_str = std::fs::read_to_string(config_path).expect("failed to read config");
        let config: Config = toml::from_str(&config_str).expect("failed to parse config");

        for route in &config.model_routes {
            if let Some(reason) = provider_validation_error(&route.model_provider) {
                println!("⚠️  model route \"{}\" uses invalid model_provider \"{}\": {}", route.hint, route.model_provider, reason);
            } else {
                println!("✅ model route \"{}\" is valid", route.hint);
            }
        }
    }
}
