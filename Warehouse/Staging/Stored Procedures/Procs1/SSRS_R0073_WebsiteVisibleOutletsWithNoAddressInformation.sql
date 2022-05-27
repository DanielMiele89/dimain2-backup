

-- *******************************************************************************
-- Author: Suraj Chahal
-- Create date: 26/05/2015
-- Description: Report that shows Address info for unsuppressed MIDs where Address1 is blank
-- *******************************************************************************
CREATE PROCEDURE [Staging].[SSRS_R0073_WebsiteVisibleOutletsWithNoAddressInformation]
						
			
AS
BEGIN
	SET NOCOUNT ON;

IF OBJECT_ID ('tempdb..#Partner_PostCodes') IS NOT NULL DROP TABLE #Partner_PostCodes
SELECT	ro.PartnerID,
	p.PartnerName,
	ro.MerchantID,
	f.Address1,
	f.Address2,
	f.City,
	f.PostCode,
	f.County,
	ro.PartnerOutletReference
INTO #Partner_PostCodes
FROM SLC_Report.dbo.RetailOutlet ro
INNER JOIN SLC_Report.dbo.Fan as f
	on	ro.FanID = f.ID
INNER JOIN Warehouse.Relational.Partner p
	ON p.PartnerID = ro.PartnerID
WHERE	(ro.SuppressFromSearch = 0 OR ro.Coordinates IS NOT NULL)
	AND (
	f.Address1 = '' OR LEN(f.Address1) < 2
		OR (f.Address2 = City AND len(f.Address2) > 2)
		OR (f.Address2 IS NULL)
            )
	AND p.CurrentlyActive = 1
--(151 row(s) affected)


SELECT	*
FROM #Partner_PostCodes
Where Len(Coalesce(Address1,'')+Coalesce(Address2,'')+Coalesce(City,'')+Coalesce(Postcode,'')) > 1



END