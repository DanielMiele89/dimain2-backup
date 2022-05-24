-- =============================================
-- Author:		<Shaun Hide>
-- Create date: <16/05/2018>
-- Description:	<Produce Sector SOW and DD by Date Specified (Note, the date displayed in YYYYMM is relative to the EndDate)>
-- =============================================
CREATE PROCEDURE [Prototype].[SectorDD]
	-- Add the parameters for the stored procedure here
	(
		@StartDate DATE,
		@EndDate DATE
	)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


	-- CLEAR UP OLD FILE
	DELETE FROM Warehouse.Prototype.YYYYMM_SectorDD WHERE YYYYMM = LEFT(CONVERT(VARCHAR,@EndDate,12),6)

	------------------------------------------------------------------------------------
-- Find Book Type and PostCodeDistrict for all customers

IF OBJECT_ID('tempdb..#Customers') IS NOT NULL DROP TABLE #Customers
SELECT	c.PostCodeDistrict,
        c.SourceUID,
		c.FanID,
		cin.CINID
INTO	#Customers
FROM	Warehouse.Relational.Customer c
JOIN	Warehouse.Relational.CINList cin
	ON	c.SourceUID = cin.CIN

CREATE CLUSTERED INDEX cix_CINID ON #Customers (CINID)
CREATE NONCLUSTERED INDEX nix_PostCodeDistrint ON #Customers (PostCodeDistrict)
CREATE NONCLUSTERED INDEX nix_SourceUID ON #Customers (SourceUID)

-- 3898179 rows

IF OBJECT_ID('tempdb..#BackBook') IS NOT NULL DROP TABLE #BackBook
SELECT	DISTINCT FanID
		,BookType
		,StartDate
		,EndDate
INTO	#BackBook
FROM	Warehouse.Relational.Customer_SchemeMembershipType t
JOIN	Warehouse.Relational.Customer_SchemeMembership csm
	ON	t.ID = csm.SchemeMembershipTypeID
WHERE	EndDate IS NULL
	AND BookType = 'Back Book'

CREATE CLUSTERED INDEX cix_FanID ON #BackBook (FanID)

-- 1393917

IF OBJECT_ID('tempdb..#Population') IS NOT NULL DROP TABLE #Population
SELECT	a.PostCodeDistrict,
		a.SourceUID,
		a.FanID,
		a.CINID,
		COALESCE(b.BookType,'Front Book') AS BookType
INTO	#Population
FROM	#Customers a
LEFT JOIN
	#BackBook b
	ON a.FanID = b.FanID

CREATE NONCLUSTERED INDEX nix_CINID ON #Population (CINID)
CREATE CLUSTERED INDEX cix_SourceUID ON #Population (SourceUID)

-- Population Summary
IF OBJECT_ID('tempdb..#PopulationSummary') IS NOT NULL DROP TABLE #PopulationSummary
SELECT	PostCodeDistrict,
		COUNT(CINID) AS PopulationSize
INTO	#PopulationSummary
FROM	#Population
GROUP BY PostCodeDistrict
ORDER BY 1

CREATE CLUSTERED INDEX cix_Combo ON #PopulationSummary (PostCodeDistrict)

--SELECT * FROM #PopulationSummary ORDER BY 1

-- Define Sectors
IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT	ConsumerCombinationID,
		SectorName
INTO	#CC
FROM	Warehouse.Relational.ConsumerCombination cc
JOIN	Warehouse.Relational.Brand br
	ON	cc.BrandID = br.BrandID
JOIN	Warehouse.Relational.BrandSector bs
	ON	br.SectorID = bs.SectorID
WHERE	SectorGroupID NOT IN (3,4)

CREATE CLUSTERED INDEX cix_ConsumerCombinationID ON #CC(ConsumerCombinationID)
CREATE NONCLUSTERED INDEX nix_SectorName ON #CC(SectorName)

--SELECT	SectorName,
--		COUNT(ConsumerCombinationID)
--FROM	#CC
--GROUP BY SectorName
--ORDER BY 1

IF OBJECT_ID('tempdb..#CINTrans') IS NOT NULL DROP TABLE #CINTrans
SELECT	ct.CINID,
		ct.Amount,
		mrb.PostCodeDistrict,
		mrb.BookType,
		cc.SectorName
INTO	#CINTrans
FROM	Warehouse.Relational.ConsumerTransaction ct WITH (NOLOCK)
JOIN	#CC cc
	ON	cc.ConsumerCombinationID = ct.ConsumerCombinationID
JOIN	#Population mrb
	ON	mrb.CINID = ct.CINID
WHERE  ct.TranDate BETWEEN @StartDate and @EndDate
	AND 0 < ct.Amount

CREATE CLUSTERED INDEX CIX_CinTrans_Main ON #CinTrans (CINID)
CREATE NONCLUSTERED INDEX NIX_CinTrans_Shh ON #CinTrans (PostCodeDistrict) INCLUDE (CINID)

IF OBJECT_ID('tempdb..#FileIDList') IS NOT NULL DROP TABLE #FileIDList
SELECT FileID
INTO #FileIDList
FROM Archive_Light.dbo.CBP_DirectDebit_TransactionHistory
GROUP BY FileID
HAVING MIN([Date]) BETWEEN @StartDate AND @EndDate 
ORDER BY FileID

CREATE CLUSTERED INDEX cix_FileID ON #FileIDList (FileID)

IF OBJECT_ID('tempdb..#DirectDebits') IS NOT NULL DROP TABLE #DirectDebits
SELECT	pop.PostCodeDistrict,
		pop.BookType,
		pop.SourceUID,
		dd.Amount,
		dd.OIN
INTO	#DirectDebits
FROM	#Population pop
JOIN	Archive_Light.dbo.CBP_DirectDebit_TransactionHistory dd WITH (NOLOCK)
	ON	pop.SourceUID = dd.SourceUID
JOIN	#FileIDList f 
    ON	f.FileID = dd.FileID

CREATE CLUSTERED INDEX CIX_CinTrans_Main ON #DirectDebits (SourceUID)
CREATE NONCLUSTERED INDEX NIX_OIN ON #DirectDebits (OIN)
CREATE NONCLUSTERED INDEX NIX_CinTrans_Shh ON #DirectDebits (PostCodeDistrict) INCLUDE (SourceUID)


IF OBJECT_ID('tempdb..#Output') IS NOT NULL DROP TABLE #Output
SELECT	LEFT(CONVERT(VARCHAR,@EndDate,112),6) AS YYYYMM,
		a.*
INTO	#Output
FROM	
(
	SELECT
		ct.PostCodeDistrict,
		ct.SectorName,
		ps.PopulationSize,
		SUM(ct.Amount) AS Sales,
		COUNT(ct.CINID) AS Transactions,
		COUNT(DISTINCT ct.CINID) AS Shoppers
	FROM	#CINTrans ct
	JOIN	#PopulationSummary ps
		ON	ct.PostCodeDistrict = ps.PostCodeDistrict
	GROUP BY
		ct.PostCodeDistrict,
		ct.BookType,
		ct.SectorName,
		ps.PopulationSize
	UNION
	SELECT
		dd.PostCodeDistrict,
		'Direct Debit - Utilities (Media Energy Local Authorities & Water)' AS SectorName,
		ps.PopulationSize,
		SUM(dd.Amount) AS Sales,
		COUNT(dd.SourceUID) AS Transactions,
		COUNT(DISTINCT dd.SourceUID) AS Shoppers
	FROM	#DirectDebits dd
	JOIN    Warehouse.Relational.DD_DataDictionary dict
		ON	dd.OIN = dict.OIN
	JOIN	Warehouse.Relational.DD_DataDictionary_Suppliers sup
		ON	dict.SupplierID = sup.SupplierID
	JOIN	#PopulationSummary ps
		ON	dd.PostCodeDistrict = ps.PostCodeDistrict
	WHERE	sup.RefusedByRBSG = 0
	GROUP BY
		dd.PostCodeDistrict,
		ps.PopulationSize
	UNION
	SELECT
		dd.PostCodeDistrict,
		'Direct Debit - Other' AS SectorName,
		ps.PopulationSize,
		SUM(dd.Amount) AS Sales,
		COUNT(dd.SourceUID) AS Transactions,
		COUNT(DISTINCT dd.SourceUID) AS Shoppers
	FROM	#DirectDebits dd
	JOIN	#PopulationSummary ps
		ON	dd.PostCodeDistrict = ps.PostCodeDistrict
	WHERE NOT EXISTS (	SELECT 1
						FROM   Warehouse.Relational.DD_DataDictionary dict
						WHERE  dd.OIN = dict.OIN )
	GROUP BY
		dd.PostCodeDistrict,
		ps.PopulationSize
) a

-- Commas ruin the table in Athena
UPDATE #Output
SET		SectorName = 'Clothing Accessories and Footwear'
WHERE	SectorName = 'Clothing, Accessories and Footwear'

INSERT INTO Warehouse.Prototype.YYYYMM_SectorDD
	SELECT	*
	FROM	#Output


--IF OBJECT_ID('Warehouse.Prototype.YYYYMM_SectorDD') IS NOT NULL DROP TABLE Warehouse.Prototype.YYYYMM_SectorDD
--CREATE TABLE Warehouse.Prototype.YYYYMM_SectorDD
--	(
--		YYYYMM INT,
--		PostCodeDistrict VARCHAR(10),
--		SectorName VARCHAR(100),
--		PopulationSize INT,
--		Sales MONEY,
--		Transactions INT,
--		Shoppers INT
--	)

	
END