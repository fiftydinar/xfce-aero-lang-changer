fn main() {
    // If bundled feature is enabled, fltk-sys handles everything.
    if std::env::var("CARGO_FEATURE_BUNDLED").is_ok() {
        return;
    }
    let output = std::process::Command::new("fltk-config")
        .args(["--use-images", "--ldstaticflags"])
        .output();
    let Ok(output) = output else { return };
    let flags = String::from_utf8_lossy(&output.stdout);
    let mut lib_dirs: Vec<String> = Vec::new();
    let mut libs: Vec<String> = Vec::new();
    let mut static_libs: Vec<String> = Vec::new();
    for flag in flags.split_whitespace() {
        if let Some(dir) = flag.strip_prefix("-L") {
            lib_dirs.push(dir.to_string());
            println!("cargo:rustc-link-search=native={}", dir);
        } else if let Some(lib) = flag.strip_prefix("-l") {
            libs.push(lib.to_string());
        } else if flag.ends_with(".a") {
            // Absolute path to a static library
            let path = std::path::Path::new(flag);
            if let Some(dir) = path.parent() {
                let dir_str = dir.to_str().unwrap().to_string();
                if !lib_dirs.contains(&dir_str) {
                    lib_dirs.push(dir_str.clone());
                    println!("cargo:rustc-link-search=native={}", dir_str);
                }
            }
            let file_name = path.file_name().and_then(|s| s.to_str()).unwrap_or("");
            if file_name.starts_with("lib") && file_name.ends_with(".a") {
                let lib = &file_name[3..file_name.len()-2];
                static_libs.push(lib.to_string());
            } else {
                // Fallback: use the whole file name without .a as the lib name
                let lib = file_name.trim_end_matches(".a");
                static_libs.push(lib.to_string());
            }
        }
    }
    // Emit the static libraries we found via absolute paths
    for lib in static_libs {
        println!("cargo:rustc-link-lib=static={}", lib);
    }
    // Determine for each -l flag whether it's static or dylib
    for lib in libs {
        let is_static = lib_dirs.iter().any(|dir| {
            let path = std::path::Path::new(dir).join(format!("lib{}.a", lib));
            path.exists()
        });
        let kind = if is_static { "static" } else { "dylib" };
        println!("cargo:rustc-link-lib={}={}", kind, lib);
    }
}
