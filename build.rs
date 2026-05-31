fn main() {
    if let Ok(output) = std::process::Command::new("fltk-config")
        .args(["--use-images", "--ldstaticflags"])
        .output()
    {
        let flags = String::from_utf8_lossy(&output.stdout);
        for flag in flags.split_whitespace() {
            if let Some(lib) = flag.strip_prefix("-l") {
                println!("cargo:rustc-link-lib=dylib={}", lib);
            } else if let Some(dir) = flag.strip_prefix("-L") {
                println!("cargo:rustc-link-search=native={}", dir);
            }
        }
        println!("cargo:rustc-link-lib=static=fltk");
        println!("cargo:rustc-link-lib=static=fltk_images");
    }
}
