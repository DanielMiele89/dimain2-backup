CREATE PROCEDURE [dbo].[__AdminCalcPointsPerFan] 
AS
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

-- Update Log
-- Nirupam - 07/01/2015 - New Refund Logic implemented (AM-61)
-- ChrisM 20180404 Changed database SLC_Subscription.dbo.Fan
-- ChrisM 20180418 completely rewritten
-- To be run in subscriber database before snapshot

DECLARE @FanID INT

-- Collect changes
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
CROSS APPLY (
	SELECT 
		pointspending = SUM(tt.multiplier*t.points),
		pointsavailable = SUM(CASE
			when tt.multiplier<0 or t.activationdays=-1 or dateadd(d,t.activationdays,t.date)<getdate() THEN tt.multiplier*t.points 
			else 0 end),
		clubcashpending = SUM(tt.multiplier*t.clubcash),
		MRclubcashavailable = SUM(CASE
			when ((tt.multiplier<0 and t.TypeID <> 10) or t.activationdays=-1 or dateadd(d,t.activationdays,t.date)<getdate()) THEN tt.multiplier*t.clubcash 
			else 0 end),
		nonMRclubcashavailable = SUM(CASE
			when (tt.multiplier<0 or t.activationdays=-1 or dateadd(d,t.activationdays,t.date)<getdate()) THEN tt.multiplier*t.clubcash 
			else 0 end)
	FROM dbo.transactiontype tt
	INNER merge JOIN dbo.trans t 
		ON tt.id=t.typeid
	WHERE t.FanID = f.ID
) x
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
OPTION (MAXDOP 8) 
-- (3016 rows affected) / 00:04:46

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

CREATE UNIQUE CLUSTERED INDEX ucx_FanID ON #Fan (FanID)


-- select * from #Fan 239200


BEGIN TRAN

-- attempt to lock the rows
SELECT @FanID = FanID
FROM #Fan x
INNER loop JOIN dbo.Fan f WITH (ROWLOCK, UPDLOCK, HOLDLOCK) 
	ON x.FanID = f.ID

-- Apply changes
UPDATE f SET
	PointsPending = x.PointsPending,
	PointsAvailable = x.PointsAvailable,
	ClubCashPending = x.ClubCashPending,
	ClubCashAvailable = x.ClubCashAvailable
FROM dbo.Fan f
INNER JOIN #Fan x 
	ON x.FanID = f.ID
-- (3016 rows affected) / 00:00:07


COMMIT TRAN


RETURN 0


