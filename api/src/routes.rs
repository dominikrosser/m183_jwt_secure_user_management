use crate::db::Conn as DbConn;
use crate::models::{User, NewUser};
use crate::pw_hashing;
use crate::jwt_impl;
use ::rocket_contrib::json::Json;
use ::rocket_contrib::json::JsonValue;
use ::rocket::request::Form;
use ::rocket::http::{Cookies,Cookie};

#[derive(FromForm)]
pub struct Login {
    pub username: String,
    pub password: String
}

impl Login {
    pub fn hash_user(&self) -> NewUser {
        let hashed_data = pw_hashing::hash_data(&self.password);

        NewUser {
            username: self.username.clone(),
            pw_hash: hashed_data.hash,
            pw_salt: hashed_data.salt
        }
    }
}


//-- API Routes

#[get("/")]
pub fn index(cookies: Cookies) -> &'static str {
    "Hello, world!"
}

#[post("/login", data="<login_form>")]
pub fn login(conn: DbConn, mut cookies: Cookies, login_form: Form<Login>) -> JsonValue {
    let validation_ok: bool = User::exists_with_username_and_password(&login_form.username, &login_form.password, &conn);

    // does a user with this username exist and was a correct password entered?
    if validation_ok {
        let jwt_token = jwt_impl::jwt_generate(login_form.username.clone(), vec![String::from("admin")]);
        let cookie = Cookie::build("jwt"/*.into()*/, jwt_token).finish();
        // Add jwt cookie
        cookies.add(cookie);
    }

    // return json with status that informs whether the login was successful and a cookie was created or not
    json!({
        "status": validation_ok
    })
}

#[get("/users", format = "application/json")]
pub fn all_users(conn: DbConn, cookies: Cookies) -> JsonValue {
    let users = User::all(&conn);

    json!({
        "status": 200,
        "result": users,
    })
}

#[post("/users", format= "application/json", data = "<login_form>")]
pub fn new_user(conn: DbConn, cookies: Cookies, login_form: Form<Login>) -> JsonValue {
    let new_user = login_form.hash_user();
    let insert_ok: bool = User::insert(new_user/*.into_inner()*/, &conn);
    let users = User::all(&conn);
    let inserted_user = users.first();

    json!({
        "status": insert_ok,
        "result": inserted_user,
    })
}

#[get("/users/<id>", format = "application/json")]
pub fn show_user(conn: DbConn, cookies: Cookies, id: i32) -> JsonValue {
    let result = User::get_by_id(id, &conn);
    let status = if result.is_empty() { 404 } else { 200 };

    json!({
        "status": status,
        "result": result.get(0),
        })
}

#[put("/users/<id>", format = "application/json", data = "<user>")]
pub fn update_user(conn: DbConn, cookies: Cookies, id: i32, user: Json<NewUser>) -> JsonValue {
    let status = if User::update_by_id(id, &conn, user.into_inner()) { 200 } else { 404 };

    json!({
        "status": status,
        "result": null,
    })
}

#[delete("/users/<id>")]
pub fn delete_user(id: i32, conn: DbConn, cookies: Cookies) -> JsonValue {
    let status = if User::delete_by_id(id, &conn) { 200 } else { 404 };

    json!({
        "status": status,
        "result": null,
    })
}