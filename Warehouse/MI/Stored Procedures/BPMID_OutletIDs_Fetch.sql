-- =============================================
-- Author:		JEA
-- Create date: 24/10/2013
-- Description:	gets a list of BP MIDs and outletIDs
-- =============================================
CREATE PROCEDURE MI.BPMID_OutletIDs_Fetch
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT OutletID, MerchantID AS MID
	FROM Relational.Outlet
	WHERE PartnerID = 3960

END