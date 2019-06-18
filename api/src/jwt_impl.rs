// https://skinkade.github.io/rocket-jwt-roles-demo/

use ::serde::{Serialize, Deserialize};
use ::time;
use ::jwt::{encode, decode, Header, Algorithm, Validation};

// head -c16 /dev/urandom > secret.key
static KEY: &'static [u8; 16] = include_bytes!("../secret.key");
static ONE_WEEK: i64 = 60 * 60 * 24 * 7;

#[derive(Debug, Serialize, Deserialize)]
struct UserRolesToken {
    // issued at
    iat: i64,
    // expiration
    exp: i64,
    user: String,
    roles: Vec<String>,
}

impl UserRolesToken {
    fn has_role(&self, role: &str) -> bool {
        self.roles.contains(&role.to_string())
    }
}

pub fn jwt_generate(user: String, roles: Vec<String>) -> String {
    let now = time::get_time().sec;
    let payload = UserRolesToken {
        iat: now,
        exp: now + ONE_WEEK,
        user: user,
        roles: roles,
    };

    encode(&Header::default(), &payload, KEY).unwrap()
}