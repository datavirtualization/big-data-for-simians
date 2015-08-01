IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/gold'; %DEFAULT out_dir '/data/outd/baseball';
bat_seasons   = load_bat_seasons();


-- move forward to the stats chapter if we move the "completely summarize" there

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Calculating Quantiles
--
-- QEM: needs prose (perhaps able to draw from prose file)

--
-- Example of quantile extraction
--

-- Adding in a little randomness so that the values on the boundary don't stack up
vals = FOREACH bat_seasons GENERATE
  weight + 0.001*RANDOM() AS val
  ;

h_4ile = FOREACH (GROUP (FILTER vals BY val IS NOT NULL) ALL) {
  sorted = ORDER    $1.val BY val;
  GENERATE
    FLATTEN(SortedQuartile(sorted))
  ;
};
DESCRIBE h_4ile;
DUMP h_4ile;

cts = FOREACH vals {
  GENERATE
    ((val >= (double)h_4ile.quantile_0_0  AND val <  (double)h_4ile.quantile_0_25) ? 1 : 0) AS is_q1,
    ((val >= (double)h_4ile.quantile_0_25 AND val <  (double)h_4ile.quantile_0_5 ) ? 1 : 0) AS is_q2,
    ((val >= (double)h_4ile.quantile_0_5  AND val <  (double)h_4ile.quantile_0_75) ? 1 : 0) AS is_q3,
    ((val >= (double)h_4ile.quantile_0_75 AND val <= (double)h_4ile.quantile_1_0 ) ? 1 : 0) AS is_q4
    ;
};

dist = FOREACH (GROUP cts ALL) {
  n_vals = COUNT_STAR(cts);
  GENERATE
    n_vals,
    SUM(cts.is_q1)  AS q1_ct,
    SUM(cts.is_q2)  AS q2_ct,
    SUM(cts.is_q3)  AS q3_ct,
    SUM(cts.is_q4)  AS q4_ct
    ;
};

DUMP dist;

bins = FOREACH vals GENERATE ROUND_TO(val, 0) AS bin;
hist = FOREACH (GROUP bins BY bin) GENERATE
  group AS bin, COUNT_STAR(bins) AS ct;
DUMP hist;

-- tc_cities = load_us_city_pops();
--
-- parks = load_parks();
-- parks  = FILTER parks BY n_games > 50;
-- bb_cities = FOREACH parks GENERATE park_id, city;
--
-- summary = summarize_strings_by(parks, 'park_id',    'ALL'); DUMP summary;
-- summary = summarize_strings_by(parks, 'park_name',  'ALL'); DUMP summary;
-- summary = summarize_strings_by(parks, 'city',       'ALL'); DUMP summary;
-- summary = summarize_strings_by(parks, 'streetaddr', 'ALL'); DUMP summary;
-- summary = summarize_strings_by(parks, 'url',        'ALL'); DUMP summary;
-- summary = summarize_strings_by(parks, 'allnames',   'ALL'); DUMP summary;
-- summary = summarize_strings_by(parks, 'allteams',   'ALL'); DUMP summary;
-- summary = summarize_strings_by(parks, 'comments',   'ALL'); DUMP summary;
-- summary = summarize_strings_by(parks, 'state_id',   'ALL'); DUMP summary;
-- summary = summarize_strings_by(parks, 'country_id', 'ALL'); DUMP summary;
