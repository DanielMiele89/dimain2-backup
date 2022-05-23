create PROCEDURE [dbo].[AdminCalcPointsPerFan] 
AS
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

-- Update Log
-- Nirupam - 07/01/2015 - New Refund Logic implemented (AM-61)
-- ChrisM 20180404 Changed database SLC_Subscription.dbo.Fan
-- ChrisM 20180418 completely rewritten
-- To be run in subscriber database before snapshot
-- ChrisM 20180531 changes to defeat deadlocking
-- ChrisM 20201201 Preaggregate Trans


-- Collect preaggregated transactions
IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans 
SELECT t.FanID, 
	pointspending = SUM(tt.multiplier*t.points),
	pointsavailable = SUM(CASE
		when tt.multiplier<0 or t.Condition = 1 THEN tt.multiplier*t.points 
		else 0 end),
	clubcashpending = SUM(tt.multiplier*t.clubcash),
	MRclubcashavailable = SUM(CASE
		when ((tt.multiplier<0 and t.TypeID <> 10) or t.Condition = 1) THEN tt.multiplier*t.clubcash 
		else 0 end),
	nonMRclubcashavailable = SUM(CASE
		when (tt.multiplier<0 or t.Condition = 1) THEN tt.multiplier*t.clubcash 
		else 0 end)
INTO #Trans
FROM (
	SELECT t.FanID, t.typeid, x.Condition, points = SUM(t.points), clubcash = SUM(t.clubcash)
	FROM dbo.trans t
	CROSS APPLY (
		SELECT Condition = CASE WHEN t.activationdays=-1 OR dateadd(d,t.activationdays,t.date) < getdate() THEN 1 ELSE 0 END
	) x
	GROUP BY t.FanID, t.typeid, x.Condition	
) t 
INNER JOIN dbo.transactiontype tt
	ON tt.id = t.typeid
GROUP BY t.FanID
-- (7,115,303 rows affected) / 00:01:32

CREATE UNIQUE CLUSTERED INDEX ucx_Stuff ON #Trans (FanID)


-- Collect points / clubcash changes
IF OBJECT_ID('tempdb..#Fan') IS NOT NULL DROP TABLE #Fan 
SELECT f.ID AS FanID,
	x.PointsPending,
	x.PointsAvailable,
	x.ClubCashPending,
	y.ClubCashAvailable
INTO #Fan
FROM dbo.Club c 
INNER hash JOIN dbo.Fan f
	ON f.clubid = c.id 
INNER JOIN #Trans x 
	ON x.FanID = f.ID
CROSS APPLY (
	SELECT clubcashavailable = CASE WHEN ClubID IN (132,138) THEN x.MRclubcashavailable ELSE x.nonMRclubcashavailable END
) y
WHERE f.[status] = 1 
	AND c.[status] = 1
	AND 
	(f.pointspending <> x.pointspending OR
	f.pointsavailable <> x.pointsavailable OR
	f.clubcashpending <> x.clubcashpending OR
	f.clubcashavailable <> y.clubcashavailable)
--OPTION (MAXDOP 8) 
-- (12933 rows affected) / 00:00:03

-- Update rewards for members with no transactions
INSERT INTO #Fan (FanID, PointsPending, PointsAvailable, ClubCashPending, ClubCashAvailable)
SELECT f.ID AS FanID,
	PointsPending = 0, PointsAvailable = 0, ClubCashPending = 0, ClubCashAvailable = 0
FROM dbo.Fan f
INNER JOIN dbo.Club c 
	ON f.clubid = c.id 
WHERE f.[status] = 1 
	AND c.[status] = 1 
	AND NOT EXISTS (SELECT 1 FROM dbo.Trans t WHERE t.FanID = f.ID)
	AND (PointsPending <> 0 OR PointsAvailable <> 0 OR ClubCashPending <> 0 OR ClubCashAvailable <> 0)
-- 0 / 00:00:29

CREATE UNIQUE CLUSTERED INDEX ucx_FanID ON #Fan (FanID)


IF OBJECT_ID('tempdb..#AgreedTCs') IS NOT NULL DROP TABLE #AgreedTCs 
SELECT FanID = ID INTO #AgreedTCs FROM dbo.Fan WHERE AgreedTCs IS NULL
-- (3911 rows affected) / 00:00:00
CREATE UNIQUE CLUSTERED INDEX ucx_FanID ON #AgreedTCs (FanID)


UPDATE f SET
	PointsPending = x.PointsPending,
	PointsAvailable = x.PointsAvailable,
	ClubCashPending = x.ClubCashPending,
	ClubCashAvailable = x.ClubCashAvailable
FROM dbo.Fan f WITH (ROWLOCK)
INNER JOIN #Fan x 
	ON x.FanID = f.ID
-- (12933 rows affected) / 00:00:01

UPDATE f SET AgreedTCs = 0 
FROM dbo.Fan f 
INNER JOIN #AgreedTCs a ON a.FanID = f.id
-- (3911 rows affected) / 00:00:01


RETURN 0


