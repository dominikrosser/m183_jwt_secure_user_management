use ::rocket;
use ::rocket_cors;

use ::rocket::http::Method;
use ::rocket::{get, post, delete, put, routes};
use ::rocket_cors::{Cors, AllowedHeaders, AllowedOrigins, Error};

pub fn cors_options() -> Cors {
    let allowed_origins = AllowedOrigins::all();
    //let allowed_methods = vec![Method::Get, Method::Post, Method::Delete, Method::Put]
    //    .into_iter()
    //    .map(From::from)
    //    .collect();
    //let allowed_headers = AllowedHeaders::all();

    rocket_cors::CorsOptions {
        allowed_origins: allowed_origins,
        //allowed_methods: allowed_methods, 
        //allowed_headers: allowed_headers, 
        allow_credentials: true,
        ..Default::default()
    }
    .to_cors()
    .expect("Error: Cors options object couldn't be created")
}