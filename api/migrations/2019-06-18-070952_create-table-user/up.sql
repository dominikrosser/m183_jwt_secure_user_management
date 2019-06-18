-- Your SQL goes here

CREATE TABLE users (
	id SERIAL PRIMARY KEY,
	username VARCHAR NOT NULL,
	pw_hash VARCHAR NOT NULL,
	pw_salt VARCHAR NOT NULL
);