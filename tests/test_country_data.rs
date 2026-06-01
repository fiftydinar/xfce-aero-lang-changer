#[test]
fn test_country_names_json() -> Result<(), Box<dyn std::error::Error>> {
    use std::collections::HashMap;
    let data: HashMap<String, HashMap<String, String>> =
        serde_json::from_str(include_str!("../data/country_names.json"))?;

    assert_eq!(data.get("tt").and_then(|m| m.get("RU")).unwrap(), "Русия");
    assert_eq!(data.get("sr@latin").and_then(|m| m.get("RS")).unwrap(), "Srbija");
    assert_eq!(data.get("sr").and_then(|m| m.get("RS")).unwrap(), "Србија");
    assert_eq!(data.get("en").and_then(|m| m.get("GB")).unwrap(), "United Kingdom");
    assert!(data.len() >= 200, "Expected >=200 langs, got {}", data.len());

    for k in &["be@latin", "sr@latin", "uz@cyrillic", "tt@iqtelif"] {
        assert!(data.contains_key(*k), "Missing key: {}", k);
    }
    Ok(())
}


