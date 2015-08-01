
-- ***************************************************************************
--
-- === Detecting Outliers
--

--
--
-- Let's make a
-- QEM: need to complete sentence/idea
--
-- footnote:[this is a miniature version of the Career Standards Test formulated
-- by Bill James, the Newton of baseball analytics -- see
-- www.baseball-reference.com/about/leader_glossary.shtml#hof_standard]
--
-- In this case, we're interested in the outliers precisely because they are outliers.
--
-- but in other situations you might use this trick to identify values that are
-- spurious or deserve closer inspection.
--
-- Your first instinct might be to use a nested FILTER or FOREACH on each
-- group's bag, but that is unweildy at best. Instead, make a new field that
-- has a value only when the record should be selected:
--
-- First, project a column with an innocuous value like zero or null when not in
-- the chosen set, and the value to retrieve when in the set. Here, we project
-- the value 1 for outlier seasons -- more than one standard deviation over the
-- league average.
--
tops = FOREACH normed GENERATE
  player_id, year_id,
  G,    PA,   AB,   HBP,  SH,
  BB,   H,    h1B,  h2B,  h3B,
  HR,   R,    RBI,  OBP,  SLG,
  zH,   zHR,  zR,   zRBI, zOBP,  zSLG, zOPS,
  ((zH   >= 1.0 AND PA >= 450) ? 1 : 0) AS hi_H,
  ((zHR  >= 1.0 AND PA >= 450) ? 1 : 0) AS hi_HR,
  ((zR   >= 1.0 AND PA >= 450) ? 1 : 0) AS hi_R,
  ((zRBI >= 1.0 AND PA >= 450) ? 1 : 0) AS hi_RBI,
  ((zOBP >= 1.0 AND PA >= 450) ? 1 : 0) AS hi_OBP,
  ((zSLG >= 1.0 AND PA >= 450) ? 1 : 0) AS hi_SLG
  ;

--
-- Now we can roll up a player's career and count the number of outlier seasons
-- simultaneously.
--
career_peaks = FOREACH (GROUP tops BY player_id) {
  topq   = FILTER tops BY PA >= 450;
  G   = SUM(tops.G);   PA  = SUM(tops.PA);  AB  = SUM(tops.AB);
  HBP = SUM(tops.HBP); BB  = SUM(tops.BB);  H   = SUM(tops.H);
  h1B = SUM(tops.h1B); h2B = SUM(tops.h2B); h3B = SUM(tops.h3B);
  HR  = SUM(tops.HR);  R   = SUM(tops.R);   RBI = SUM(tops.RBI);
  OBP    = 1.0*(H + BB + HBP) / (PA-SUM(tops.SH));
  SLG    = 1.0*(h1B + 2*h2B + 3*h3B + 4*HR) / AB;
  avzH   = ROUND_TO(AVG(topq.zH),3);   avzHR  = ROUND_TO(AVG(topq.zHR),3);
  avzR   = ROUND_TO(AVG(topq.zR),3);   avzRBI = ROUND_TO(AVG(topq.zRBI),3);
  avzOBP = ROUND_TO(AVG(topq.zOBP),3); avzSLG = ROUND_TO(AVG(topq.zSLG),3);
  avzOPS = ROUND_TO(AVG(topq.zOPS),3);
  GENERATE
    group AS player_id,
    MIN(tops.year_id)   AS beg_year, MAX(tops.year_id) AS end_year,
    --
    -- Total career contribution:
    --   Cumulative statistics
    G   AS G,   PA  AS PA,  BB  AS BB,
    H   AS H,   HR  AS HR,  R   AS R,  RBI AS RBI,
    ROUND_TO(OBP,3) AS OBP, ROUND_TO(SLG,3) AS SLG, ROUND_TO(OBP+SLG,3) AS OPS,
    --
    -- Peak excellence, normalized to era:
    --   Average of seasonal z-scores (qual. only)
    -- avzH   AS avzH,   avzHR  AS avzHR,
    avzR   AS avzR,   avzRBI AS avzRBI,
    avzOBP AS avzOBP, avzSLG AS avzSLG, avzOPS AS avzOPS,
    --
    -- Sustained excellence, normalized to era:
    --   total seasons and qualified (at least 450 plate appearances) seasons
    COUNT_STAR(tops)  AS n_seasons, COUNT_STAR(topq)  AS n_qualsns,
    --   number of qualified seasons with > 1-sigma performance
    SUM(tops.hi_H)    AS n_hiH,     SUM(tops.hi_HR)   AS n_hiHR,
    SUM(tops.hi_R)    AS n_hiR,     SUM(tops.hi_RBI)  AS n_hiRBI,
    SUM(tops.hi_OBP)  AS n_hiOBP,   SUM(tops.hi_SLG)  AS n_hiSLG
    ;
  };

--
-- We've prepared a set of metrics we think will be useful in identifying
-- players with historically great careers, but we don't yet have any
--
-- That is, we know Tony Gwynn's ten seasons of 1-sigma-plus OBP
-- and Jim Rice's ten seasons of 1-sigma-plus SLG are both impressive,
--
-- (these are defensible choices, though guided in part by narrative goals)
--
-- Players with truly exceptional careers
-- footnote:[Voting is based on a player's "record, playing ability, integrity, sportsmanship, character, and contributions to [their] team(s)". Induction requires 75% or more of votes in a yearly ballot of baseball writers, or selection by special committee. Players must have played 10 or more seasons, and become eligible five years after retirement or if deceased; eligibility ends 20 years after retirement or by receiving less than 5% of votes -- baseballhall.org/hall-famers/rules-election/BBWAA]
-- are selected for the Hall of Fame.
--
-- The 'bat_hof' table lists every player eligible for the hall of fame
--

-- ballplayers or hospitals or keyword advertisements
--

-- Earlier we stated that the
--
-- Whenever possible,
--
-- Any rational evaluation will place Babe Ruth, Ted Williams and Willie Mays among the very
-- best of players.

-- If we chose to judge players' careers by number of high-OBP or high-SLG
-- seasons, total career home runs, and career OPS on-base-plus-slugging, then
-- Ellis Burks  (2 high-OPS, 8 high-SLG; 0.874 career OPS) would seem to be the superior of
-- Andre Dawson (0 high-OPS, 8 high-SLG; 0.806 career OPS), both superior to
-- Robin Yount  (4 high-OPS, 4 high-SLG, 0.772 career OPS).

-- In fact, however, Yount is acknowledged as one of the hundred best players
-- ever; Dawson as being right above the edge of what defines a great career; and
-- Burks as being very good but well short of great. Any metric as simplistic as this

-- Ellis Burks, Carl Yastrzemski ("Yaz" from here on) and Andre Dawson each had
-- 8 1-sigma-SLG seasons, a career OPS over 0.800, and more than 350 home runs.

-- The details of performing logistic regression analysis are out of scope for
-- this book, but you can look in the sample code.

--
-- We'd like to
-- QEM: need to complete sentence/idea

-- *
-- *

-- * multiple seasons of excellent performance
-- *

hof = load_hofs();

hof = FOREACH hof GENERATE player_id, hof_score, (is_pending == 1 ? 'pending' : Coalesce(inducted_by, '.'));
hof_worthy = FOREACH (JOIN career_peaks BY player_id, hof BY player_id)
  GENERATE *,
   (n_hiH + n_hiHR + n_hiR + n_hiRBI + 1.5*n_hiOBP + 1.5*n_hiSLG) AS is_awesome;
hof_worthy = ORDER hof_worthy BY is_awesome, avzOPS, hof_score;
STORE_TABLE('hof_worthy', hof_worthy);
-- cat $out_dir/hof_worthy
