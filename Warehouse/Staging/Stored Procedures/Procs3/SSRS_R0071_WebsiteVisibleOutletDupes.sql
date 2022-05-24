

-- *******************************************************************************
-- Author: Suraj Chahal
-- Create date: 15/05/2015
-- Description: Report that looks for MIDs that appear more than once for a partner and are 
--		all not suppressed from web search, add a Partner Parameter
-- *******************************************************************************
CREATE PROCEDURE [Staging].[SSRS_R0071_WebsiteVisibleOutletDupes]
			(
			@PartnerID INT
			)
						
			
AS
BEGIN
	SET NOCOUNT ON;

IF OBJECT_ID ('tempdb..#Partner_PostCodes') IS NOT NULL DROP TABLE #Partner_PostCodes
SELECT	ro.PartnerID,
	p.PartnerName,
	o.PostCode,
	COUNT(1) as TimesPromotedOnWebsite
INTO #Partner_PostCodes
FROM SLC_Report.dbo.RetailOutlet ro
INNER JOIN Warehouse.Relational.Outlet o
	ON ro.ID = o.OutletID
INNER JOIN Warehouse.Relational.Partner p
	ON p.PartnerID = ro.PartnerID
INNER JOIN Warehouse.Relational.Master_Retailer_Table mrt
	ON mrt.PartnerID = p.PartnerID
WHERE	ro.SuppressFromSearch = 0
	AND PostCode <> ''
	AND p.CurrentlyActive = 1
	AND NOT	(
		o.PartnerID = 3960 AND o.Address1 LIKE '%East%' 
		OR o.PartnerID = 3960 AND o.Address1 LIKE '%West%'
		OR o.PartnerID = 3960 AND o.Address1 LIKE '%South%'
		OR o.PartnerID = 3960 AND o.Address1 LIKE '%North%'
		)
GROUP BY ro.PartnerID, p.PartnerName, o.PostCode
HAVING COUNT(1) > 1
ORDER BY COUNT(1) DESC,PartnerName
--(767 row(s) affected)


--DECLARE @PartnerID INT
--SET @PartnerID = '3996'

SELECT	o.MerchantID,
	PartnerName,
	Address1,
	Address2,
	City,
	o.PostCode,
	TimesPromotedOnWebsite,
	ClientServicesRep,
	LastTransaction_PartnerTrans
FROM Warehouse.Relational.Outlet o
INNER JOIN #Partner_PostCodes p
	ON p.PostCode = o.PostCode
	AND o.PartnerID = p.PartnerID
INNER JOIN SLC_Report.dbo.RetailOutlet ro
	ON ro.ID = o.OutletID
LEFT OUTER JOIN (
		SELECT	OutletID,
			MAX(TransactionDate) as LastTransaction_PartnerTrans
		FROM Warehouse.Relational.PartnerTrans WITH (NOLOCK)
		GROUP BY OutletID
		) pt
	ON o.OutletID = pt.OutletID
LEFT OUTER JOIN	(
		SELECT	PartnerID,
			(rs.FirstName+' '+rs.Surname) as ClientServicesRep
		FROM Warehouse.Relational.Master_Retailer_Table mrf
		INNER JOIN Warehouse.Staging.Reward_StaffTable rs
			ON rs.StaffID = mrf.CS_Lead_ID
		)rep
	ON ro.PartnerID = rep.PartnerID
WHERE	ro.SuppressFromSearch = 0
	AND (o.PartnerID = @PartnerID OR @PartnerID = '')
ORDER BY o.PostCode


END