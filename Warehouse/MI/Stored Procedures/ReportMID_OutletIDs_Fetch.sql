-- =============================================
-- Author:		AJS
-- Create date: 11/06/2014
-- Description:	gets a list of BP MIDs and outletIDs by Partnerid
-- =============================================
create PROCEDURE [MI].[ReportMID_OutletIDs_Fetch]
(@PartnerID int)
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT OutletID, MerchantID AS MID
	FROM Relational.Outlet
	WHERE PartnerID = @PartnerID

END