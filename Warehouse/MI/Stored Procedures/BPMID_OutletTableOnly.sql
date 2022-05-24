-- =============================================
-- Author:		JEA
-- Create date: 24/10/2013
-- Description:	Retrieves MIDs on the outlet table but not the BP spreadsheet
-- =============================================
CREATE PROCEDURE [MI].[BPMID_OutletTableOnly]
AS
BEGIN
	
	SET NOCOUNT ON;

   SELECT o.OutletID, CAST(MerchantID AS VARCHAR(50)) AS MID, cast(4 as tinyint) as StatusID
   FROM (SELECT * FROM Relational.Outlet WHERE PartnerID = 3960) O
   LEFT OUTER JOIN MI.Staging_BPMID b on o.OutletID = b.OutletID
   WHERE b.OutletID is null

END