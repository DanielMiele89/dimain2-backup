﻿/*
-- Replaces this bunch of stored procedures:
EXEC WHB.Partners_CurrentlyActive_V1_1
EXEC WHB.Partners_UpdateAccountManager
EXEC WHB.Partners_MIDTrackingGAS
EXEC WHB.Partners_DailyAboveBaseOffers_V1_1
EXEC WHB.Partners_PartnerVsBrandsLookup

*/
CREATE PROCEDURE [WHB].[__Partners_Daily_Archived] 
AS 

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;


DECLARE @msg VARCHAR(200), @RowsAffected INT



-------------------------------------------------------------------------------
--EXEC WHB.Partners_CurrentlyActive_V1_1 ####################################
-------------------------------------------------------------------------------
EXEC Monitor.ProcessLog_Insert 'WHB', 'Partners_CurrentlyActive_V1_1', 'Starting'

-------------------------------------------------------------------------------------------
-- CURRENTLY ACTIVE FLAG 

UPDATE Derived.Partner
Set CurrentlyActive = 0


Declare @Date Date = Cast(Getdate() as date)

---Find active offers
if object_id('tempdb..#Offers') is not null drop table #Offers
Select io.IronOfferID,io.PartnerID, case when IronOfferName like '%MFDD%' THEN 2 ELSE 1 END AS OfferType
Into #Offers
From Derived.IronOffer as io
Where IsSignedOff = 1
			AND (io.EndDate IS NULL OR io.EndDate >= GETDATE())
			AND io.IsTriggerOffer = 0
			and StartDate <= @Date

Create Clustered index cix_Offers_IronOfferID on #Offers (IronOfferID)


---Check offers have members
if object_id('tempdb..#CurrentOffers') is not null drop table #CurrentOffers
Select Distinct PartnerID
Into #CurrentOffers
From #Offers as o
inner join slc_report.dbo.ironoffermember as i
	on o.IronOfferID = i.IronOfferID

Create Clustered index cix_CurrentOffers_PartnerID on #CurrentOffers (PartnerID)


---Update partner records
Update Derived.Partner
Set CUrrentlyActive = 1
Where PartnerID in (Select PartnerID from #CUrrentOffers)

-----------------------------------------------------------------------------------------------
-- TRANSACTIONTYPEID FLAG

-- Upcoming offers
if object_id('tempdb..#Offers2') is not null drop table #Offers2
Select io.IronOfferID,io.PartnerID, case when IronOfferName like '%MFDD%' THEN 2 ELSE 1 END AS OfferType
Into #Offers2
From Derived.IronOffer as io
Where --IsSignedOff = 1
			(io.EndDate IS NULL OR io.EndDate >= GETDATE())
			AND io.IsTriggerOffer = 0
		--	and StartDate <= @Date


Update p
Set TransactionTypeID = OfferType
from Derived.Partner p
Left join #Offers2 o 
	on o.PartnerID = p.PartnerID
where p.TransactionTypeID is null

EXEC Monitor.ProcessLog_Insert 'WHB', 'Partners_CurrentlyActive_V1_1', 'Finished'




-------------------------------------------------------------------------------
--EXEC WHB.Partners_UpdateAccountManager ####################################
-------------------------------------------------------------------------------
EXEC Monitor.ProcessLog_Insert 'WHB', 'Partners_UpdateAccountManager', 'Starting'


-- 2.1. Fetch current partner details from [APW].[Retailer]
IF OBJECT_ID('tempdb..#PartnerAccountManager') IS NOT NULL DROP TABLE #PartnerAccountManager
SELECT *
INTO #PartnerAccountManager
FROM [Selections].[PartnerAccountManager]
WHERE EndDate IS NULL


-- 2.2. Fetch partner details from [APW].[Retailer]
IF OBJECT_ID ('tempdb..#Retailer') IS NOT NULL DROP TABLE #Retailer
SELECT *
INTO #Retailer
FROM Warehouse.[APW].[Retailer]
WHERE AccountManager != ''	


-- 3.	Add missing retailers
IF OBJECT_ID('tempdb..#MissingRetailer') IS NOT NULL DROP TABLE #MissingRetailer
SELECT ID AS RetailerID
		, RetailerName
		, AccountManager
INTO #MissingRetailer
FROM Warehouse.[APW].[Retailer] re
WHERE AccountManager != ''
AND NOT EXISTS (SELECT 1
				FROM #PartnerAccountManager pam
				WHERE re.ID = pam.PartnerID)	
						
INSERT INTO #MissingRetailer
SELECT pa.ID
		, pa.Name
		, mr.AccountManager
FROM #MissingRetailer mr
INNER JOIN Warehouse.[iron].[PrimaryRetailerIdentification] pri
	ON mr.RetailerID = pri.PrimaryPartnerID
INNER JOIN [SLC_Report].[dbo].[Partner] pa
	ON pri.PartnerID = pa.ID
WHERE NOT EXISTS (SELECT 1
					FROM #PartnerAccountManager pam
					WHERE pa.ID = pam.PartnerID)
	
INSERT INTO [Selections].[PartnerAccountManager]
SELECT RetailerID
		, RetailerName
		, AccountManager
		, GETDATE()
		, NULL
	FROM #MissingRetailer


--4.	Update retailers who have changed AM
IF OBJECT_ID ('tempdb..#UpdatedAccountManagers') IS NOT NULL DROP TABLE #UpdatedAccountManagers
SELECT pam.ID
		, r.ID AS RetailerID
		, r.RetailerName AS RetailerName
		, pam.AccountManager AS CurrentAccountManager
		, r.AccountManager AS NewAccountManager
INTO #UpdatedAccountManagers
FROM #Retailer r
INNER JOIN #PartnerAccountManager pam
	ON pam.PartnerID = r.ID
	AND r.AccountManager != pam.AccountManager
WHERE r.AccountManager != 'Nick'
AND r.AccountManager != 'Nick / Tom'

INSERT INTO #UpdatedAccountManagers
SELECT pam.ID
		, pa.ID
		, pa.Name
		, uam.CurrentAccountManager
		, uam.NewAccountManager
FROM #UpdatedAccountManagers uam
INNER JOIN Warehouse.[iron].[PrimaryRetailerIdentification] pri
	ON uam.RetailerID = pri.PrimaryPartnerID
INNER JOIN [SLC_Report].[dbo].[Partner] pa
	ON pri.PartnerID = pa.ID
INNER JOIN #PartnerAccountManager pam
	ON pa.ID = pam.PartnerID

UPDATE pam
	SET EndDate = DATEADD(DAY, -1, GETDATE())
FROM [Selections].[PartnerAccountManager] pam
INNER JOIN #UpdatedAccountManagers uam
	ON pam.ID = uam.ID
	
INSERT INTO [Selections].[PartnerAccountManager]
SELECT RetailerID
		, RetailerName
		, NewAccountManager
		, GETDATE()
		, NULL
FROM #UpdatedAccountManagers


/***********************************************************************************************************************
	5.	Update the Relational.Partner table, setting AccountManager to Unassigned where no entry is found
***********************************************************************************************************************/

Update pa
	Set AccountManager = ISNULL(am.AccountManager,'Unassigned')
FROM Derived.Partner pa
Left join #PartnerAccountManager am
	on pa.PartnerID = am.PartnerID

EXEC Monitor.ProcessLog_Insert 'WHB', 'Partners_UpdateAccountManager', 'Finished'




-------------------------------------------------------------------------------
--EXEC WHB.Partners_MIDTrackingGAS ############################################
-------------------------------------------------------------------------------
EXEC Monitor.ProcessLog_Insert 'WHB', 'Partners_MIDTrackingGAS', 'Starting'
EXEC WHB.Partners_MIDTrackingGAS
EXEC Monitor.ProcessLog_Insert 'WHB', 'Partners_MIDTrackingGAS', 'Finished'




-------------------------------------------------------------------------------
--EXEC WHB.Partners_DailyAboveBaseOffers_V1_1 #################################
-------------------------------------------------------------------------------
EXEC Monitor.ProcessLog_Insert 'WHB', 'Partners_DailyAboveBaseOffers_V1_1', 'Starting'

DECLARE @OutputCount INT = DATEDIFF(DAY,'Jan 01, 2013',GETDATE())+1
 
IF OBJECT_ID ('tempdb..#Calendar') IS NOT NULL DROP TABLE #Calendar;
WITH 
	E1 AS (SELECT n = 0 FROM (VALUES (0),(0),(0),(0),(0),(0),(0),(0),(0),(0)) d (n)),
	E2 AS (SELECT n = 0 FROM E1 a, E1 b),
	Numbers AS (SELECT TOP(@OutputCount) n = CAST(ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS INT) FROM E2 a, E2 b)
SELECT ID = n, StartDate = DATEADD(DAY,1-n,CAST(GETDATE() AS DATE)) 
INTO #Calendar 
FROM Numbers
OPTION (OPTIMIZE FOR (@OutputCount = 2559));

CREATE UNIQUE CLUSTERED INDEX ucx_Stuff On #Calendar (StartDate);


TRUNCATE TABLE Derived.Partner_AboveBaseOffers_PerDay
INSERT INTO Derived.Partner_AboveBaseOffers_PerDay (DayDate, PartnerID, AboveBaseOffer)
SELECT 
	DayDate = cp.StartDate,
	cp.PartnerID,
	AboveBaseOffer = ISNULL(x.Abovebase,0)
FROM (SELECT * FROM Derived.[Partner] p CROSS JOIN #Calendar c) cp
LEFT JOIN (
	SELECT  
		cp.StartDate, i.PartnerID, i.Abovebase
	FROM Derived.IronOffer i
	INNER JOIN #Calendar cp
		ON cp.StartDate BETWEEN i.StartDate AND i.EndDate 
			AND i.Abovebase = 1 
			AND i.IsTriggerOffer = 0 
			AND i.ironofferName <> '(Demo) special offer'
	GROUP BY cp.StartDate, i.PartnerID, i.Abovebase
) x ON x.PartnerID = cp.PartnerID AND x.StartDate = cp.StartDate;

EXEC Monitor.ProcessLog_Insert 'WHB', 'Partners_DailyAboveBaseOffers_V1_1', 'Finished'




-------------------------------------------------------------------------------
--EXEC WHB.Partners_PartnerVsBrandsLookup #####################################
-------------------------------------------------------------------------------
EXEC Monitor.ProcessLog_Insert 'WHB', 'Partners_PartnerVsBrandsLookup', 'Starting'


IF OBJECT_ID ('tempdb..#InitialBrandIDs') IS NOT NULL DROP TABLE #InitialBrandIDs;
;WITH FilteredSet AS (
	SELECT PartnerID, PrimaryPartnerID, GroupNo = DENSE_RANK() OVER(ORDER BY PrimaryPartnerID) 
	FROM Warehouse.Iron.PrimaryRetailerIdentification 
	WHERE PrimaryPartnerID is not null
),
MultiplePartners AS (
	SELECT PartnerID, PrimaryPartnerID, GroupNo
	FROM FilteredSet 
	UNION ALL
	SELECT PartnerID = PrimaryPartnerID, PrimaryPartnerID, GroupNo
	FROM FilteredSet
	GROUP BY PrimaryPartnerID, GroupNo
)
SELECT	mp.*,
	BrandID 
INTO #InitialBrandIDs
FROM MultiplePartners mp
LEFT JOIN Warehouse.MI.PartnerBrand pb
	ON mp.PartnerID = pb.PartnerID


--Duplicate Brand IDs identified for secondary records
UPDATE a
SET a.BrandID = b.BrandID
FROM #InitialBrandIDs as a
inner join #InitialBrandIDs as b
	on	a.PrimaryPartnerID = b.PrimaryPartnerID and
		a.PartnerID <> b.PartnerID and
		a.BrandID is null and
		b.BrandID is not null


--Delete Rows that could not be matched
DELETE FROM #InitialBrandIDs
WHERE BrandID is null


--Create Table with contents of MI table and this new data combined
TRUNCATE TABLE Staging.Partners_Vs_Brands
INSERT INTO Staging.Partners_Vs_Brands
SELECT * 
FROM Warehouse.MI.PartnerBrand as pb
UNION
SELECT	PartnerID, BrandID
FROM	#InitialBrandIDs
--Order by BrandID

EXEC Monitor.ProcessLog_Insert 'WHB', 'Partners_PartnerVsBrandsLookup', 'Finished'




RETURN 0



