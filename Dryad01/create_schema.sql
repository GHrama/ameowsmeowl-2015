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
select count(*) into temp1 from queue_table where queue_id=queue_id;
if temp1=0 then
result = -1000;
end if;
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
401	client
402	client
403	client
404	client
405	client
406	client
407	client
408	client
409	client
410	client
411	client
412	client
413	client
414	client
415	client
416	client
417	client
418	client
419	client
420	client
421	client
422	client
423	client
424	client
425	client
426	client
427	client
428	client
429	client
430	client
431	client
432	client
433	client
434	client
435	client
436	client
437	client
438	client
439	client
440	client
441	client
442	client
443	client
444	client
445	client
446	client
447	client
448	client
449	client
450	client
451	client
452	client
453	client
454	client
455	client
456	client
457	client
458	client
459	client
460	client
461	client
462	client
463	client
464	client
465	client
466	client
467	client
468	client
469	client
470	client
471	client
472	client
473	client
474	client
475	client
476	client
477	client
478	client
479	client
480	client
481	client
482	client
483	client
484	client
485	client
486	client
487	client
488	client
489	client
490	client
491	client
492	client
493	client
494	client
495	client
496	client
497	client
498	client
499	client
500	client
\.


--
-- Name: client_table_client_id_seq; Type: SEQUENCE SET; Schema: public; Owner: rsridhar
--

SELECT pg_catalog.setval('client_table_client_id_seq', 1, false);


--
-- Data for Name: message_table; Type: TABLE DATA; Schema: public; Owner: rsridhar
--

COPY message_table (message_id, queue_id, sender_id, receiver_id, payload, arrival_time) FROM stdin;
\.


--
-- Name: message_table_message_id_seq; Type: SEQUENCE SET; Schema: public; Owner: rsridhar
--

SELECT pg_catalog.setval('message_table_message_id_seq', 1, false);


--
-- Data for Name: queue_table; Type: TABLE DATA; Schema: public; Owner: rsridhar
--

COPY queue_table (queue_id, queue_name) FROM stdin;
1	q
2	q
3	q
4	q
5	q
6	q
7	q
8	q
9	q
10	q
11	q
12	q
13	q
14	q
15	q
16	q
17	q
18	q
19	q
20	q
21	q
22	q
23	q
24	q
25	q
26	q
27	q
28	q
29	q
30	q
31	q
32	q
33	q
34	q
35	q
36	q
37	q
38	q
39	q
40	q
41	q
42	q
43	q
44	q
45	q
46	q
47	q
48	q
49	q
50	q
51	q
52	q
53	q
54	q
55	q
56	q
57	q
58	q
59	q
60	q
61	q
62	q
63	q
64	q
65	q
66	q
67	q
68	q
69	q
70	q
71	q
72	q
73	q
74	q
75	q
76	q
77	q
78	q
79	q
80	q
81	q
82	q
83	q
84	q
85	q
86	q
87	q
88	q
89	q
90	q
91	q
92	q
93	q
94	q
95	q
96	q
97	q
98	q
99	q
100	q
101	q
102	q
103	q
104	q
105	q
106	q
107	q
108	q
109	q
110	q
111	q
112	q
113	q
114	q
115	q
116	q
117	q
118	q
119	q
120	q
121	q
122	q
123	q
124	q
125	q
126	q
127	q
128	q
129	q
130	q
131	q
132	q
133	q
134	q
135	q
136	q
137	q
138	q
139	q
140	q
141	q
142	q
143	q
144	q
145	q
146	q
147	q
148	q
149	q
150	q
151	q
152	q
153	q
154	q
155	q
156	q
157	q
158	q
159	q
160	q
161	q
162	q
163	q
164	q
165	q
166	q
167	q
168	q
169	q
170	q
171	q
172	q
173	q
174	q
175	q
176	q
177	q
178	q
179	q
180	q
181	q
182	q
183	q
184	q
185	q
186	q
187	q
188	q
189	q
190	q
191	q
192	q
193	q
194	q
195	q
196	q
197	q
198	q
199	q
200	q
201	q
202	q
203	q
204	q
205	q
206	q
207	q
208	q
209	q
210	q
211	q
212	q
213	q
214	q
215	q
216	q
217	q
218	q
219	q
220	q
221	q
222	q
223	q
224	q
225	q
226	q
227	q
228	q
229	q
230	q
231	q
232	q
233	q
234	q
235	q
236	q
237	q
238	q
239	q
240	q
241	q
242	q
243	q
244	q
245	q
246	q
247	q
248	q
249	q
250	q
251	q
252	q
253	q
254	q
255	q
256	q
257	q
258	q
259	q
260	q
261	q
262	q
263	q
264	q
265	q
266	q
267	q
268	q
269	q
270	q
271	q
272	q
273	q
274	q
275	q
276	q
277	q
278	q
279	q
280	q
281	q
282	q
283	q
284	q
285	q
286	q
287	q
288	q
289	q
290	q
291	q
292	q
293	q
294	q
295	q
296	q
297	q
298	q
299	q
300	q
301	q
302	q
303	q
304	q
305	q
306	q
307	q
308	q
309	q
310	q
311	q
312	q
313	q
314	q
315	q
316	q
317	q
318	q
319	q
320	q
321	q
322	q
323	q
324	q
325	q
326	q
327	q
328	q
329	q
330	q
331	q
332	q
333	q
334	q
335	q
336	q
337	q
338	q
339	q
340	q
341	q
342	q
343	q
344	q
345	q
346	q
347	q
348	q
349	q
350	q
351	q
352	q
353	q
354	q
355	q
356	q
357	q
358	q
359	q
360	q
361	q
362	q
363	q
364	q
365	q
366	q
367	q
368	q
369	q
370	q
371	q
372	q
373	q
374	q
375	q
376	q
377	q
378	q
379	q
380	q
381	q
382	q
383	q
384	q
385	q
386	q
387	q
388	q
389	q
390	q
391	q
392	q
393	q
394	q
395	q
396	q
397	q
398	q
399	q
400	q
401	q
402	q
403	q
404	q
405	q
406	q
407	q
408	q
409	q
410	q
411	q
412	q
413	q
414	q
415	q
416	q
417	q
418	q
419	q
420	q
421	q
422	q
423	q
424	q
425	q
426	q
427	q
428	q
429	q
430	q
431	q
432	q
433	q
434	q
435	q
436	q
437	q
438	q
439	q
440	q
441	q
442	q
443	q
444	q
445	q
446	q
447	q
448	q
449	q
450	q
451	q
452	q
453	q
454	q
455	q
456	q
457	q
458	q
459	q
460	q
461	q
462	q
463	q
464	q
465	q
466	q
467	q
468	q
469	q
470	q
471	q
472	q
473	q
474	q
475	q
476	q
477	q
478	q
479	q
480	q
481	q
482	q
483	q
484	q
485	q
486	q
487	q
488	q
489	q
490	q
491	q
492	q
493	q
494	q
495	q
496	q
497	q
498	q
499	q
500	q
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

