-- =============================================
-- Author:		JEA
-- Create date: 21/06/2013
-- Description:	Refresh uplift support tables
-- =============================================
CREATE PROCEDURE [MI].[SchemeUpliftSupportTables_Refresh]
	WITH EXECUTE AS 'Ed'
AS
BEGIN
	
	SET NOCOUNT ON;
   
	--Clear customer list
	TRUNCATE TABLE MI.SchemeTransCINID

	INSERT INTO MI.SchemeTransCINID(CINID, FanID, ClubID, CompositeID)
	SELECT l.CINID, c.FanID, c.ClubID, c.CompositeID
	FROM Relational.CINList l
	INNER JOIN Relational.Customer c on l.CIN = c.SourceUID
	LEFT OUTER JOIN MI.CINDuplicate d ON c.FanID = d.FanID
	WHERE NOT c.ActivatedDate IS NULL
	AND d.FanID IS NULL

	UNION
	--insert entirety of the current unstratified control group
	SELECT u.CINID, u.FanID, u.ClubID, c.CompositeID
	FROM Relational.Control_Unstratified u
	INNER JOIN SLC_Report.dbo.Fan c on u.FanID = c.ID
	WHERE u.EndDate IS NULL OR u.EndDate > GETDATE()

	--reconstruct primary key once inserts are complete
	ALTER INDEX PK_MI_SchemeTransCINID ON MI.SchemeTransCINID REBUILD
   
	--REFRESH SchemeMID start and end dates

	--Initialise start and end dates.
	--If no partnertrans records are found, these dates apply
	UPDATE Relational.SchemeMID
	SET StartDate = AddedDate, EndDate = RemovedDate

	--StartDate will never be null.
	--Where transactions are incentivised before the addedDate, this is revised
	UPDATE Relational.SchemeMID
		SET StartDate = p.MinTranDate
	FROM Relational.SchemeMID s
	INNER JOIN (SELECT OutletID, MIN(TransactionDate) AS MinTranDate
				FROM Relational.PartnerTrans
				WHERE EligibleForCashback = 1
				GROUP BY OutletID
				) p on S.OutletID = P.OutletID
	WHERE p.MinTranDate < S.StartDate

	--where transactions are incentivised after a MID is removed, the end date is extended.
	--note that where RemovedDate is null, this test will always fail by design
	UPDATE Relational.SchemeMID
		SET EndDate = p.MaxTranDate
	FROM Relational.SchemeMID s
	INNER JOIN (SELECT OutletID, MAX(TransactionDate) AS MaxTranDate
				FROM Relational.PartnerTrans
				WHERE EligibleForCashback = 1
				GROUP BY OutletID
				) p on S.OutletID = P.OutletID
	WHERE p.MaxTranDate > s.EndDate

	--Clear the BrandMID list
	TRUNCATE TABLE MI.SchemeTransBrandMID
	TRUNCATE TABLE MI.SchemeTransCombination
	
	--create a temp table to keep track of those MIDs to be added, in particular those with leading zeroes
	CREATE TABLE #MIDOutlet(MID VARCHAR(50) PRIMARY KEY, OutletID int not null, PartnerID int not null, IsOnline bit not null, StartDate date not null, EndDate date)

	INSERT INTO #MIDOutlet(MID, OutletID, PartnerID, IsOnline, StartDate, EndDate)
	SELECT MID, OutletID, PartnerID, IsOnline, StartDate, EndDate
	FROM Relational.SchemeMID

	CREATE TABLE #CombinationsOfInterest(ConsumerCombinationID INT PRIMARY KEY, MID VARCHAR(50) NOT NULL)

	INSERT INTO	#CombinationsOfInterest(ConsumerCombinationID, MID)
	SELECT ConsumerCombinationID, MID
	FROM Relational.ConsumerCombination
	WHERE IsUKSpend = 1

	INSERT INTO #MIDOutlet(MID, OutletID, PartnerID, IsOnline, StartDate, EndDate)
	SELECT N.MID, N.OutletID, N.PartnerID , N.IsOnline, N.StartDate, N.EndDate
	FROM
	(
		SELECT RIGHT(MID,7) AS MID, OutletID, PartnerID, IsOnline, StartDate, EndDate
		FROM Relational.SchemeMID
		WHERE LEN(MID) = 8 AND LEFT(MID,1) = '0'
	) N
	LEFT OUTER JOIN #MIDOutlet M ON N.MID = M.MID
	WHERE M.MID IS NULL

	INSERT INTO MI.SchemeTransBrandMID(BrandMIDID, OutletID, PartnerID, IsOnline, StartDate, EndDate)
	SELECT B.BrandMIDID, m.outletID, m.PartnerID, m.IsOnline, m.StartDate, m.EndDate
	FROM Relational.BrandMID B
	INNER JOIN #MIDOutlet m on b.MID = m.MID

	INSERT INTO MI.SchemeTransCombination(ConsumerCombinationID, OutletID, PartnerID, IsOnline, StartDate, EndDate)
	SELECT B.ConsumerCombinationID, m.outletID, m.PartnerID, m.IsOnline, m.StartDate, m.EndDate
	FROM #CombinationsOfInterest B
	INNER JOIN #MIDOutlet m on b.MID = m.MID
	
	ALTER INDEX PK_MI_SchemeTransBrandMID ON MI.SchemeTransBrandMID REBUILD
	ALTER INDEX PK_MI_SchemeTransCombination ON MI.SchemeTransCombination REBUILD
   
END