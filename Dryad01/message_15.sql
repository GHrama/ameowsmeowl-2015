--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

--
-- Name: msg; Type: TYPE; Schema: public; Owner: ramapriyasridharan
--

CREATE TYPE msg AS (
	message_id integer,
	sender_id integer,
	receiver_id integer,
	payload text,
	arrival_time timestamp without time zone
);


ALTER TYPE msg OWNER TO ramapriyasridharan;

--
-- Name: add_client(character varying); Type: FUNCTION; Schema: public; Owner: ramapriyasridharan
--

CREATE FUNCTION add_client(client_name character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$declare
result integer;
begin
insert into client_table(client_name) values(client_name) returning client_id as client_id into result;
return result;
end;$$;


ALTER FUNCTION public.add_client(client_name character varying) OWNER TO ramapriyasridharan;

--
-- Name: add_message(integer, integer, integer, text); Type: FUNCTION; Schema: public; Owner: ramapriyasridharan
--

CREATE FUNCTION add_message(_q_id integer, _s_id integer, _r_id integer, _p text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
declare
result integer;begin
insert into message_table(queue_id,sender_id,receiver_id,payload) values(_q_id,_s_id,_r_id,_p) returning message_id as message_id into result;
return result;
end;
$$;


ALTER FUNCTION public.add_message(_q_id integer, _s_id integer, _r_id integer, _p text) OWNER TO ramapriyasridharan;

--
-- Name: add_new_queue(character varying); Type: FUNCTION; Schema: public; Owner: ramapriyasridharan
--

CREATE FUNCTION add_new_queue(_queue_name character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$
declare
result integer;
begin
insert into queue_table(queue_name) values(_queue_name) returning queue_id as queue_id into result;
return result;
end;
$$;


ALTER FUNCTION public.add_new_queue(_queue_name character varying) OWNER TO ramapriyasridharan;

--
-- Name: delete_client(integer); Type: FUNCTION; Schema: public; Owner: ramapriyasridharan
--

CREATE FUNCTION delete_client(_client_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$BEGIN
delete from client_table where client_id=_client_id;
END;$$;


ALTER FUNCTION public.delete_client(_client_id integer) OWNER TO ramapriyasridharan;

--
-- Name: delete_queue(integer); Type: FUNCTION; Schema: public; Owner: ramapriyasridharan
--

CREATE FUNCTION delete_queue(_queue_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
delete from queue_table where queue_id=_queue_id;
END;
$$;


ALTER FUNCTION public.delete_queue(_queue_id integer) OWNER TO ramapriyasridharan;

--
-- Name: get_latest_message(integer, integer); Type: FUNCTION; Schema: public; Owner: ramapriyasridharan
--

CREATE FUNCTION get_latest_message(_queue_id integer, _receiver_id integer) RETURNS msg
    LANGUAGE plpgsql STABLE
    AS $$
declare r msg;
begin
select message_id,sender_id,receiver_id,payload,arrival_time into r.message_id,r.sender_id,r.receiver_id,r.payload,r.arrival_time from message_table 
where receiver_id in (_receiver_id,-1) and queue_id = _queue_id order by arrival_time desc limit 1;
return r;
end;
$$;


ALTER FUNCTION public.get_latest_message(_queue_id integer, _receiver_id integer) OWNER TO ramapriyasridharan;

--
-- Name: get_latest_message_delete(integer, integer); Type: FUNCTION; Schema: public; Owner: ramapriyasridharan
--

CREATE FUNCTION get_latest_message_delete(_queue_id integer, _receiver_id integer) RETURNS msg
    LANGUAGE plpgsql
    AS $$
declare
r msg;
begin
select message_id,sender_id,receiver_id,payload,arrival_time into r.message_id,r.sender_id,r.receiver_id,r.payload,r.arrival_time 
from message_table where receiver_id in (_receiver_id,-1) and queue_id = _queue_id order by arrival_time desc limit 1 for update ;
delete from message_table where message_id = r.message_id;
return r;
end;
$$;


ALTER FUNCTION public.get_latest_message_delete(_queue_id integer, _receiver_id integer) OWNER TO ramapriyasridharan;

--
-- Name: get_queues_with_messages(integer); Type: FUNCTION; Schema: public; Owner: ramapriyasridharan
--

CREATE FUNCTION get_queues_with_messages(_receiver_id integer) RETURNS SETOF integer
    LANGUAGE plpgsql STABLE
    AS $$
begin
RETURN QUERY
select distinct message_table.queue_id from message_table where receiver_id in (_receiver_id,-1);
end;
$$;


ALTER FUNCTION public.get_queues_with_messages(_receiver_id integer) OWNER TO ramapriyasridharan;

--
-- Name: in_cl(integer, character varying); Type: FUNCTION; Schema: public; Owner: ramapriyasridharan
--

CREATE FUNCTION in_cl(id integer, name character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
begin
insert into client_table(client_id,client_name) values(id,name);
end;
$$;


ALTER FUNCTION public.in_cl(id integer, name character varying) OWNER TO ramapriyasridharan;

--
-- Name: init_message(); Type: FUNCTION; Schema: public; Owner: ramapriyasridharan
--

CREATE FUNCTION init_message() RETURNS void
    LANGUAGE plpgsql
    AS $$
begin
alter sequence queue_table_queue_id_seq restart with 1;
delete from queue_table;
delete from message_table;
alter sequence client_table_client_id_seq restart with 1;
alter sequence message_table_message_id_seq restart with 1;
delete from client_table;
insert into client_table(client_id,client_name) values(-1,'b');
end;
$$;


ALTER FUNCTION public.init_message() OWNER TO ramapriyasridharan;

--
-- Name: latest_message_from_sender(integer, integer, integer); Type: FUNCTION; Schema: public; Owner: ramapriyasridharan
--

CREATE FUNCTION latest_message_from_sender(_queue_id integer, _receiver_id integer, _sender_id integer) RETURNS msg
    LANGUAGE plpgsql STABLE
    AS $$DECLARE
r msg;
BEGIN
SELECT message_id, sender_id, receiver_id, payload, arrival_time
INTO r.message_id, r.sender_id, r.receiver_id, r.payload, r.arrival_time
FROM message_table
WHERE receiver_id in (_receiver_id, -1) AND queue_id=_queue_id AND sender_id=_sender_id
ORDER BY arrival_time DESC
LIMIT 1;
RETURN r;
END;
$$;


ALTER FUNCTION public.latest_message_from_sender(_queue_id integer, _receiver_id integer, _sender_id integer) OWNER TO ramapriyasridharan;

--
-- Name: latest_message_from_sender_delete(integer, integer, integer); Type: FUNCTION; Schema: public; Owner: ramapriyasridharan
--

CREATE FUNCTION latest_message_from_sender_delete(_queue_id integer, _receiver_id integer, _sender_id integer) RETURNS msg
    LANGUAGE plpgsql
    AS $$DECLARE
r msg;
BEGIN
SELECT message_id, sender_id, receiver_id, payload, arrival_time
INTO r.message_id, r.sender_id, r.receiver_id, r.payload, r.arrival_time
FROM message_table
WHERE receiver_id in (_receiver_id, -1) AND queue_id=_queue_id AND sender_id=_sender_id
ORDER BY arrival_time DESC
LIMIT 1
FOR UPDATE;
DELETE FROM message_table
WHERE message_id=r.message_id;
RETURN r;
END;$$;


ALTER FUNCTION public.latest_message_from_sender_delete(_queue_id integer, _receiver_id integer, _sender_id integer) OWNER TO ramapriyasridharan;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: client_table; Type: TABLE; Schema: public; Owner: ramapriyasridharan; Tablespace: 
--

CREATE TABLE client_table (
    client_id integer NOT NULL,
    client_name character varying(50)
);


ALTER TABLE client_table OWNER TO ramapriyasridharan;

--
-- Name: client_table_client_id_seq; Type: SEQUENCE; Schema: public; Owner: ramapriyasridharan
--

CREATE SEQUENCE client_table_client_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE client_table_client_id_seq OWNER TO ramapriyasridharan;

--
-- Name: client_table_client_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ramapriyasridharan
--

ALTER SEQUENCE client_table_client_id_seq OWNED BY client_table.client_id;


--
-- Name: message_table; Type: TABLE; Schema: public; Owner: ramapriyasridharan; Tablespace: 
--

CREATE TABLE message_table (
    message_id integer NOT NULL,
    queue_id integer,
    sender_id integer NOT NULL,
    receiver_id integer NOT NULL,
    payload text NOT NULL,
    arrival_time timestamp without time zone DEFAULT now()
);


ALTER TABLE message_table OWNER TO ramapriyasridharan;

--
-- Name: message_table_message_id_seq; Type: SEQUENCE; Schema: public; Owner: ramapriyasridharan
--

CREATE SEQUENCE message_table_message_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE message_table_message_id_seq OWNER TO ramapriyasridharan;

--
-- Name: message_table_message_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ramapriyasridharan
--

ALTER SEQUENCE message_table_message_id_seq OWNED BY message_table.message_id;


--
-- Name: queue_table_queue_id_seq; Type: SEQUENCE; Schema: public; Owner: ramapriyasridharan
--

CREATE SEQUENCE queue_table_queue_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE queue_table_queue_id_seq OWNER TO ramapriyasridharan;

--
-- Name: queue_table; Type: TABLE; Schema: public; Owner: ramapriyasridharan; Tablespace: 
--

CREATE TABLE queue_table (
    queue_id integer DEFAULT nextval('queue_table_queue_id_seq'::regclass) NOT NULL,
    queue_name character varying(50)
);


ALTER TABLE queue_table OWNER TO ramapriyasridharan;

--
-- Name: client_id; Type: DEFAULT; Schema: public; Owner: ramapriyasridharan
--

ALTER TABLE ONLY client_table ALTER COLUMN client_id SET DEFAULT nextval('client_table_client_id_seq'::regclass);


--
-- Name: message_id; Type: DEFAULT; Schema: public; Owner: ramapriyasridharan
--

ALTER TABLE ONLY message_table ALTER COLUMN message_id SET DEFAULT nextval('message_table_message_id_seq'::regclass);


--
-- Data for Name: client_table; Type: TABLE DATA; Schema: public; Owner: ramapriyasridharan
--

COPY client_table (client_id, client_name) FROM stdin;
-1	b
\.


--
-- Name: client_table_client_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ramapriyasridharan
--

SELECT pg_catalog.setval('client_table_client_id_seq', 1, false);


--
-- Data for Name: message_table; Type: TABLE DATA; Schema: public; Owner: ramapriyasridharan
--

COPY message_table (message_id, queue_id, sender_id, receiver_id, payload, arrival_time) FROM stdin;
\.


--
-- Name: message_table_message_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ramapriyasridharan
--

SELECT pg_catalog.setval('message_table_message_id_seq', 1, false);


--
-- Data for Name: queue_table; Type: TABLE DATA; Schema: public; Owner: ramapriyasridharan
--

COPY queue_table (queue_id, queue_name) FROM stdin;
\.


--
-- Name: queue_table_queue_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ramapriyasridharan
--

SELECT pg_catalog.setval('queue_table_queue_id_seq', 1, false);


--
-- Name: client_table_client_name_key; Type: CONSTRAINT; Schema: public; Owner: ramapriyasridharan; Tablespace: 
--

ALTER TABLE ONLY client_table
    ADD CONSTRAINT client_table_client_name_key UNIQUE (client_name);


--
-- Name: client_table_pkey; Type: CONSTRAINT; Schema: public; Owner: ramapriyasridharan; Tablespace: 
--

ALTER TABLE ONLY client_table
    ADD CONSTRAINT client_table_pkey PRIMARY KEY (client_id);


--
-- Name: message_table_pkey; Type: CONSTRAINT; Schema: public; Owner: ramapriyasridharan; Tablespace: 
--

ALTER TABLE ONLY message_table
    ADD CONSTRAINT message_table_pkey PRIMARY KEY (message_id);


--
-- Name: queue_table_pkey; Type: CONSTRAINT; Schema: public; Owner: ramapriyasridharan; Tablespace: 
--

ALTER TABLE ONLY queue_table
    ADD CONSTRAINT queue_table_pkey PRIMARY KEY (queue_id);


--
-- Name: all_msgs_gv_receiver_queue; Type: INDEX; Schema: public; Owner: ramapriyasridharan; Tablespace: 
--

CREATE INDEX all_msgs_gv_receiver_queue ON message_table USING btree (receiver_id, queue_id);


--
-- Name: latest_msg_gv_receiver; Type: INDEX; Schema: public; Owner: ramapriyasridharan; Tablespace: 
--

CREATE INDEX latest_msg_gv_receiver ON message_table USING btree (receiver_id, arrival_time);


--
-- Name: latest_msg_gv_sender; Type: INDEX; Schema: public; Owner: ramapriyasridharan; Tablespace: 
--

CREATE INDEX latest_msg_gv_sender ON message_table USING btree (receiver_id, sender_id, arrival_time);


--
-- Name: message_table_queue_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ramapriyasridharan
--

ALTER TABLE ONLY message_table
    ADD CONSTRAINT message_table_queue_id_fkey FOREIGN KEY (queue_id) REFERENCES queue_table(queue_id) ON DELETE CASCADE;


--
-- Name: message_table_receiver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ramapriyasridharan
--

ALTER TABLE ONLY message_table
    ADD CONSTRAINT message_table_receiver_id_fkey FOREIGN KEY (receiver_id) REFERENCES client_table(client_id);


--
-- Name: message_table_sender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ramapriyasridharan
--

ALTER TABLE ONLY message_table
    ADD CONSTRAINT message_table_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES client_table(client_id);


--
-- Name: public; Type: ACL; Schema: -; Owner: ramapriyasridharan
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM ramapriyasridharan;
GRANT ALL ON SCHEMA public TO ramapriyasridharan;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- Name: client_table; Type: ACL; Schema: public; Owner: ramapriyasridharan
--

REVOKE ALL ON TABLE client_table FROM PUBLIC;
REVOKE ALL ON TABLE client_table FROM ramapriyasridharan;
GRANT ALL ON TABLE client_table TO ramapriyasridharan;
GRANT ALL ON TABLE client_table TO rama;


--
-- Name: client_table_client_id_seq; Type: ACL; Schema: public; Owner: ramapriyasridharan
--

REVOKE ALL ON SEQUENCE client_table_client_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE client_table_client_id_seq FROM ramapriyasridharan;
GRANT ALL ON SEQUENCE client_table_client_id_seq TO ramapriyasridharan;
GRANT ALL ON SEQUENCE client_table_client_id_seq TO rama;


--
-- Name: message_table; Type: ACL; Schema: public; Owner: ramapriyasridharan
--

REVOKE ALL ON TABLE message_table FROM PUBLIC;
REVOKE ALL ON TABLE message_table FROM ramapriyasridharan;
GRANT ALL ON TABLE message_table TO ramapriyasridharan;
GRANT ALL ON TABLE message_table TO rama;


--
-- Name: message_table_message_id_seq; Type: ACL; Schema: public; Owner: ramapriyasridharan
--

REVOKE ALL ON SEQUENCE message_table_message_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE message_table_message_id_seq FROM ramapriyasridharan;
GRANT ALL ON SEQUENCE message_table_message_id_seq TO ramapriyasridharan;
GRANT ALL ON SEQUENCE message_table_message_id_seq TO rama;


--
-- Name: queue_table_queue_id_seq; Type: ACL; Schema: public; Owner: ramapriyasridharan
--

REVOKE ALL ON SEQUENCE queue_table_queue_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE queue_table_queue_id_seq FROM ramapriyasridharan;
GRANT ALL ON SEQUENCE queue_table_queue_id_seq TO ramapriyasridharan;
GRANT ALL ON SEQUENCE queue_table_queue_id_seq TO rama;


--
-- Name: queue_table; Type: ACL; Schema: public; Owner: ramapriyasridharan
--

REVOKE ALL ON TABLE queue_table FROM PUBLIC;
REVOKE ALL ON TABLE queue_table FROM ramapriyasridharan;
GRANT ALL ON TABLE queue_table TO ramapriyasridharan;
GRANT ALL ON TABLE queue_table TO rama;


--
-- PostgreSQL database dump complete
--

