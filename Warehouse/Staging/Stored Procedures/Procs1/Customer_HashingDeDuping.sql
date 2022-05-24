-- ========================================================================================
-- Author: Suraj Chahal
-- Create date: 06/05/2015
-- Description: Generates table with Matched hashed customers using MD5 or SHA1 algorithms
-- =======================================================================================
CREATE PROCEDURE [Staging].[Customer_HashingDeDuping] (
			@HashType TINYINT,
			@InputTableName VARCHAR(200),
			@HashedMatchTableName VARCHAR(200)
			) 	

AS
BEGIN
	SET NOCOUNT ON;


DECLARE @SQLQry NVARCHAR(MAX)
 
--SET @HashType = 2
--SET @InputTableName = 'Sandbox.Stuart.Trainline_details20150609101606'
--SET @HashedMatchTableName = 'Warehouse.InsightArchive.Trainline_ShoppedEverMatches'

/******************************************************************************
**********************Currently Active email addresses*************************
******************************************************************************/
IF OBJECT_ID ('tempdb..#ActiveCustomers') IS NOT NULL DROP TABLE #ActiveCustomers
SELECT	FanID,
	LOWER(LTRIM(RTRIM(LastName))) as Surname,
	LOWER(REPLACE(Email,' ','')) as Email
INTO #ActiveCustomers
FROM warehouse.relational.customer
WHERE CurrentlyActive = 1


/*****************************************************************************
********************Currently Active old email addresses**********************
*****************************************************************************/
IF OBJECT_ID ('tempdb..#ActiveAltEmail') IS NOT NULL DROP TABLE #ActiveAltEmail
SELECT	c.FanID,
	LOWER(LTRIM(RTRIM(c.Lastname))) as Surname,
	LOWER(REPLACE(d.value,' ','')) as Email
INTO #ActiveAltEmail
FROM Warehouse.Relational.Customer c
INNER JOIN OPENQUERY(DB5,'
			SELECT	FanID,
				Value
			FROM Archive.ChangeLog.DataChangeHistory_Nvarchar
			WHERE TableColumnsID = 2
			') d
	ON	c.FanID = d.FanID 
		AND REPLACE(d.Value,' ','') <> REPLACE(c.Email,' ','')
		AND LEN(REPLACE(d.Value,' ','')) > 5
WHERE	CurrentlyActive = 1
ORDER BY FanID

/*******************************************************************************
********************************Combined list***********************************
*******************************************************************************/
IF OBJECT_ID ('tempdb..#Combined') IS NOT NULL DROP TABLE #Combined
SELECT	*
INTO #Combined
FROM	(
	SELECT	*
	FROM #ActiveCustomers
	WHERE len(email) > 5
UNION ALL
	SELECT	*
	FROM #ActiveAltEmail
	) a
ORDER BY FanID 

/*************************************************************************************
***************************Create table in Insight Archive****************************
*************************************************************************************/
IF OBJECT_ID ('tempdb..#CompleteEmails') IS NOT NULL DROP TABLE #CompleteEmails
SELECT	FanID,
	Surname,
	CAST(Email AS VARCHAR) as Email
INTO #CompleteEmails
FROM #Combined


/************************************************************************************
*******************Create table in Insight Archive with Hashed Data******************
************************************************************************************/

--**MD5
IF @HashType = 1
BEGIN

IF OBJECT_ID ('tempdb..#Hashing_Stage1') IS NOT NULL DROP TABLE #Hashing_Stage1
SELECT	*,
	SUBSTRING(Master.dbo.fn_VarbinToHexstr(HASHBYTES('MD5', Email)), 3, 100) as Hashed_Text
INTO #Hashing_Stage1	
FROM #CompleteEmails
--

--**Find Matched Records
SET @SQLQry =
'
SELECT	h.*
INTO '+@HashedMatchTableName+'
FROM '+@InputTableName+' itn
INNER JOIN #Hashing_Stage1 h
	on itn.MD5_Text = h.Hashed_Text
WHERE h.FanID > 1000
ORDER BY h.FanID
'
EXEC SP_EXECUTESQL @SQLQry
--

END

--**SHA1
ELSE IF @HashType = 2
BEGIN

IF OBJECT_ID ('tempdb..#Hashing_Stage2') IS NOT NULL DROP TABLE #Hashing_Stage2
SELECT	*,
	SUBSTRING(Master.dbo.fn_VarbinToHexstr(HASHBYTES('SHA1', Email)), 3, 100) as Hashed_Text
INTO #Hashing_Stage2	
FROM #CompleteEmails
--

--**Find Matched Records
SET @SQLQry =
'
SELECT	h.*
INTO '+@HashedMatchTableName+'
FROM '+@InputTableName+' itn
INNER JOIN #Hashing_Stage2 h
	on itn.SHA1_Text = h.Hashed_Text
WHERE h.FanID > 1000
ORDER BY h.FanID
'
EXEC SP_EXECUTESQL @SQLQry
--

END


SET @SQLQry =
'
SELECT	*
FROM '+@HashedMatchTableName+'
'
EXEC SP_EXECUTESQL @SQLQry

/*
----------------------------------------------------------------------------------------------
--------------------------------------Find Matches by Share of Wallet Segments -----------------------------------
----------------------------------------------------------------------------------------------
select	G.HTMID,
		G.HTM_Description,
		Count(*) as CustomerCount
from #t2 as t
Left Outer join warehouse.relational.ShareOfWallet_Members AS SOW
	ON	T.FANID = SOW.FanID AND
		sOW.EndDate IS NULL and
		sow.PartnerID = 4478
Left Outer JOIN WAREHOUSE.RELATIONAL.HeadroomTargetingModel_Groups AS G
	ON SOW.HTMID = G.HTMID
Group BY G.HTMID,G.HTM_Description
Order By HTMID
----------------------------------------------------------------------------------------------
--------------------------------------Find Matches by Share of Wallet Segments -----------------------------------
----------------------------------------------------------------------------------------------
select	G.HTMID,
		G.HTM_Description,
		Count(*) as CustomerCount
from #t2 as t
Left Outer join warehouse.relational.ShareOfWallet_Members AS SOW
	ON	T.FANID = SOW.FanID AND
		sOW.EndDate IS NULL and
		sow.PartnerID = 4478
Left Outer JOIN WAREHOUSE.RELATIONAL.HeadroomTargetingModel_Groups AS G
	ON SOW.HTMID = G.HTMID
inner join warehouse.relational.customer as c
	on t.fanid = c.fanid
Where MarketableByEmail = 1
Group BY G.HTMID,G.HTM_Description
Order By HTMID
-------------------------------------------------------------------------
---------------Write Data File of people to Exclude----------------------
-------------------------------------------------------------------------
select	t.FanID
Into Warehouse.InsightArchive.Laithwaites_HashingMatches_20140808
from #t2 as t
Left Outer join warehouse.relational.ShareOfWallet_Members AS SOW
	ON	T.FANID = SOW.FanID AND
		sOW.EndDate IS NULL and
		sow.PartnerID = 4462
Left Outer JOIN WAREHOUSE.RELATIONAL.HeadroomTargetingModel_Groups AS G
	ON SOW.HTMID = G.HTMID
Order by FanID
*/



END