fn main() {
    // On glibc Linux, LLD cannot resolve _dl_x86_cpu_features and other
    // glibc internals referenced by the static FLTK library. Force GNU ld
    // to avoid this. Harmless on musl or where GNU ld is already the default.
    #[cfg(target_os = "linux")]
    println!("cargo:rustc-link-arg=-fuse-ld=bfd");

    let output = std::process::Command::new("fltk-config")
        .args(["--use-images", "--ldstaticflags"])
        .output();
    let Ok(output) = output else { return };
    let flags = String::from_utf8_lossy(&output.stdout);
    let mut lib_dirs: Vec<&str> = Vec::new();
    let mut libs: Vec<&str> = Vec::new();
    for flag in flags.split_whitespace() {
        if let Some(dir) = flag.strip_prefix("-L") {
            lib_dirs.push(dir);
            println!("cargo:rustc-link-search=native={}", dir);
        } else if let Some(lib) = flag.strip_prefix("-l") {
            libs.push(lib);
        }
    }
    for lib in libs {
        let is_static = lib_dirs.iter().any(|dir| {
            let path = std::path::Path::new(dir).join(format!("lib{}.a", lib));
            path.exists()
        });
        let kind = if is_static { "static" } else { "dylib" };
        println!("cargo:rustc-link-lib={}={}", kind, lib);
    }
}
