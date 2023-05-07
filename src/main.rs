mod heap;
use clap::Parser;
use heap::MinHeap;
use std::process::Command;

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

fn get_all_packages() -> Vec<String> {
    let mut cmd = Command::new("apt")
        .arg("list")
        .output()
        .expect("failed to run 'apt list'");

    let all_packages: Vec<String> = String::from_utf8_lossy(&cmd.stdout)
        .split("Listing...\n")
        .map(|s| s.to_string())
        .collect();

    return all_packages;
}

fn get_suggestions(orig_pkg: &String) -> Vec<String> {
    let mh: heap::MinHeap<i32> = MinHeap::new();
    let all_packages = get_all_packages();
    // let top_10
    for pkg in all_packages.clone() {
        // if len top_10 == 10 && dist <
        // do sth
    }
    return all_packages;
}

fn main() {
    let args = Cli::parse();
    let top_10_suggestions = get_suggestions(&args.package_name);
    // let regexes = generate_fuzzy_alternatives(args.package_name.clone());

    for suggestion in top_10_suggestions {
        let output = Command::new("apt")
            // .args(&["list", regex])
            .arg("search")
            .arg(suggestion)
            .output()
            .expect(format!("failed to search for package {}", args.package_name).as_str());
        println!("{}", String::from_utf8(output.stdout).unwrap());
    }
}

// try 1: for every package, give me the top 10 with the closest (smallest) hamming distance
