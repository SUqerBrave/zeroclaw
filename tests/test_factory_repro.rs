#[cfg(test)]
mod tests {
    use zeroclaw_providers;

    #[test]
    fn test_factory_split() {
        let result = zeroclaw_providers::create_model_provider("openrouter.default", None);
        assert!(result.is_ok(), "Factory failed: {:?}", result.err());
    }
}
