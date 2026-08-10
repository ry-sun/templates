fn greeting(name: &str) -> String {
    format!("Hello, {name}! You've been greeted from Rust!")
}

#[tauri::command]
fn greet(name: &str) -> String {
    greeting(name)
}

/// Start the Tauri application and register its commands.
///
/// # Panics
///
/// Panics when the Tauri runtime cannot start or encounters an unrecoverable error.
#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .invoke_handler(tauri::generate_handler![greet])
        .run(tauri::generate_context!())
        .expect("error while running Tauri application");
}

#[cfg(test)]
mod tests {
    use super::greeting;

    #[test]
    fn builds_greeting_for_name() {
        assert_eq!(
            greeting("Codex"),
            "Hello, Codex! You've been greeted from Rust!"
        );
    }
}
