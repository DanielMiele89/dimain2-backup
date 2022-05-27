

-- *******************************************************************************
-- Author: Suraj Chahal
-- Create date: 18/05/2015
-- Description: Shows by Partner the number of their MIDs in GAS and BPD and how many are Suppressed
-- *******************************************************************************
CREATE PROCEDURE [Staging].[SSRS_R0072_MIDCountsWithSuppressionDetails]
			
AS
BEGIN
	SET NOCOUNT ON;


IF OBJECT_ID ('tempdb..#BPD_MIDs') IS NOT NULL DROP TABLE #BPD_MIDs
SELECT	cc.BrandID,
	COUNT(DISTINCT MID) as MIDs_In_BPD
INTO #BPD_MIDs
FROM Warehouse.Relational.ConsumerCombination cc (NOLOCK)
INNER JOIN Warehouse.Relational.Partner p
	ON cc.BrandID = p.BrandID
WHERE p.CurrentlyActive = 1
GROUP BY cc.BrandID



SELECT	o.PartnerID,
	p.PartnerName,
	bpd.MIDs_In_BPD as Total_MIDsInBPD,
	COUNT(DISTINCT o.MerchantID) as Total_MIDsInGAS,
	(COUNT(DISTINCT o.MerchantID)-SUM(CAST(SuppressFromSearch AS TINYINT))) as UnsuppressedMIDs,
	SUM(CASE WHEN SuppressFromSearch = 0 AND GeolocationUpdateFailed = 1 THEN 1 ELSE 0 END) as Unsuppressed_GeoLocation_Failed
FROM Warehouse.Relational.Outlet o
INNER JOIN SLC_Report.dbo.RetailOutlet ro
	ON o.OutletID = ro.ID
INNER JOIN Warehouse.Relational.Partner p
	ON ro.PartnerID = p.PartnerID
LEFT OUTER JOIN #BPD_MIDs bpd
	ON p.BrandID = bpd.BrandID
WHERE p.CurrentlyActive = 1
GROUP BY o.PartnerID, p.PartnerName, bpd.MIDs_In_BPD
ORDER BY p.PartnerName


END