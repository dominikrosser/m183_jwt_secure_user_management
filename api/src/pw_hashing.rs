
use ::dotenv::dotenv;
use ::rand::Rng;
use rand::distributions::Alphanumeric;
use ::std::env;
use argon2rs::defaults::{KIB, LANES, PASSES};
use argon2rs::verifier::Encoded;
use argon2rs::{Argon2, Variant};

pub struct HashedData {
    pub hash: String,
    pub salt: String
}

pub fn hash_data(data: &str) -> HashedData {

    // https://elliotekj.com/2017/04/02/hashing-sensitive-data-in-rust-with-argon2rs/

    let local_salt = env::var("LOCAL_SALT").expect("LOCAL_SALT must be set");
    let random_salt = rand::thread_rng()
        .sample_iter(&Alphanumeric)
        .take(32)
        .collect::<String>();

    let a2 = Argon2::new(PASSES, LANES, KIB, Variant::Argon2d).unwrap();
    let random_salt_hash = Encoded::new(a2, random_salt.as_bytes(), local_salt.as_bytes(), b"", b"").to_u8();
    let random_salt_hash_storable_encoding = String::from_utf8(random_salt_hash).unwrap();

    let a2 = Argon2::new(PASSES, LANES, KIB, Variant::Argon2d).unwrap();
    let data_hash = Encoded::new(a2, data.as_bytes(), random_salt_hash_storable_encoding.as_bytes(), b"", b"").to_u8();
    let data_hash_storable_encoding = String::from_utf8(data_hash).unwrap();

    println!("random salt: {}", random_salt);
    println!("data hash: {}", data_hash_storable_encoding);

    HashedData {
        hash: String::from(data_hash_storable_encoding),
        salt: String::from(random_salt)
    }
}

pub fn compare_input_to_hashed_value(input: &str, hashed_value: &str, random_salt: &str) -> bool {
    let local_salt = env::var("LOCAL_SALT").expect("LOCAL_SALT must be set");

    let a2 = Argon2::new(PASSES, LANES, KIB, Variant::Argon2d).unwrap();
    let random_salt_hash = Encoded::new(a2, random_salt.as_bytes(), local_salt.as_bytes(), b"", b"").to_u8();
    let random_salt_hash_storable_encoding = String::from_utf8(random_salt_hash).unwrap();

    let a2 = Argon2::new(PASSES, LANES, KIB, Variant::Argon2d).unwrap();
    let data_hash = Encoded::new(a2, input.as_bytes(), random_salt_hash_storable_encoding.as_bytes(), b"", b"").to_u8();
    let data_hash_storable_encoding = String::from_utf8(data_hash).unwrap();

    if data_hash_storable_encoding == hashed_value {
        println!("They're equal!");
        true
    } else {
        println!("They're not equal.");
        false
    }
}

// Beispiel:
// let data_to_hash = /* However it is you receive user input */;
// hash_data(data_to_hash);

// let user_input = /* However it is you receive user input */;
// let hashed_data = /* Retrieve the previously hashed data from your database */;
// let random_salt = /* Retrieve the randomly generated salt from your database */;
// compare_input_to_hashed_value(user_input, hashed_data, random_salt);