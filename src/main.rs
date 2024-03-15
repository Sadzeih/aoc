use std::fs::File;
use std::io::BufReader;

const INPUT: &str = "d1p1";

mod d1;

fn main() {
    let file = File::open(INPUT).expect("could not open input");
    let mut reader = BufReader::new(file);

    d1::solve_p1(&mut reader);
}
