IMPORT 'common_macros.pig';
%DEFAULT rawd    '/data/gold';
%DEFAULT out_dir '/data/outd/baseball';

-- cities = LOAD '$rawd/geo/census/us_city_pops.tsv' AS (city:chararray, state:chararray, pop:int);
-- New York    	New York    	8244910
-- Los Angeles 	California  	3819702
-- Chicago     	Illinois    	2707120
-- Houston     	Texas       	2145146
-- Philadelphia	Pennsylvania	1536471
-- Phoenix     	Arizona     	1469471

cities = LOAD '$rawd/geo/census/us_city_pops.tsv' AS (city:chararray, state:chararray, pop:int);

DESCRIBE cities;

DEFINE IOver                  org.apache.pig.piggybank.evaluation.Over('state_rk:int');

ranked = FOREACH(GROUP cities BY state) {
  c_ord = ORDER cities BY pop DESC;
  GENERATE
    -- FLATTEN(
    Stitch(c_ord,
      IOver(c_ord, 'rank', -1, -1, 2)) -- beginning (-1) to end (-1) on third field (2)
    -- )
    ;
};
DESCRIBE ranked;
STORE_TABLE('ranked_cities', ranked);

-- ranked_cities = FOREACH (GROUP cities BY state) {
--   tcc     = ORDER cities BY pop DESC;
--   ranked  = Stitch(tcc, IOver(tcc, 'rank', -1, -1, 2));
--   GENERATE
--     group   AS year_id, 
--     ranked  AS ranked
--     ;
-- };
-- DESCRIBE ranked_cities;
-- -- STORE_TABLE('foo', cities);


-- foo = FOREACH cities GENERATE
--   SPRINTF('%6s|%-8s|%2$,+12d %2$8x %3$1tF %<tT %<tz', 'yay', 665568, (long)(665568*1000000L)),
--   SPRINTF('%2$5d: %3$6s %1$3s %2$4x (%<4X)', 'the', 48879, 'wheres'),
--   SPRINTF('%tF %<tT %<tz', ToMilliSeconds(CurrentTime()))  
-- ;
-- 
--   -- SPRINTF('%2$10s %1$-20s %2$,10d %2$8x %3$10.3f %4$1TFT%<tT%<tz',
--   --   city, pop, (float)(pop/69.0f), (long)(pop * 1000000L));
-- 
-- DUMP foo;
-- 
-- -- (   8244910 New York                   8,244,910   7dceae 119491.453 true       2231-04-09)
-- -- (   3819702 Los Angeles                3,819,702   3a48b6  55358.000 true       2091-01-15)
-- -- (   2707120 Chicago                    2,707,120   294eb0  39233.625 true       2055-10-14)
-- -- (   2145146 Houston                    2,145,146   20bb7a  31089.072 true       2037-12-22)
-- -- (   1536471 Philadelphia               1,536,471   1771d7  22267.695 true       2018-09-09)
-- -- (   1469471 Phoenix                    1,469,471   166c1f  21296.682 true       2016-07-25)
-- 
-- 
-- 
-- -- -- foo = LIMIT bat_yrs 1;
-- -- --
-- -- -- bob = FOREACH foo GENERATE
-- -- --   (1,2) AS tup:tuple(a:int, b:int),
-- -- --   1 AS val:int,
-- -- --   (1)   AS tup1:tuple(a:int);
-- -- --
-- -- -- bob = FOREACH bob GENERATE
-- -- --   TOTUPLE(tup), TOTUPLE(1), TOTUPLE(tup1);
-- -- -- DUMP bob;
-- -- -- DESCRIBE bob;
-- -- 
-- -- 
-- -- CREATE TABLE test(in_d DECIMAL(6,3),   in_f FLOAT,         digits INT,
-- --                   out_dd DECIMAL(6,3), out_fd DECIMAL(6,3), 
-- --                   out_df FLOAT,        out_ff FLOAT);
-- -- 
-- -- INSERT INTO test(in_d, digits) VALUES (12.6,  0);
-- -- INSERT INTO test(in_d, digits) VALUES (12.5,  0);
-- -- INSERT INTO test(in_d, digits) VALUES (12.35, 0);
-- -- INSERT INTO test(in_d, digits) VALUES (12.25, 0);
-- -- INSERT INTO test(in_d, digits) VALUES (12.0,  0);
-- -- INSERT INTO test(in_d, digits) VALUES (11.6,  0);
-- -- INSERT INTO test(in_d, digits) VALUES (11.5,  0);
-- -- INSERT INTO test(in_d, digits) VALUES (11.35, 0);
-- -- INSERT INTO test(in_d, digits) VALUES (11.25, 0);
-- -- INSERT INTO test(in_d, digits) VALUES (11.0,  0);
-- -- INSERT INTO test(in_d, digits) VALUES (10.5,  0);
-- -- INSERT INTO test(in_d, digits) VALUES ( 9.5,  0);
-- -- INSERT INTO test(in_d, digits) VALUES ( 8.5,  0);
-- -- INSERT INTO test(in_d, digits) VALUES ( 7.5,  0);
-- -- INSERT INTO test(in_d, digits) VALUES (1.0,   0);
-- -- INSERT INTO test(in_d, digits) VALUES (0.0,   0);
-- -- 
-- -- INSERT INTO test(in_d, digits) SELECT -in_d, 0 FROM test 
-- --   WHERE (in_d > 0) AND (digits = 0) ORDER BY in_d;
-- -- 
-- -- INSERT INTO test(in_d, digits) SELECT in_d, 1 FROM test 
-- --   WHERE (digits = 0) ORDER BY in_d;
-- -- 
-- -- UPDATE test SET in_f = in_d;
-- -- 
-- -- UPDATE test SET 
-- --   out_dd = ROUND(in_d, digits), -- round decimal to decimal
-- --   out_fd = ROUND(in_f, digits), -- round float   to decimal
-- --   out_df = ROUND(in_d, digits), -- round decimal to float
-- --   out_ff = ROUND(in_f, digits)  -- round float   to float
-- -- ;
-- -- 
-- -- 
-- -- SELECT test.*, out_dd - out_fd AS q1, out_df - out_ff AS q2
-- --   FROM test
-- --   ORDER BY digits ASC, ABS(in_d) DESC, q1, q2;
-- -- 
-- -- 
-- -- -- oracle    away from zero  away from zero
-- -- -- posgresql away from zero  (no yuo)
-- -- -- websql    away from zero  away from zero
-- -- 
-- -- -- 12.35	12.35000038147	1	12.4	12.4	12.39999961853	12.39999961853	1	1
-- -- -- -12.35	-12.35000038147	1	-12.4	-12.4	-12.39999961853	-12.39999961853	1	1
-- -- -- -11.25	-11.25	1	-11.3	-11.2	-11.300000190735	-11.199999809265	0	0
-- -- -- 11.25	11.25	1	11.3	11.2	11.300000190735	11.199999809265	0	0
-- -- -- 12.25	12.25	1	12.3	12.2	12.300000190735	12.199999809265	0	0
-- -- -- -12.25	-12.25	1	-12.3	-12.2	-12.300000190735	-12.199999809265	0	0
-- -- -- 10.5    10.5    0       11      10      11      10      0       0
-- -- -- -10.5   -10.5   0       -11     -10     -11     -10     0       0
-- -- -- -9.5    -9.5    0       -10     -10     -10     -10     1       1
-- -- -- 9.5     9.5     0       10      10      10      10      1       1
-- -- -- -8.5    -8.5    0       -9      -8      -9      -8      0       0
-- -- -- 8.5     8.5     0       9       8       9       8       0       0
-- -- -- 7.5     7.5     0       8       8       8       8       1       1
-- -- -- -7.5    -7.5    0       -8      -8      -8      -8      1       1
-- top_queries = LOAD '/Users/flip/ics/data_science_fun_pack/pig/pig/test/data/pigunit/top_queries_input_data.txt' AS (site:chararray, hits:int);

-- SET;

top_queries = LOAD '/data/gold/misc/pigunit/top_queries_input_data.txt' AS (site:chararray, hits:int);
  
-- top_queries_g = GROUP top_queries BY site;
-- top_queries_x = FOREACH top_queries_g GENERATE
--   Coalesce(group) AS site, Stitch(top_queries, top_queries) AS tt;
-- DUMP top_queries_x;


round_fiddle = FOREACH top_queries {
  num  = (0.029 * (hits / SIZE(site)));
  GENERATE
    ROUND_TO(num,        4)      AS rnd_dbl,
    ROUND_TO((float)num, 4)      AS rnd_flt,
    ROUND_TO(0.9876543,  5)      AS rnd_bty,
    site, hits, SIZE(site), 
    num
    ;
  };

DESCRIBE round_fiddle;
DUMP round_fiddle;
