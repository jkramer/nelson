--
-- PostgreSQL database dump
--

SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

SET search_path = public, pg_catalog;

--
-- Name: seqassignid; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE seqassignid
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: assign; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE assign (
    id bigint DEFAULT nextval('seqassignid'::regclass) NOT NULL,
    "user" character varying(28) NOT NULL,
    key character varying(64) NOT NULL,
    value character varying(512) NOT NULL,
    "when" timestamp without time zone DEFAULT now(),
    revision integer DEFAULT 0 NOT NULL
);


--
-- Name: score; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE score (
    key character varying(128) NOT NULL,
    score integer NOT NULL
);


--
-- Name: scrobble; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE scrobble (
    "user" character varying(28) NOT NULL,
    login character varying(28) NOT NULL,
    "time" bigint DEFAULT 0,
    track character varying(128) DEFAULT ''::character varying
);


--
-- Name: TOTAL(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION "TOTAL"() RETURNS bigint
    AS $$
SELECT (SELECT COUNT(*) FROM "assign") + (SELECT COUNT(*) FROM "dump") + (SELECT COUNT(*) FROM "score");
$$
    LANGUAGE sql;


--
-- Name: assign_key_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY assign
    ADD CONSTRAINT assign_key_key UNIQUE (key, revision);


--
-- Name: assign_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY assign
    ADD CONSTRAINT assign_pkey PRIMARY KEY (id);


--
-- Name: score_key_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY score
    ADD CONSTRAINT score_key_key UNIQUE (key);


--
-- Name: scrobble_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY scrobble
    ADD CONSTRAINT scrobble_pkey PRIMARY KEY ("user");


--
-- Name: public; Type: ACL; Schema: -; Owner: -
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

