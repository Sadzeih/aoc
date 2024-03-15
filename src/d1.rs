use std::{
    fs::File,
    io::{BufRead, BufReader},
};

pub fn solve_p1(reader: &mut BufReader<File>) {
    let mut sum = 0;
    let mut line = String::new();
    loop {
        let len = reader.read_line(&mut line).expect("could not read line");
        if len == 0 {
            break;
        }
        let fdi = line.find(char::is_numeric).unwrap();
        let ldi = line.rfind(char::is_numeric).unwrap();
        let fd = line
            .chars().nth(fdi)
            .expect("could not get first digit")
            .to_digit(10)
            .expect("could not convert to u32");
        let ld = line
            .chars()
            .nth(ldi)
            .expect("couuld not get last digit")
            .to_digit(10)
            .expect("could not convert to u32");
        println!("{fd} {ld}");
        sum += fd + ld;
    }
    println!("{sum}")
}
