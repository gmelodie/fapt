use clap::Parser;
use std::process::{Command, Stdio};

// Search for a pattern in a file and display the lines that contain it.
#[derive(Parser)]
struct Cli {
    // The "root" apt package look for
    package_name: String,
}

// TODO: implement a fuzzy euristic (https://www.baeldung.com/cs/fuzzy-search-algorithm)
// TODO: apt search keyword
// TODO: apt search .
// apt search REGEX
//
fn generate_fuzzy_alternatives(regex: String) -> Vec<String> {
    let mut fuzzy_alternatives: Vec<String> = Vec::new();
    fuzzy_alternatives.push(regex);

    return fuzzy_alternatives;
}

fn get_all_packages() -> Vec<String> {
    let mut all_packages = Command::new("apt")
        .arg("list")
        .output()
        .expect("failed to run 'apt list'");

    all_packages = String::from_utf8_lossy(&all_packages.stdout)
        .split("Listing...\n")
        .collect()[1]
}

fn main() {
    let args = Cli::parse();
    let all_packages = get_all_packages();
    let regexes = generate_fuzzy_alternatives(args.package_name.clone());

    for regex in regexes {
        let output = Command::new("apt")
            // .args(&["list", regex])
            .arg("search")
            .arg(regex)
            .output()
            .expect(format!("failed to search for package {}", args.package_name).as_str());
        println!("{}", String::from_utf8(output.stdout).unwrap());
    }
}
