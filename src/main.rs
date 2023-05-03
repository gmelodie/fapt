use clap::Parser;
use std::process::Command;

// Search for a pattern in a file and display the lines that contain it.
#[derive(Parser)]
struct Cli {
    // The "root" apt package look for
    package_name: String,
}

// TODO: implement a fuzzy euristic (https://www.baeldung.com/cs/fuzzy-search-algorithm)
// TODO: search common local dirs

fn main() {
    let args = Cli::parse();
    let output = Command::new("apt")
        .arg("search")
        .arg("cache")
        .arg(args.package_name.clone())
        .output()
        .expect(format!("failed to search for package {}", args.package_name).as_str());

    println!("{}", String::from_utf8(output.stdout).unwrap());
    //apt-cache search keyword
    //apt-cache search .
}
