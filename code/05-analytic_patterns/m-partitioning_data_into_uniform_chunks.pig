IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/gold'; %DEFAULT out_dir '/data/outd/baseball';

bat_seasons = load_bat_seasons();

-- ***************************************************************************
--
-- === Partitioning Data into Uniform Chunks
--

-- note this should come after the MultiStorage script.


-- ==== Strategy 1: ORDER BY with parallelism
-- 
-- An ORDER BY statement with parallelism forced to (output size / desired chunk size) will give you _roughly_ uniform chunks,


bats_chunked_1 = ORDER bat_seasons BY (player_id, year_id) PARALLEL 7
STORE_TABLE(bats_chunked, 'bats_chunked');

-- ==== Strategy 2: Rank
-- 
-- Each chunk except the last will be exactly chunk_size.

%DEFAULT chunk_size 10000
;

-- Supply enough keys to rank to ensure a stable sorting
bat_seasons_ranked  = RANK bat_seasons BY (player_id, year_id)
bat_seasons_chunked = FOREACH (bat_seasons_ranked) GENERATE
  SPRINTF("%03d", FLOOR(rank/$chunk_size)) AS chunk_key, player_id..;

-- Writes the chunk key into the file, like it or not.
STORE bat_seasons_chunked INTO '$out_dir/bat_seasons_chunked'
  USING MultiStorage('$out_dir/bat_seasons_chunked','0'); -- field 0: chunk_key


-- ==== Strategy 3: Mod Chunks

-- Send rows to reducer line_no % n_chunks.
-- Assuming input files are meaty, will be exactly n_chunks files of size ~= (tot_recs/n_size) +/- sqrt(n_mappers)

%DEFAULT n_chunks 8
;
-- no sort key fields, and so it's done on the map side (avoiding the single-reducer drawback of RANK)
bats_ranked_m = FOREACH (RANK bat_seasons) GENERATE
  MOD(rank, $n_chunks) AS chunk_key, player_id..;
bats_chunked_m = FOREACH (GROUP bats_ranked_m BY chunk_key)
  GENERATE FLATTEN(bats_ranked_m);
STORE bats_chunked_m INTO '$out_dir/bats_chunked_m'
  USING MultiStorage('$out_dir/bat_seasons_chunked','0'); -- field 0: chunk_key
