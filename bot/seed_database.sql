DROP TABLE IF EXISTS score_submission;
DROP TABLE IF EXISTS run_category;
DROP TABLE IF EXISTS "user";

CREATE TABLE "user" (
    id SERIAL PRIMARY KEY,

);
ALTER SEQUENCE user_id_seq RESTART WITH 10000;

CREATE TABLE run_category (
    id SERIAL PRIMARY KEY,
    "name" VARCHAR(64) UNIQUE NOT NULL
);
ALTER SEQUENCE run_category_id_seq RESTART WITH 10;

CREATE TABLE score_submission (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL FOREIGN KEY REFERENCES "user"(id),
    category_id INTEGER NOT NULL FOREIGN KEY REFERENCES run_category(id),
    score INTEGER NOT NULL,
    evidence_link VARCHAR(65536),
    created_date TIMESTAMPTZ NOT NULL
);
ALTER SEQUENCE score_submission_id_seq RESTART WITH 100000;

INSERT INTO run_category ("name") VALUES 
    ('marathon'),
    ('micro31'),
    ('killscreen'),
    ('single'),
    ('mil'),
    ('5man'),
    ('pb');