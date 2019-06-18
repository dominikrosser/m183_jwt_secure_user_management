#![feature(proc_macro_hygiene, decl_macro, const_fn, custom_attribute, plugin/*, proc_macro_derive*/)]
//#![plugin(rocket_codegen)]
#![allow(dead_code, unused_imports, unused_variables)]

#[macro_use]
extern crate rocket;

#[macro_use]
extern crate rocket_contrib;
extern crate rocket_cors;

#[macro_use]                    
extern crate diesel;

#[macro_use]
extern crate serde_derive;
extern crate serde_json;

// create json web tokens
extern crate jsonwebtoken as jwt;

// include password hashing library
extern crate argon2rs;

extern crate dotenv;
extern crate rand;
extern crate time;

mod db;
mod schema;
mod models;
mod pw_hashing;
mod jwt_impl;
mod routes;
mod cors_options;

// to read environment variables
use std::env;
use dotenv::dotenv;

// pass a different base configuration to our app
use rocket::config::{Config, Environment};

// include api routes functions
use routes::*;

// get the PORT from the env variable PORT
fn get_server_port() -> u16 {
    env::var("PORT")
        .ok()
        .and_then(|p| p.parse().ok())
        .unwrap_or(8181)
}

#[post("/user/new")]
fn main() {
    dotenv().ok();

    // Read DATABASE_URL from .env
    let database_url = env::var("DATABASE_URL").expect("set DATABASE_URL");

    // Init postgres connection pool managed by r2d2
    let pool = db::init_pool(&database_url);



    let config = Config::build(Environment::Staging)
        .address("0.0.0.0")
        .port(get_server_port())
        .unwrap();

    rocket::custom(config)
        .manage(pool)
        .mount("/", routes![routes::index])
        .mount("/api/v1/", routes![routes::all_users, routes::new_user, routes::show_user, routes::update_user, routes::delete_user])

        // Set custom CORS options
        .attach(cors_options::cors_options())

        .launch();
}