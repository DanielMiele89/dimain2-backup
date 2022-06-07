CREATE PROCEDURE [SchemeMI].[Process_Staging_Customer]

-- from [MI].[RBS_SchemeCustomer_Load_ClearedBalance] 
AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


TRUNCATE TABLE [SchemeMI].[Staging_Customer]
ALTER INDEX ix_Stuff ON SchemeMI.Staging_Customer DISABLE


CREATE TABLE #CustomerStuff (FanID INT, GenderID TINYINT, AgeBandID TINYINT, BankID TINYINT, RainbowID TINYINT, ChannelPreferenceID TINYINT, ActivationMethodID TINYINT)
INSERT INTO #CustomerStuff
EXEC ('LoyaltyPortal.RBSMIPortal.Customer_ST_Fetch') AT lsREWARDBI


;WITH TableGrab AS (
	SELECT f.ID AS FanID
		, f.Sex AS GenderID
		, f.DOB
		, a.ActivatedDate AS ActivationDate
		, a.DeactivatedDate
		, a.OptedOutDate
		, CAST(CASE WHEN a.IsRBS = 1 THEN 1 ELSE 2 END AS TINYINT) AS BankID
		, CAST(ISNULL(CASE WHEN b.IsRainbow = 1 THEN 1 ELSE 2 END,2) AS TINYINT) AS RainbowID
		, CAST(CASE WHEN F.Unsubscribed = 1 THEN 0 ELSE 1 END AS INT) As ContactByEmail
		, CAST(F.ContactByPhone AS INT) AS ContactByPhone
		, CAST(F.ContactBySMS AS INT) AS ContactBySMS
		, CAST(F.ContactByPost AS INT) AS ContactByPost
		, ISNULL(j.CustomerJourneyStatus, 'MOT1') As CustomerJourneyStatus
		, ISNULL(j.LapsFlag, 'Not Lapsed') AS LapsFlag
		--, a.ActivationMethodID AS ActivationMethod
		, a.ActivationMethodID -- ######################################
		, f.SourceUID
		, ISNULL(e.EmailEngaged,0) AS EmailEngaged
		, ISNULL(r.Registered, 0) AS Registered
		, ISNULL(co.ChannelPreferenceID, 3) AS ChannelPreferenceID
		, f.ActivationChannel
		, f.ClubCashAvailable As ClearedBalance
	FROM SLC_REPL..Fan f 
	INNER JOIN Warehouse.MI.CustomerActiveStatus a on f.ID = a.FanID
	LEFT OUTER JOIN (SELECT c.CIN, b.IsRainbow
						FROM Warehouse.Relational.CINList c
						INNER JOIN Warehouse.Relational.CustomerAttribute CA ON C.CINID = CA.CINID
						INNER JOIN Warehouse.Relational.CardTransactionBank b ON CA.BankID = b.BankID
					) b on f.sourceUID = b.CIN
	LEFT OUTER JOIN (SELECT FanID, CustomerJourneyStatus, LapsFlag
				FROM Warehouse.Relational.CustomerJourney
				WHERE EndDate IS NULL) j on f.ID = j.FanID
	LEFT OUTER JOIN (SELECT FanID, EmailEngaged
						FROM Warehouse.Relational.Customer_EmailEngagement
						WHERE EndDate IS NULL) e ON f.ID = e.FanID
	INNER JOIN (SELECT FanID, Registered
					FROM Warehouse.Relational.Customer) r ON F.ID = r.FanID
	LEFT OUTER JOIN Warehouse.MI.RBS_ChannelPreferenceOffline co ON F.ID = co.FanID
)

INSERT INTO [SchemeMI].[Staging_Customer] WITH (TABLOCK) (
	[FanID],[DOB],[ActivatedDate],[DeactivatedDate],[OptedOutDate],[GenderID],[AgeBandID],
	[BankID],[RainbowID],[ChannelPreferenceID],[JourneyStageID],[ContactByEmail],
	[ContactByPhone],[ContactBySMS],[ContactByPost],[IsLapsed],[ActivationMethodID],
	[JourneyStageDetailedID],[SourceUID],[EmailEngaged],[Registered],[ActivationChannel],
	[ClearedBalance]
)
SELECT 
	[FanID],[DOB],[ActivatedDate],[DeactivatedDate],[OptedOutDate],[GenderID],[AgeBandID],
	[BankID],[RainbowID],[ChannelPreferenceID],[JourneyStageID],[ContactByEmail],
	[ContactByPhone],[ContactBySMS],[ContactByPost],[IsLapsed],tg.[ActivationMethodID],
	[JourneyStageDetailedID],[SourceUID],[EmailEngaged],[Registered],[ActivationChannel],
	[ClearedBalance]
FROM TableGrab tg
CROSS APPLY (
	SELECT 
		[ActivatedDate] = GETDATE(), -- ######## 
		[AgeBandID],
		[JourneyStageID] = 0,
		[IsLapsed] = 0,
		--[ActivationMethodID], ----------------------------
		[JourneyStageDetailedID] = 0
	FROM #CustomerStuff ct 
	WHERE ct.FanID = tg.FanID
) x
-- (4318053 rows affected)

ALTER INDEX ix_Stuff ON SchemeMI.Staging_Customer REBUILD -- (FanID) INCLUDE (GenderID, AgeBandID, BankID, RainbowID, ChannelPreferenceID, ActivationMethodID)

RETURN 0