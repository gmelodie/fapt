mod heap;
use clap::Parser;
use heap::MinHeap;
use std::cmp::Ordering;
use std::fmt;
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

#[derive(Clone)]
struct Pkg {
    name: String,
    full_name: String,
    dist: i32,
}

impl PartialOrd for Pkg {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        if self.dist > other.dist {
            Option::Some(Ordering::Greater)
        } else if self.dist < other.dist {
            Option::Some(Ordering::Less)
        } else {
            Option::Some(Ordering::Equal)
        }
    }
}

impl PartialEq for Pkg {
    fn eq(&self, other: &Self) -> bool {
        self.dist == other.dist
    }
}

impl fmt::Display for Pkg {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "{} (Hamming distance: {})", self.full_name, self.dist)
    }
}

fn get_all_packages() -> Vec<Pkg> {
    let cmd = Command::new("apt")
        .arg("list")
        .arg("--all-versions")
        .output()
        .expect("failed to run 'apt list'");

    let all_packages: Vec<Pkg> = String::from_utf8_lossy(&cmd.stdout)
        .split("Listing...\n") // remove annoying Listing... string
        .nth(1)
        .unwrap()
        .lines() // split into lines
        .filter(|line| !line.is_empty()) // filter out empty lines
        .map(|s| Pkg {
            full_name: s.to_string().clone(),
            name: s.split('/').nth(0).unwrap().to_string(),
            dist: -1,
        }) // remove everything after / on package (version, arch)
        .collect();

    return all_packages;
}

fn hamming_dist(str1: &String, str2: &String) -> i32 {
    let mut dist: i32 = 0;
    let shortest_str = if str1.len() > str2.len() { str2 } else { str1 };
    for (i, _c) in shortest_str.chars().enumerate() {
        if str1.char_indices().nth(i) != str2.char_indices().nth(i) {
            dist += 1;
        }
    }

    // also add the lenght difference do the dist
    // hamming_dist(aba, aa) == 2
    let len_diff = str1.len() as i32 - str2.len() as i32;
    dist += len_diff.abs();

    return dist;
}

fn main() {
    let args = Cli::parse();
    let mut mh: heap::MinHeap<Pkg> = MinHeap::new();
    let all_packages = get_all_packages();

    // get hamming dist between strings

    println!("searching {} packages...", all_packages.len());
    for pkg in all_packages {
        let ham_dist = hamming_dist(&args.package_name, &pkg.name);
        // println!("hamming dist for {} is {}", pkg.name, ham_dist);
        mh.hpush(Pkg {
            name: pkg.name,
            full_name: pkg.full_name,
            dist: ham_dist,
        });
    }

    // let regexes = generate_fuzzy_alternatives(args.package_name.clone());

    for _ in 0..5 {
        println!("{}", mh.hpop());
    }
}

// try 1: for every package, give me the top 10 with the closest (smallest) hamming distance
//

#[cfg(test)]
mod tests {
    use crate::hamming_dist;
    #[test]
    fn test_hamming_distance() {
        assert_eq!(hamming_dist(&"asdf".to_string(), &"a".to_string()), 3);
        assert_eq!(hamming_dist(&"aaasdf".to_string(), &"aaas".to_string()), 2);
        assert_eq!(hamming_dist(&"abab".to_string(), &"baba".to_string()), 4);
    }
}
