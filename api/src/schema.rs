table! {
    users (id) {
        id -> Int4,
        username -> Varchar,
        pw_hash -> Varchar,
        pw_salt -> Varchar,
    }
}
