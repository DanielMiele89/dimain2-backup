-- =============================================
-- Author:		JEA
-- Create date: 01/02/2013
-- Description:	Analyses Partner MID activity
-- =============================================
CREATE PROCEDURE [gas].[MIDWatchList] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    CREATE TABLE #MIDs(MID varchar(50) not null, BrandID SmallInt not null)

	INSERT INTO #MIDs(MID, BrandID)
	SELECT DISTINCT o.MerchantID, b.BrandID
	FROM Relational.Outlet o
	INNER JOIN Relational.[Partner] p on o.PartnerID = p.PartnerID
	INNER JOIN Relational.Brand b on p.BrandID = b.BrandID
	WHERE O.MerchantID != ''
	ORDER BY b.BrandID

	ALTER TABLE #MIDs ADD PRIMARY KEY(MID)

	CREATE TABLE #BrandMIDs(BrandMIDID INT NOT NULL, BrandID smallint not null, PartnerBrandID smallint not null)

	INSERT INTO #BrandMIDs(BrandMIDID, BrandID, PartnerBrandID)
	SELECT bm.BrandMIDID, bm.BrandID, m.BrandID as PartnerBrandID
	FROM Relational.BrandMID bm
	INNER JOIN #MIDs M ON BM.MID = m.MID

	ALTER TABLE #BrandMIDs ADD PRIMARY KEY(BrandMIDID)

	CREATE TABLE #WatchMIDs(BrandMIDID int not null, LastTranDate date)

	INSERT INTO #WatchMIDs(BrandMIDID, LastTranDate)
	SELECT bm.BrandMIDID, MAX(ct.TranDate) As LastTranDate
	FROM Relational.CardTransaction ct with (nolock)
	INNER JOIN #BrandMIDs bm with (nolock) on ct.BrandMIDID = bm.BrandMIDID
	GROUP BY bm.BrandMIDID, bm.BrandID, bm.PartnerBrandID

	ALTER TABLE #WatchMIDs ADD PRIMARY KEY(BrandMIDID)

	DELETE FROM #WatchMIDs
	FROM #WatchMIDs W
		INNER JOIN #BrandMIDs B ON W.BrandMIDID = B.BrandMIDID
	WHERE LastTranDate > DATEADD(MONTH, -3, GETDATE()) AND B.BrandID = B.PartnerBrandID

	SELECT m.MID, b.BrandName as Brand, mb.BrandName as PartnerBrand, b.IsLivePartner
		, c.FirstTranDate, c.LastTranDate, c.TotalAmount, '' AS LocationAddress--, c.LocationAddress
	FROM
	(
		SELECT W.BrandMIDID, MIN(ct.TranDate)AS FirstTranDate, MAX(ct.TranDate) AS LastTranDate
			, SUM(Amount) AS TotalAmount--, MAX(ct.LocationAddress) AS LocationAddress
		FROM Relational.CardTransaction CT with (nolock)
		INNER JOIN #WatchMIDs W on ct.BrandMIDID = w.BrandMIDID
		GROUP BY W.BrandMIDID
	) c
	INNER JOIN Relational.BrandMID bm with (nolock) on c.BrandMIDID = bm.BrandMIDID
	INNER JOIN Relational.Brand b with (nolock) on bm.BrandID = b.BrandID
	INNER JOIN #MIDs m on bm.MID = m.MID
	INNER JOIN Relational.Brand mb with (nolock) on m.BrandID = mb.BrandID

	DROP TABLE #MIDs
	DROP TABLE #WatchMIDs
	DROP TABLE #BrandMIDs
	
END
GO
GRANT EXECUTE
    ON OBJECT::[gas].[MIDWatchList] TO [DB5\reportinguser]
    AS [dbo];

