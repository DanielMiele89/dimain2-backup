


-- *****************************************************************************************************
-- Author:		Ijaz Amjad
-- Create date: 02/11/2016
-- Description: 
-- *****************************************************************************************************
CREATE PROCEDURE [Staging].[SSRS_R0136_RetailerOutletTracking_MIDlevel_Apr2015_to_Oct2016](
				@PartnerID INT,
				@ClubID INT
				)
AS						

DECLARE			@PID	INT,
				@CID	INT
SET				@PID =	@PartnerID
SET				@CID =	@ClubID


IF OBJECT_ID ('tempdb..#MIDs') IS NOT NULL DROP TABLE #MIDs
SELECT			PartnerID
,				OutletID
,				MerchantID
,				Address1
,				Address2
,				City
,				PostCode
INTO			#MIDs
FROM			Warehouse.Relational.Outlet
WHERE			PartnerID = @PID

CREATE CLUSTERED INDEX IDX_OutletID ON #MIDs (OutletID)


IF OBJECT_ID ('tempdb..#Data') IS NOT NULL DROP TABLE #Data
CREATE TABLE #Data
(
PartnerID INT NULL,
OutletID INT NULL,
MID VARCHAR(100) NULL,
FirstTransactionDate DATE NULL,
LastTransactionDate DATE NULL,
Address1 VARCHAR(100) NULL,
Address2 VARCHAR(100) NULL,
Town VARCHAR(100) NULL,
Postcode VARCHAR(20) NULL,
April2015 INT NULL,
May2015 INT NULL,
June2015 INT NULL,
July2015 INT NULL,
August2015 INT NULL,
September2015 INT NULL,
October2015 INT NULL,
November2015 INT NULL,
December2015 INT NULL,
January2016 INT NULL,
February2016 INT NULL,
March2016 INT NULL,
April2016 INT NULL,
May2016 INT NULL,
June2016 INT NULL,
July2016 INT NULL,
August2016 INT NULL,
September2016 INT NULL,
October2016 INT NULL
)


INSERT INTO #Data (PartnerID, OutletID, MID, Address1, Address2, Town, Postcode)
SELECT			PartnerID AS PartnerID,
				OutletID AS OutletID,
				MerchantID AS MID,
				Address1 AS Address1,
				Address2 AS Address2,
				City AS Town,
				PostCode As Postcode
FROM			#MIDs


IF OBJECT_ID ('tempdb..#TranCounts') IS NOT NULL DROP TABLE #TranCounts
SELECT			mid.OutletID
,				SUM(	CASE
							WHEN	YEAR(m.TransactionDate) = 2015 AND MONTH(m.TransactionDate) = 4	THEN 1
							ELSE	0
						END) AS Apr2015
,				SUM(	CASE
							WHEN	YEAR(m.TransactionDate) = 2015 AND MONTH(m.TransactionDate) = 5	THEN 1
							ELSE	0
						END) AS May2015
,				SUM(	CASE
							WHEN	YEAR(m.TransactionDate) = 2015 AND MONTH(m.TransactionDate) = 6	THEN 1
							ELSE	0
						END) AS Jun2015
,				SUM(	CASE
							WHEN	YEAR(m.TransactionDate) = 2015 AND MONTH(m.TransactionDate) = 7	THEN 1
							ELSE	0
						END) AS Jul2015
,				SUM(	CASE
							WHEN	YEAR(m.TransactionDate) = 2015 AND MONTH(m.TransactionDate) = 8	THEN 1
							ELSE	0
						END) AS Aug2015
,				SUM(	CASE
							WHEN	YEAR(m.TransactionDate) = 2015 AND MONTH(m.TransactionDate) = 9	THEN 1
							ELSE	0
						END) AS Sep2015
,				SUM(	CASE
							WHEN	YEAR(m.TransactionDate) = 2015 AND MONTH(m.TransactionDate) = 10	THEN 1
							ELSE	0
						END) AS Oct2015
,				SUM(	CASE
							WHEN	YEAR(m.TransactionDate) = 2015 AND MONTH(m.TransactionDate) = 11	THEN 1
							ELSE	0
						END) AS Nov2015
,				SUM(	CASE
							WHEN	YEAR(m.TransactionDate) = 2015 AND MONTH(m.TransactionDate) = 12	THEN 1
							ELSE	0
						END) AS Dec2015
,				SUM(	CASE
							WHEN	YEAR(m.TransactionDate) = 2016 AND MONTH(m.TransactionDate) = 1	THEN 1
							ELSE	0
						END) AS Jan2016
,				SUM(	CASE
							WHEN	YEAR(m.TransactionDate) = 2016 AND MONTH(m.TransactionDate) = 2	THEN 1
							ELSE	0
						END) AS Feb2016
,				SUM(	CASE
							WHEN	YEAR(m.TransactionDate) = 2016 AND MONTH(m.TransactionDate) = 3	THEN 1
							ELSE	0
						END) AS Mar2016
,				SUM(	CASE
							WHEN	YEAR(m.TransactionDate) = 2016 AND MONTH(m.TransactionDate) = 4	THEN 1
							ELSE	0
						END) AS Apr2016
,				SUM(	CASE
							WHEN	YEAR(m.TransactionDate) = 2016 AND MONTH(m.TransactionDate) = 5	THEN 1
							ELSE	0
						END) AS May2016
,				SUM(	CASE
							WHEN	YEAR(m.TransactionDate) = 2016 AND MONTH(m.TransactionDate) = 6	THEN 1
							ELSE	0
						END) AS Jun2016
,				SUM(	CASE
							WHEN	YEAR(m.TransactionDate) = 2016 AND MONTH(m.TransactionDate) = 7	THEN 1
							ELSE	0
						END) AS Jul2016
,				SUM(	CASE
							WHEN	YEAR(m.TransactionDate) = 2016 AND MONTH(m.TransactionDate) = 8	THEN 1
							ELSE	0
						END) AS Aug2016
,				SUM(	CASE
							WHEN	YEAR(m.TransactionDate) = 2016 AND MONTH(m.TransactionDate) = 9	THEN 1
							ELSE	0
						END) AS Sep2016
,				SUM(	CASE
							WHEN	YEAR(m.TransactionDate) = 2016 AND MONTH(m.TransactionDate) = 10	THEN 1
							ELSE	0
						END) AS Oct2016
INTO			#TranCounts
FROM			#MIDs AS mid
INNER JOIN		SLC_Report.dbo.Match AS m
		ON		mid.OutletID = m.RetailOutletID
INNER JOIN		SLC_Report.dbo.Trans AS t
		ON		m.ID = t.MatchID
INNER JOIN		SLC_Report.dbo.Fan AS f
		ON		t.FanID = f.ID
WHERE			m.TransactionDate >= '2015-04-01'
		AND		m.TransactionDate < '2016-11-01'
		AND		f.ClubID = 12
GROUP BY		mid.OutletID


IF OBJECT_ID ('tempdb..#TranDates') IS NOT NULL DROP TABLE #TranDates
SELECT			mid.OutletID
,				MIN(m.TransactionDate) AS FirstTranDate
,				MAX(m.TransactionDate) AS LastTranDate
INTO			#TranDates
FROM			#MIDs AS mid
INNER JOIN		SLC_Report.dbo.Match AS m
		ON		mid.OutletID = m.RetailOutletID
GROUP BY		mid.OutletID


UPDATE			#Data
SET				April2015 = Apr2015
,				May2015 = tc.May2015
,				June2015 = Jun2015
,				July2015 = Jul2015
,				August2015 = Aug2015
,				September2015 = Sep2015
,				October2015 = Oct2015
,				November2015 = Nov2015
,				December2015 = Dec2015
,				January2016 = Jan2016
,				February2016 = Feb2016
,				March2016 = Mar2016
,				April2016 = Apr2016
,				May2016 = tc.May2016
,				June2016 = Jun2016
,				July2016 = Jul2016
,				August2016 = Aug2016
,				September2016 = Sep2016
,				October2016 = Oct2016
FROM			#Data AS d
LEFT JOIN		#TranCounts AS tc
		ON		d.OutletID = tc.OutletID


UPDATE			#Data
SET				FirstTransactionDate = FirstTranDate
,				LastTransactionDate = LastTranDate
FROM			#Data AS d
LEFT JOIN		#TranDates AS td
		ON		d.OutletID = td.OutletID


SELECT			*
FROM			#Data
ORDER BY		10 DESC
,				11 DESC
,				12 DESC
,				13 DESC
,				14 DESC
,				15 DESC
,				16 DESC
,				17 DESC
,				18 DESC
,				19 DESC
,				20 DESC
,				21 DESC
,				22 DESC
,				23 DESC
,				24 DESC
,				25 DESC
,				26 DESC
,				27 DESC
,				28 DESC