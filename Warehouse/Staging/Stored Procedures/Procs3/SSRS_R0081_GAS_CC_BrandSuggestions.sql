

-- *****************************************************************************************************
-- Author: Suraj Chahal
-- Create date: 24/06/2015
-- Description: Find outlets we have in GAS but are not branded for the retailer in Consumer Combination 
--		Only for GB
-- *****************************************************************************************************
CREATE PROCEDURE [Staging].[SSRS_R0081_GAS_CC_BrandSuggestions]
						
			
AS
BEGIN
	SET NOCOUNT ON;


/******************************************************************************
*******Finding MIDS for currently active Partners from the Outlet table********
******************************************************************************/
IF OBJECT_ID ('tempdb..#Outlets') IS NOT NULL DROP TABLE #Outlets
SELECT	p.PartnerID,
	PartnerName,
	p.BrandID,
	o.OutletID,
	o.MerchantID as MID
INTO #Outlets
FROM Warehouse.Relational.Outlet o
INNER JOIN Warehouse.Relational.Partner p
	ON o.PartnerID = p.PartnerID
	--AND p.CurrentlyActive = 1
INNER JOIN SLC_Report.dbo.RetailOutlet ro
	ON o.OutletID = ro.ID
--(13326 row(s) affected)


/***********************************************************************************
****Transform the MID adding a leading zero where there isn't one and taking********
**************************one away where there already is***************************
***********************************************************************************/
INSERT INTO #Outlets
SELECT	PartnerID,
	PartnerName,
	BrandID,
	OutletID,
	CASE
		WHEN LEFT(MID,1) = '0' THEN RIGHT(MID,(LEN(MID)-1))
                ELSE '0'+MID
	END as MID
FROM #Outlets
--(13326 row(s) affected)



/*********************************************************************
***Find outlets we have in GAS but are not branded for the retailer***
****************in Consumer Combination - Only for GB*****************
*********************************************************************/
IF OBJECT_ID ('tempdb..#OutletsInCCID') IS NOT NULL DROP TABLE #OutletsInCCID
SELECT	o.PartnerID as GAS_PartnerID,
	o.PartnerName as GAS_PartnerName,
	o.BrandID as GAS_BrandID,
	o.OutletID as GAS_OutletID,
	o.MID as GAS_MID,
	cc.MID as CC_MID,
	cc.ConsumerCombinationID,
	cc.BrandID as CC_BrandID,
	cc.Narrative as CC_Narrative,
	mcc.MCCDesc as MCCDescription
INTO #OutletsInCCID
FROM #Outlets o
INNER JOIN warehouse.Relational.ConsumerCombination cc
	ON o.MID = cc.MID
INNER JOIN Warehouse.Relational.MCCList mcc
	ON cc.MCCID = mcc.MCCID
WHERE	cc.BrandID = 944
	AND LocationCOuntry = 'GB'
--(373 row(s) affected)

TRUNCATE TABLE Warehouse.Staging.R_0081_GAS_CC_BrandSuggestions


INSERT INTO Warehouse.Staging.R_0081_GAS_CC_BrandSuggestions
SELECT	*
FROM #OutletsInCCID 
WHERE GAS_PartnerID NOT IN (4447,3432,4326,4325,4513,3724)



SELECT	gas.*
FROM Warehouse.Staging.R_0081_GAS_CC_BrandSuggestions gas
LEFT OUTER JOIN Warehouse.Staging.R_0081_Exclusions gas2
	ON gas.GAS_BrandID = gas2.GAS_BrandID
	AND gas.ConsumerCombinationID = gas2.ConsumerCombinationID
WHERE	gas2.ConsumerCombinationID IS NULL
ORDER BY gas.GAS_PartnerName

END