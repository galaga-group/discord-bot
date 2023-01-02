DROP FUNCTION IF EXISTS get_player_best_scores;
DROP FUNCTION IF EXISTS do_submission;
DROP FUNCTION IF EXISTS lookup_category;
DROP FUNCTION IF EXISTS register_user;
DROP FUNCTION IF EXISTS lookup_user;
DROP TABLE IF EXISTS score_submission;
DROP TABLE IF EXISTS run_category;
DROP TABLE IF EXISTS "user";

CREATE TABLE "user" (
    id SERIAL PRIMARY KEY,
    discord_id BIGINT NOT NULL UNIQUE,
    discord_name VARCHAR(32) NOT NULL,
    discord_display_name VARCHAR(32) NOT NULL,
    discord_discriminator INTEGER NOT NULL,
    created_date TIMESTAMPTZ NOT NULL
);
ALTER SEQUENCE user_id_seq RESTART WITH 10000;

CREATE TABLE run_category (
    id SERIAL PRIMARY KEY,
    "name" VARCHAR(64) UNIQUE NOT NULL,
    display_name VARCHAR(64)
);
ALTER SEQUENCE run_category_id_seq RESTART WITH 10;

CREATE TABLE score_submission (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES "user"(id),
    category_id INTEGER NOT NULL REFERENCES run_category(id),
    score INTEGER NOT NULL,
    evidence_link VARCHAR(65536),
    created_date TIMESTAMPTZ NOT NULL
);
ALTER SEQUENCE score_submission_id_seq RESTART WITH 100000;

CREATE TABLE command (
    id SERIAL PRIMARY KEY,
    "name" VARCHAR(64) UNIQUE NOT NULL,
    help_text VARCHAR(65536)
);
ALTER SEQUENCE command_id_seq RESTART WITH 100;

INSERT INTO run_category ("name", display_name) VALUES 
    ('marathon', 'Marathon'),
    ('micro31', 'Micro 31'),
    ('killscreen', 'Killscreen'),
    ('single', 'Single Ship'),
    ('mil', 'Million Pts Race'),
    ('5man', 'Tournament'),
    ('pb', 'PB (any)');

INSERT INTO command ("name", help_text) VALUES
    ('submit', 'This command allows a user to register and update their personal best score in a given category with an optionally provided evidence link.\nUsage:\n\n!submit <category> <score> [evidence link]\n\nE.g. !submit micro31 123456 https://link-goes-here/\nUse !categories to list categories.');

CREATE OR REPLACE FUNCTION lookup_user(did BIGINT) RETURNS TABLE(id INTEGER, discord_id BIGINT, discord_name VARCHAR(32), discord_display_name VARCHAR(32), discord_discriminator INTEGER, created_date TIMESTAMPTZ) AS $lookup_user$
BEGIN
    RETURN QUERY SELECT * FROM "user" WHERE "user".discord_id = did;
END;
$lookup_user$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION register_user(did BIGINT, dname VARCHAR(64), ddisplay_name VARCHAR(64), disc INTEGER) RETURNS TABLE(id INTEGER, discord_id BIGINT, discord_name VARCHAR(32), discord_display_name VARCHAR(32), discord_discriminator INTEGER, created_date TIMESTAMPTZ) AS $register_user$
DECLARE 
    user_id INTEGER;
BEGIN
    INSERT INTO "user" (id, discord_id, discord_name, discord_display_name, discord_discriminator, created_date) VALUES
        (default, did, dname, ddisplay_name, disc, (SELECT CURRENT_TIMESTAMP AT TIME ZONE 'utc'))
    RETURNING "user".id INTO user_id;

    RETURN QUERY SELECT * FROM "user" WHERE "user".id = user_id;
END;
$register_user$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION lookup_category(cat VARCHAR(64)) RETURNS TABLE(id INTEGER, "name" VARCHAR(64)) AS $lookup_category$
BEGIN
    RETURN QUERY SELECT rc.id, rc."name" FROM run_category AS rc WHERE rc."name" = cat;
END;
$lookup_category$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION do_submission("uid" INTEGER, cat VARCHAR(64), sc INT, elink VARCHAR(65536)) RETURNS void AS $do_submission$
DECLARE
    cid INTEGER;
BEGIN
    -- Get the id for the provided category, if one exists
    SELECT id INTO cid FROM lookup_category(cat);

    -- Create the submission
    INSERT INTO score_submission(user_id, category_id, score, evidence_link, created_date) VALUES
        ("uid", cid, sc, elink, (SELECT CURRENT_TIMESTAMP AT TIME ZONE 'utc'));
END;
$do_submission$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_player_best_scores("uid" INTEGER) RETURNS TABLE(category VARCHAR(64), high_score INTEGER, evidence_link VARCHAR(65536)) AS $get_player_best_scores$
BEGIN
    RETURN QUERY SELECT rc.display_name, ss.score, ss.evidence_link
        FROM score_submission AS ss 
        JOIN run_category AS rc ON rc.id = ss.category_id
        INNER JOIN (
            SELECT ss2.category_id, MAX(ss2.score) AS max_score
            FROM score_submission AS ss2
            WHERE ss2.user_id = "uid"
            GROUP BY ss2.category_id
        ) b ON ss.category_id = b.category_id AND ss.score = b.max_score
        WHERE ss.user_id = "uid";
END;
$get_player_best_scores$ LANGUAGE plpgsql;