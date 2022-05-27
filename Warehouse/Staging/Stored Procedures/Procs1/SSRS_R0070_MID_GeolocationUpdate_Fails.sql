

-- *******************************************************************************
-- Author: Suraj Chahal
-- Create date: 13/05/2015
-- Description: Partner parameter that list all the MIDs that are not suppressed but have not had co-ordinates assigned
-- *******************************************************************************
CREATE PROCEDURE [Staging].[SSRS_R0070_MID_GeolocationUpdate_Fails]
			(
			@PartnerID INT
			)
						
			
AS
BEGIN
	SET NOCOUNT ON;

/*
Report with a Partner parameter that list all the MIDs that are not suppressed but have not had co-ordinates assigned
*/

--DECLARE	@PartnerID INT
--SET @PartnerID = ''

SELECT	ro.PartnerID,
	PartnerName,
	ro.MerchantID,
	o.Address1,
	o.Address2,
	o.City,
	o.PostCode,
	o.PostalSector,
	o.PostArea,
	o.Region,
	CASE WHEN GeolocationUpdateFailed = 1 THEN 'Yes' ELSE 'No' END as GeolocationUpdateFailed,
	rep.ClientServicesRep
FROM SLC_Report.dbo.RetailOutlet ro
INNER JOIN Warehouse.Relational.Outlet o
	ON ro.ID = o.OutletID
INNER JOIN Warehouse.Relational.Partner p
	ON p.PartnerID = ro.PartnerID
LEFT OUTER JOIN	(
		SELECT	PartnerID,
			(rs.FirstName+' '+rs.Surname) as ClientServicesRep
		FROM Warehouse.Relational.Master_Retailer_Table mrf
		INNER JOIN Warehouse.Staging.Reward_StaffTable rs
			ON rs.StaffID = mrf.CS_Lead_ID
		)rep
	ON ro.PartnerID = rep.PartnerID
WHERE	ro.SuppressFromSearch = 0
	AND ro.GeolocationUpdateFailed = 1
	AND (ro.PartnerID = @PartnerID OR @PartnerID = 0)


END