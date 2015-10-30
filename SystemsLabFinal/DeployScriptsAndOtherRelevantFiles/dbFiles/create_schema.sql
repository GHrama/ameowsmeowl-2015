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
-- Name: msg; Type: TYPE; Schema: public; Owner: rsridhar
--

CREATE TYPE msg AS (
	message_id integer,
	sender_id integer,
	receiver_id integer,
	payload text,
	arrival_time timestamp without time zone
);


ALTER TYPE msg OWNER TO rsridhar;

--
-- Name: add_client(character varying); Type: FUNCTION; Schema: public; Owner: rsridhar
--

CREATE FUNCTION add_client(client_name character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$declare
result integer;
begin
insert into client_table(client_name) values(client_name) returning client_id as client_id into result;
return result;
end;$$;


ALTER FUNCTION public.add_client(client_name character varying) OWNER TO rsridhar;

--
-- Name: add_message(integer, integer, integer, text); Type: FUNCTION; Schema: public; Owner: rsridhar
--

CREATE FUNCTION add_message(_q_id integer, _s_id integer, _r_id integer, _p text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
declare
result integer;
temp1 integer;
begin
insert into message_table(queue_id,sender_id,receiver_id,payload) values(_q_id,_s_id,_r_id,_p) returning message_id as message_id into result;
return result;
end;
$$;


ALTER FUNCTION public.add_message(_q_id integer, _s_id integer, _r_id integer, _p text) OWNER TO rsridhar;

--
-- Name: add_new_queue(character varying); Type: FUNCTION; Schema: public; Owner: rsridhar
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


ALTER FUNCTION public.add_new_queue(_queue_name character varying) OWNER TO rsridhar;

--
-- Name: delete_client(integer); Type: FUNCTION; Schema: public; Owner: rsridhar
--

CREATE FUNCTION delete_client(_client_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$BEGIN
delete from client_table where client_id=_client_id;
END;$$;


ALTER FUNCTION public.delete_client(_client_id integer) OWNER TO rsridhar;

--
-- Name: delete_queue(integer); Type: FUNCTION; Schema: public; Owner: rsridhar
--

CREATE FUNCTION delete_queue(_queue_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
delete from queue_table where queue_id=_queue_id;
END;
$$;


ALTER FUNCTION public.delete_queue(_queue_id integer) OWNER TO rsridhar;

--
-- Name: get_latest_message(integer, integer); Type: FUNCTION; Schema: public; Owner: rsridhar
--

CREATE FUNCTION get_latest_message(_queue_id integer, _receiver_id integer) RETURNS msg
    LANGUAGE plpgsql STABLE
    AS $$
declare 

r msg;
begin
select message_id,sender_id,receiver_id,payload,arrival_time into r.message_id,r.sender_id,r.receiver_id,r.payload,r.arrival_time from message_table 
where receiver_id in (_receiver_id,-1) and queue_id = _queue_id order by arrival_time desc limit 1;

return r;
end;
$$;


ALTER FUNCTION public.get_latest_message(_queue_id integer, _receiver_id integer) OWNER TO rsridhar;

--
-- Name: get_latest_message_delete(integer, integer); Type: FUNCTION; Schema: public; Owner: rsridhar
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


ALTER FUNCTION public.get_latest_message_delete(_queue_id integer, _receiver_id integer) OWNER TO rsridhar;

--
-- Name: get_queues_with_messages(integer); Type: FUNCTION; Schema: public; Owner: rsridhar
--

CREATE FUNCTION get_queues_with_messages(_receiver_id integer) RETURNS SETOF integer
    LANGUAGE plpgsql STABLE
    AS $$
begin
RETURN QUERY
select distinct message_table.queue_id from message_table where receiver_id in (_receiver_id,-1);
end;
$$;


ALTER FUNCTION public.get_queues_with_messages(_receiver_id integer) OWNER TO rsridhar;

--
-- Name: in_cl(integer, character varying); Type: FUNCTION; Schema: public; Owner: rsridhar
--

CREATE FUNCTION in_cl(id integer, name character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
begin
insert into client_table(client_id,client_name) values(id,name);
end;
$$;


ALTER FUNCTION public.in_cl(id integer, name character varying) OWNER TO rsridhar;

--
-- Name: init_message(); Type: FUNCTION; Schema: public; Owner: rsridhar
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

FOR i in 1..400 LOOP
insert into client_table(client_id,client_name) values(i,'client');
insert into queue_table(queue_id,queue_name) values(i,'queue');
END LOOP;

FOR i IN 1..250 LOOP
IF (i <= 100) THEN
insert into message_table(queue_id,sender_id,receiver_id,payload) values(i,i,i,'A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c');
ELSIF (i <= 200) THEN
insert into message_table(queue_id,sender_id,receiver_id,payload) values(i-100,i,i,'A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c');
ELSE
insert into message_table(queue_id,sender_id,receiver_id,payload) values(i-200,i,i,'A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c');
END IF;
end LOOP;
end;
$$;


ALTER FUNCTION public.init_message() OWNER TO rsridhar;

--
-- Name: latest_message_from_sender(integer, integer, integer); Type: FUNCTION; Schema: public; Owner: rsridhar
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


ALTER FUNCTION public.latest_message_from_sender(_queue_id integer, _receiver_id integer, _sender_id integer) OWNER TO rsridhar;

--
-- Name: latest_message_from_sender_delete(integer, integer, integer); Type: FUNCTION; Schema: public; Owner: rsridhar
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


ALTER FUNCTION public.latest_message_from_sender_delete(_queue_id integer, _receiver_id integer, _sender_id integer) OWNER TO rsridhar;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: client_table; Type: TABLE; Schema: public; Owner: rsridhar; Tablespace: 
--

CREATE TABLE client_table (
    client_id integer NOT NULL,
    client_name character varying(50)
);


ALTER TABLE client_table OWNER TO rsridhar;

--
-- Name: client_table_client_id_seq; Type: SEQUENCE; Schema: public; Owner: rsridhar
--

CREATE SEQUENCE client_table_client_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE client_table_client_id_seq OWNER TO rsridhar;

--
-- Name: client_table_client_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: rsridhar
--

ALTER SEQUENCE client_table_client_id_seq OWNED BY client_table.client_id;


--
-- Name: message_table; Type: TABLE; Schema: public; Owner: rsridhar; Tablespace: 
--

CREATE TABLE message_table (
    message_id integer NOT NULL,
    queue_id integer,
    sender_id integer NOT NULL,
    receiver_id integer NOT NULL,
    payload text NOT NULL,
    arrival_time timestamp without time zone DEFAULT now()
);


ALTER TABLE message_table OWNER TO rsridhar;

--
-- Name: message_table_message_id_seq; Type: SEQUENCE; Schema: public; Owner: rsridhar
--

CREATE SEQUENCE message_table_message_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE message_table_message_id_seq OWNER TO rsridhar;

--
-- Name: message_table_message_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: rsridhar
--

ALTER SEQUENCE message_table_message_id_seq OWNED BY message_table.message_id;


--
-- Name: queue_table_queue_id_seq; Type: SEQUENCE; Schema: public; Owner: rsridhar
--

CREATE SEQUENCE queue_table_queue_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE queue_table_queue_id_seq OWNER TO rsridhar;

--
-- Name: queue_table; Type: TABLE; Schema: public; Owner: rsridhar; Tablespace: 
--

CREATE TABLE queue_table (
    queue_id integer DEFAULT nextval('queue_table_queue_id_seq'::regclass) NOT NULL,
    queue_name character varying(50)
);


ALTER TABLE queue_table OWNER TO rsridhar;

--
-- Name: client_id; Type: DEFAULT; Schema: public; Owner: rsridhar
--

ALTER TABLE ONLY client_table ALTER COLUMN client_id SET DEFAULT nextval('client_table_client_id_seq'::regclass);


--
-- Name: message_id; Type: DEFAULT; Schema: public; Owner: rsridhar
--

ALTER TABLE ONLY message_table ALTER COLUMN message_id SET DEFAULT nextval('message_table_message_id_seq'::regclass);


--
-- Data for Name: client_table; Type: TABLE DATA; Schema: public; Owner: rsridhar
--

COPY client_table (client_id, client_name) FROM stdin;
-1	b
1	client
2	client
3	client
4	client
5	client
6	client
7	client
8	client
9	client
10	client
11	client
12	client
13	client
14	client
15	client
16	client
17	client
18	client
19	client
20	client
21	client
22	client
23	client
24	client
25	client
26	client
27	client
28	client
29	client
30	client
31	client
32	client
33	client
34	client
35	client
36	client
37	client
38	client
39	client
40	client
41	client
42	client
43	client
44	client
45	client
46	client
47	client
48	client
49	client
50	client
51	client
52	client
53	client
54	client
55	client
56	client
57	client
58	client
59	client
60	client
61	client
62	client
63	client
64	client
65	client
66	client
67	client
68	client
69	client
70	client
71	client
72	client
73	client
74	client
75	client
76	client
77	client
78	client
79	client
80	client
81	client
82	client
83	client
84	client
85	client
86	client
87	client
88	client
89	client
90	client
91	client
92	client
93	client
94	client
95	client
96	client
97	client
98	client
99	client
100	client
101	client
102	client
103	client
104	client
105	client
106	client
107	client
108	client
109	client
110	client
111	client
112	client
113	client
114	client
115	client
116	client
117	client
118	client
119	client
120	client
121	client
122	client
123	client
124	client
125	client
126	client
127	client
128	client
129	client
130	client
131	client
132	client
133	client
134	client
135	client
136	client
137	client
138	client
139	client
140	client
141	client
142	client
143	client
144	client
145	client
146	client
147	client
148	client
149	client
150	client
151	client
152	client
153	client
154	client
155	client
156	client
157	client
158	client
159	client
160	client
161	client
162	client
163	client
164	client
165	client
166	client
167	client
168	client
169	client
170	client
171	client
172	client
173	client
174	client
175	client
176	client
177	client
178	client
179	client
180	client
181	client
182	client
183	client
184	client
185	client
186	client
187	client
188	client
189	client
190	client
191	client
192	client
193	client
194	client
195	client
196	client
197	client
198	client
199	client
200	client
201	client
202	client
203	client
204	client
205	client
206	client
207	client
208	client
209	client
210	client
211	client
212	client
213	client
214	client
215	client
216	client
217	client
218	client
219	client
220	client
221	client
222	client
223	client
224	client
225	client
226	client
227	client
228	client
229	client
230	client
231	client
232	client
233	client
234	client
235	client
236	client
237	client
238	client
239	client
240	client
241	client
242	client
243	client
244	client
245	client
246	client
247	client
248	client
249	client
250	client
251	client
252	client
253	client
254	client
255	client
256	client
257	client
258	client
259	client
260	client
261	client
262	client
263	client
264	client
265	client
266	client
267	client
268	client
269	client
270	client
271	client
272	client
273	client
274	client
275	client
276	client
277	client
278	client
279	client
280	client
281	client
282	client
283	client
284	client
285	client
286	client
287	client
288	client
289	client
290	client
291	client
292	client
293	client
294	client
295	client
296	client
297	client
298	client
299	client
300	client
301	client
302	client
303	client
304	client
305	client
306	client
307	client
308	client
309	client
310	client
311	client
312	client
313	client
314	client
315	client
316	client
317	client
318	client
319	client
320	client
321	client
322	client
323	client
324	client
325	client
326	client
327	client
328	client
329	client
330	client
331	client
332	client
333	client
334	client
335	client
336	client
337	client
338	client
339	client
340	client
341	client
342	client
343	client
344	client
345	client
346	client
347	client
348	client
349	client
350	client
351	client
352	client
353	client
354	client
355	client
356	client
357	client
358	client
359	client
360	client
361	client
362	client
363	client
364	client
365	client
366	client
367	client
368	client
369	client
370	client
371	client
372	client
373	client
374	client
375	client
376	client
377	client
378	client
379	client
380	client
381	client
382	client
383	client
384	client
385	client
386	client
387	client
388	client
389	client
390	client
391	client
392	client
393	client
394	client
395	client
396	client
397	client
398	client
399	client
400	client
\.


--
-- Name: client_table_client_id_seq; Type: SEQUENCE SET; Schema: public; Owner: rsridhar
--

SELECT pg_catalog.setval('client_table_client_id_seq', 1, false);


--
-- Data for Name: message_table; Type: TABLE DATA; Schema: public; Owner: rsridhar
--

COPY message_table (message_id, queue_id, sender_id, receiver_id, payload, arrival_time) FROM stdin;
1	1	1	1	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
2	2	2	2	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
3	3	3	3	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
4	4	4	4	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
5	5	5	5	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
6	6	6	6	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
7	7	7	7	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
8	8	8	8	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
9	9	9	9	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
10	10	10	10	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
11	11	11	11	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
12	12	12	12	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
13	13	13	13	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
14	14	14	14	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
15	15	15	15	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
16	16	16	16	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
17	17	17	17	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
18	18	18	18	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
19	19	19	19	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
20	20	20	20	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
21	21	21	21	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
22	22	22	22	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
23	23	23	23	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
24	24	24	24	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
25	25	25	25	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
26	26	26	26	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
27	27	27	27	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
28	28	28	28	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
29	29	29	29	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
30	30	30	30	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
31	31	31	31	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
32	32	32	32	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
33	33	33	33	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
34	34	34	34	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
35	35	35	35	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
36	36	36	36	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
37	37	37	37	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
38	38	38	38	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
39	39	39	39	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
40	40	40	40	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
41	41	41	41	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
42	42	42	42	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
43	43	43	43	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
44	44	44	44	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
45	45	45	45	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
46	46	46	46	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
47	47	47	47	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
48	48	48	48	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
49	49	49	49	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
50	50	50	50	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
51	51	51	51	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
52	52	52	52	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
53	53	53	53	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
54	54	54	54	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
55	55	55	55	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
56	56	56	56	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
57	57	57	57	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
58	58	58	58	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
59	59	59	59	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
60	60	60	60	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
61	61	61	61	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
62	62	62	62	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
63	63	63	63	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
64	64	64	64	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
65	65	65	65	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
66	66	66	66	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
67	67	67	67	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
68	68	68	68	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
69	69	69	69	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
70	70	70	70	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
71	71	71	71	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
72	72	72	72	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
73	73	73	73	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
74	74	74	74	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
75	75	75	75	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
76	76	76	76	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
77	77	77	77	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
78	78	78	78	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
79	79	79	79	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
80	80	80	80	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
81	81	81	81	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
82	82	82	82	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
83	83	83	83	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
84	84	84	84	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
85	85	85	85	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
86	86	86	86	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
87	87	87	87	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
88	88	88	88	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
89	89	89	89	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
90	90	90	90	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
91	91	91	91	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
92	92	92	92	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
93	93	93	93	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
94	94	94	94	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
95	95	95	95	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
96	96	96	96	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
97	97	97	97	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
98	98	98	98	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
99	99	99	99	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
100	100	100	100	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
101	1	101	101	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
102	2	102	102	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
103	3	103	103	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
104	4	104	104	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
105	5	105	105	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
106	6	106	106	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
107	7	107	107	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
108	8	108	108	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
109	9	109	109	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
110	10	110	110	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
111	11	111	111	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
112	12	112	112	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
113	13	113	113	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
114	14	114	114	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
115	15	115	115	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
116	16	116	116	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
117	17	117	117	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
118	18	118	118	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
119	19	119	119	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
120	20	120	120	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
121	21	121	121	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
122	22	122	122	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
123	23	123	123	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
124	24	124	124	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
125	25	125	125	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
126	26	126	126	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
127	27	127	127	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
128	28	128	128	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
129	29	129	129	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
130	30	130	130	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
131	31	131	131	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
132	32	132	132	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
133	33	133	133	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
134	34	134	134	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
135	35	135	135	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
136	36	136	136	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
137	37	137	137	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
138	38	138	138	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
139	39	139	139	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
140	40	140	140	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
141	41	141	141	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
142	42	142	142	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
143	43	143	143	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
144	44	144	144	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
145	45	145	145	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
146	46	146	146	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
147	47	147	147	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
148	48	148	148	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
149	49	149	149	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
150	50	150	150	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
151	51	151	151	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
152	52	152	152	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
153	53	153	153	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
154	54	154	154	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
155	55	155	155	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
156	56	156	156	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
157	57	157	157	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
158	58	158	158	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
159	59	159	159	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
160	60	160	160	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
161	61	161	161	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
162	62	162	162	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
163	63	163	163	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
164	64	164	164	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
165	65	165	165	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
166	66	166	166	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
167	67	167	167	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
168	68	168	168	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
169	69	169	169	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
170	70	170	170	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
171	71	171	171	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
172	72	172	172	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
173	73	173	173	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
174	74	174	174	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
175	75	175	175	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
176	76	176	176	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
177	77	177	177	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
178	78	178	178	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
179	79	179	179	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
180	80	180	180	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
181	81	181	181	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
182	82	182	182	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
183	83	183	183	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
184	84	184	184	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
185	85	185	185	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
186	86	186	186	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
187	87	187	187	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
188	88	188	188	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
189	89	189	189	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
190	90	190	190	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
191	91	191	191	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
192	92	192	192	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
193	93	193	193	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
194	94	194	194	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
195	95	195	195	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
196	96	196	196	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
197	97	197	197	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
198	98	198	198	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
199	99	199	199	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
200	100	200	200	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
201	1	201	201	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
202	2	202	202	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
203	3	203	203	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
204	4	204	204	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
205	5	205	205	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
206	6	206	206	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
207	7	207	207	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
208	8	208	208	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
209	9	209	209	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
210	10	210	210	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
211	11	211	211	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
212	12	212	212	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
213	13	213	213	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
214	14	214	214	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
215	15	215	215	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
216	16	216	216	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
217	17	217	217	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
218	18	218	218	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
219	19	219	219	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
220	20	220	220	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
221	21	221	221	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
222	22	222	222	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
223	23	223	223	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
224	24	224	224	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
225	25	225	225	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
226	26	226	226	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
227	27	227	227	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
228	28	228	228	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
229	29	229	229	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
230	30	230	230	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
231	31	231	231	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
232	32	232	232	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
233	33	233	233	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
234	34	234	234	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
235	35	235	235	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
236	36	236	236	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
237	37	237	237	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
238	38	238	238	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
239	39	239	239	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
240	40	240	240	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
241	41	241	241	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
242	42	242	242	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
243	43	243	243	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
244	44	244	244	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
245	45	245	245	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
246	46	246	246	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
247	47	247	247	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
248	48	248	248	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
249	49	249	249	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
250	50	250	250	A5YNchaHyiDUHFi4yxDDyANcu2De5amt5NhOGNalGklz3AmzxtZ9BERLeRt8ABQT8iNYnO7wkRRLJszvK3G9RiCgwGNDfGfoECzloTxi7Pm4blxbfYLf1MQM14CboYwJwtGhHygY15gxBkOQEyhjxXs5X5coCqu6IqfoL77PbDGsZJtGuCbTG3Je2QheTbvqkq0c6C2c	2015-10-27 12:50:34.219292
\.


--
-- Name: message_table_message_id_seq; Type: SEQUENCE SET; Schema: public; Owner: rsridhar
--

SELECT pg_catalog.setval('message_table_message_id_seq', 250, true);


--
-- Data for Name: queue_table; Type: TABLE DATA; Schema: public; Owner: rsridhar
--

COPY queue_table (queue_id, queue_name) FROM stdin;
1	queue
2	queue
3	queue
4	queue
5	queue
6	queue
7	queue
8	queue
9	queue
10	queue
11	queue
12	queue
13	queue
14	queue
15	queue
16	queue
17	queue
18	queue
19	queue
20	queue
21	queue
22	queue
23	queue
24	queue
25	queue
26	queue
27	queue
28	queue
29	queue
30	queue
31	queue
32	queue
33	queue
34	queue
35	queue
36	queue
37	queue
38	queue
39	queue
40	queue
41	queue
42	queue
43	queue
44	queue
45	queue
46	queue
47	queue
48	queue
49	queue
50	queue
51	queue
52	queue
53	queue
54	queue
55	queue
56	queue
57	queue
58	queue
59	queue
60	queue
61	queue
62	queue
63	queue
64	queue
65	queue
66	queue
67	queue
68	queue
69	queue
70	queue
71	queue
72	queue
73	queue
74	queue
75	queue
76	queue
77	queue
78	queue
79	queue
80	queue
81	queue
82	queue
83	queue
84	queue
85	queue
86	queue
87	queue
88	queue
89	queue
90	queue
91	queue
92	queue
93	queue
94	queue
95	queue
96	queue
97	queue
98	queue
99	queue
100	queue
101	queue
102	queue
103	queue
104	queue
105	queue
106	queue
107	queue
108	queue
109	queue
110	queue
111	queue
112	queue
113	queue
114	queue
115	queue
116	queue
117	queue
118	queue
119	queue
120	queue
121	queue
122	queue
123	queue
124	queue
125	queue
126	queue
127	queue
128	queue
129	queue
130	queue
131	queue
132	queue
133	queue
134	queue
135	queue
136	queue
137	queue
138	queue
139	queue
140	queue
141	queue
142	queue
143	queue
144	queue
145	queue
146	queue
147	queue
148	queue
149	queue
150	queue
151	queue
152	queue
153	queue
154	queue
155	queue
156	queue
157	queue
158	queue
159	queue
160	queue
161	queue
162	queue
163	queue
164	queue
165	queue
166	queue
167	queue
168	queue
169	queue
170	queue
171	queue
172	queue
173	queue
174	queue
175	queue
176	queue
177	queue
178	queue
179	queue
180	queue
181	queue
182	queue
183	queue
184	queue
185	queue
186	queue
187	queue
188	queue
189	queue
190	queue
191	queue
192	queue
193	queue
194	queue
195	queue
196	queue
197	queue
198	queue
199	queue
200	queue
201	queue
202	queue
203	queue
204	queue
205	queue
206	queue
207	queue
208	queue
209	queue
210	queue
211	queue
212	queue
213	queue
214	queue
215	queue
216	queue
217	queue
218	queue
219	queue
220	queue
221	queue
222	queue
223	queue
224	queue
225	queue
226	queue
227	queue
228	queue
229	queue
230	queue
231	queue
232	queue
233	queue
234	queue
235	queue
236	queue
237	queue
238	queue
239	queue
240	queue
241	queue
242	queue
243	queue
244	queue
245	queue
246	queue
247	queue
248	queue
249	queue
250	queue
251	queue
252	queue
253	queue
254	queue
255	queue
256	queue
257	queue
258	queue
259	queue
260	queue
261	queue
262	queue
263	queue
264	queue
265	queue
266	queue
267	queue
268	queue
269	queue
270	queue
271	queue
272	queue
273	queue
274	queue
275	queue
276	queue
277	queue
278	queue
279	queue
280	queue
281	queue
282	queue
283	queue
284	queue
285	queue
286	queue
287	queue
288	queue
289	queue
290	queue
291	queue
292	queue
293	queue
294	queue
295	queue
296	queue
297	queue
298	queue
299	queue
300	queue
301	queue
302	queue
303	queue
304	queue
305	queue
306	queue
307	queue
308	queue
309	queue
310	queue
311	queue
312	queue
313	queue
314	queue
315	queue
316	queue
317	queue
318	queue
319	queue
320	queue
321	queue
322	queue
323	queue
324	queue
325	queue
326	queue
327	queue
328	queue
329	queue
330	queue
331	queue
332	queue
333	queue
334	queue
335	queue
336	queue
337	queue
338	queue
339	queue
340	queue
341	queue
342	queue
343	queue
344	queue
345	queue
346	queue
347	queue
348	queue
349	queue
350	queue
351	queue
352	queue
353	queue
354	queue
355	queue
356	queue
357	queue
358	queue
359	queue
360	queue
361	queue
362	queue
363	queue
364	queue
365	queue
366	queue
367	queue
368	queue
369	queue
370	queue
371	queue
372	queue
373	queue
374	queue
375	queue
376	queue
377	queue
378	queue
379	queue
380	queue
381	queue
382	queue
383	queue
384	queue
385	queue
386	queue
387	queue
388	queue
389	queue
390	queue
391	queue
392	queue
393	queue
394	queue
395	queue
396	queue
397	queue
398	queue
399	queue
400	queue
\.


--
-- Name: queue_table_queue_id_seq; Type: SEQUENCE SET; Schema: public; Owner: rsridhar
--

SELECT pg_catalog.setval('queue_table_queue_id_seq', 1, false);


--
-- Name: client_table_pkey; Type: CONSTRAINT; Schema: public; Owner: rsridhar; Tablespace: 
--

ALTER TABLE ONLY client_table
    ADD CONSTRAINT client_table_pkey PRIMARY KEY (client_id);


--
-- Name: message_table_pkey; Type: CONSTRAINT; Schema: public; Owner: rsridhar; Tablespace: 
--

ALTER TABLE ONLY message_table
    ADD CONSTRAINT message_table_pkey PRIMARY KEY (message_id);


--
-- Name: queue_table_pkey; Type: CONSTRAINT; Schema: public; Owner: rsridhar; Tablespace: 
--

ALTER TABLE ONLY queue_table
    ADD CONSTRAINT queue_table_pkey PRIMARY KEY (queue_id);


--
-- Name: all_msgs_gv_receiver_queue; Type: INDEX; Schema: public; Owner: rsridhar; Tablespace: 
--

CREATE INDEX all_msgs_gv_receiver_queue ON message_table USING btree (receiver_id, queue_id);


--
-- Name: latest_msg_gv_receiver; Type: INDEX; Schema: public; Owner: rsridhar; Tablespace: 
--

CREATE INDEX latest_msg_gv_receiver ON message_table USING btree (receiver_id, arrival_time);


--
-- Name: latest_msg_gv_sender; Type: INDEX; Schema: public; Owner: rsridhar; Tablespace: 
--

CREATE INDEX latest_msg_gv_sender ON message_table USING btree (receiver_id, sender_id, arrival_time);


--
-- Name: message_table_queue_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: rsridhar
--

ALTER TABLE ONLY message_table
    ADD CONSTRAINT message_table_queue_id_fkey FOREIGN KEY (queue_id) REFERENCES queue_table(queue_id) ON DELETE CASCADE;


--
-- Name: message_table_receiver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: rsridhar
--

ALTER TABLE ONLY message_table
    ADD CONSTRAINT message_table_receiver_id_fkey FOREIGN KEY (receiver_id) REFERENCES client_table(client_id);


--
-- Name: message_table_sender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: rsridhar
--

ALTER TABLE ONLY message_table
    ADD CONSTRAINT message_table_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES client_table(client_id);


--
-- Name: public; Type: ACL; Schema: -; Owner: rsridhar
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM rsridhar;
GRANT ALL ON SCHEMA public TO rsridhar;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- Name: client_table; Type: ACL; Schema: public; Owner: rsridhar
--

REVOKE ALL ON TABLE client_table FROM PUBLIC;
REVOKE ALL ON TABLE client_table FROM rsridhar;
GRANT ALL ON TABLE client_table TO rsridhar;
GRANT ALL ON TABLE client_table TO rama;


--
-- Name: client_table_client_id_seq; Type: ACL; Schema: public; Owner: rsridhar
--

REVOKE ALL ON SEQUENCE client_table_client_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE client_table_client_id_seq FROM rsridhar;
GRANT ALL ON SEQUENCE client_table_client_id_seq TO rsridhar;
GRANT ALL ON SEQUENCE client_table_client_id_seq TO rama;


--
-- Name: message_table; Type: ACL; Schema: public; Owner: rsridhar
--

REVOKE ALL ON TABLE message_table FROM PUBLIC;
REVOKE ALL ON TABLE message_table FROM rsridhar;
GRANT ALL ON TABLE message_table TO rsridhar;
GRANT ALL ON TABLE message_table TO rama;


--
-- Name: message_table_message_id_seq; Type: ACL; Schema: public; Owner: rsridhar
--

REVOKE ALL ON SEQUENCE message_table_message_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE message_table_message_id_seq FROM rsridhar;
GRANT ALL ON SEQUENCE message_table_message_id_seq TO rsridhar;
GRANT ALL ON SEQUENCE message_table_message_id_seq TO rama;


--
-- Name: queue_table_queue_id_seq; Type: ACL; Schema: public; Owner: rsridhar
--

REVOKE ALL ON SEQUENCE queue_table_queue_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE queue_table_queue_id_seq FROM rsridhar;
GRANT ALL ON SEQUENCE queue_table_queue_id_seq TO rsridhar;
GRANT ALL ON SEQUENCE queue_table_queue_id_seq TO rama;


--
-- Name: queue_table; Type: ACL; Schema: public; Owner: rsridhar
--

REVOKE ALL ON TABLE queue_table FROM PUBLIC;
REVOKE ALL ON TABLE queue_table FROM rsridhar;
GRANT ALL ON TABLE queue_table TO rsridhar;
GRANT ALL ON TABLE queue_table TO rama;


--
-- PostgreSQL database dump complete
--

