use ::diesel;
use ::diesel::prelude::*;
use ::diesel::pg::PgConnection;
use crate::schema::users;
use crate::schema::users::dsl::users as all_users;
use crate::pw_hashing;

#[derive(Queryable)]    // Queryable from db table
#[derive(Serialize)]    // Convertable to json
#[derive(Deserialize)]
#[derive(Debug)]        // Convertable to debug string
pub struct User {
    pub id: i32,
    pub username: String,
    pub pw_hash: String,
    pub pw_salt: String
}

#[derive(Insertable)]   // Insertable to db table
#[derive(Serialize)]    // Convertable to json
#[derive(Deserialize)]  // Convertable from json
#[table_name = "users"] // Table name: "users"
pub struct NewUser {
    pub username: String,
    pub pw_hash: String,
    pub pw_salt: String
}

/** CRUD */
impl User {

    pub fn get_by_id(id: i32, conn: &PgConnection) -> Vec<User> {
        all_users
            .find(id)
            .load::<User>(conn)
            .expect("Error loading user by id")
    }

    pub fn get_by_username_and_password(username: &str, password: &str, conn: &PgConnection) -> Option<User> {
        use users::dsl::{username as un, pw_hash as pwh, pw_salt as pws};

        let user_by_name =
            match all_users
                .filter( un.eq(&username) )
                .first::<User>(conn) {
                Ok(user) => Some(user),
                Err(_) => None
            };

        match user_by_name {
            None => None,
            Some(user_by_name) => {
                // compare hashed values
                let pw_ok = pw_hashing::compare_input_to_hashed_value(password, &user_by_name.pw_hash, &user_by_name.pw_salt);
                // if equal, the user with given password and username exists
                if pw_ok {
                    Some(user_by_name)
                } else {
                    None
                }
            }
        }
    }

    pub fn exists_with_username_and_password(username: &str, password: &str, conn: &PgConnection) -> bool {
        let maybe_user = User::get_by_username_and_password(username, password, &conn);
        
        match maybe_user {
            Some(_) => true,
            None => false
        }
    }

    pub fn all(conn: &PgConnection) -> Vec<User> {
        all_users
            .order(users::id.desc())
            .load::<User>(conn)
            .expect("Error loading the users")
    }

    pub fn update_by_id(id: i32, conn: &PgConnection, user: NewUser) -> bool {
        use users::dsl::{username as un, pw_hash as pwh, pw_salt as pws};
        let NewUser {
            username,
            pw_hash,
            pw_salt
        } = user;
        diesel::update(all_users.find(id))
            .set( (un.eq(username), pwh.eq(pw_hash), pws.eq(pw_salt)) )
            .get_result::<User>(conn)
            .is_ok()
    }

    pub fn insert(user: NewUser, conn: &PgConnection) -> bool {
        diesel::insert_into(users::table)
            .values(&user)
            .execute(conn)
            .is_ok()
    }
    
    pub fn delete_by_id(id: i32, conn: &PgConnection) -> bool {
        if User::get_by_id(id, conn).is_empty() {
            return false;
        };
        diesel::delete(all_users.find(id)).execute(conn).is_ok()
    }
}