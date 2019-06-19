use ::rocket;
use ::rocket_cors;

use ::rocket::http::Method;
use ::rocket::{get, post, delete, put, routes};
use ::rocket_cors::{Cors, AllowedHeaders, AllowedOrigins, Error};

pub fn cors_options() -> Cors {
    let allowed_origins = AllowedOrigins::all();

    rocket_cors::CorsOptions {
        allowed_origins: allowed_origins,
        allow_credentials: true,
        ..Default::default()
    }
    .to_cors()
    .expect("Error: Cors options object couldn't be created")
}