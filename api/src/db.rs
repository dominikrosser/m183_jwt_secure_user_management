/* This module / file contains code responsible for all db connections
 * i.e. the connection pool (implemented with r2d2 crate) */

use ::diesel::pg::PgConnection;
use ::r2d2;
use ::r2d2_diesel::ConnectionManager;
use ::rocket::http::Status;
use ::rocket::request::{self, FromRequest};
use ::rocket::{Outcome, Request, State};
use ::std::ops::Deref;

pub type Pool = r2d2::Pool<ConnectionManager<PgConnection>>;

pub fn init_pool(db_url: &str) -> Pool {
    let manager = ConnectionManager::<PgConnection>::new(db_url);
    r2d2::Pool::new(manager).expect("db pool failure")
}

/** Wrapper around an r2d2 pooled connection */
pub struct Conn(pub r2d2::PooledConnection<ConnectionManager<PgConnection>>); 

impl<'a, 'r> FromRequest<'a, 'r> for Conn {
    type Error = ();

    fn from_request(request: &'a Request<'r>) -> request::Outcome<Conn, ()> {
        let pool = request.guard::<State<Pool>>()?;
        match pool.get() {
            Ok(conn) => Outcome::Success(Conn(conn)),
            Err(_) => Outcome::Failure((Status::ServiceUnavailable, ())),
        }
    }
}

impl Deref for Conn {
    type Target = PgConnection;

    #[inline(always)]
    fn deref(&self) -> &Self::Target {
        &self.0
    }
}