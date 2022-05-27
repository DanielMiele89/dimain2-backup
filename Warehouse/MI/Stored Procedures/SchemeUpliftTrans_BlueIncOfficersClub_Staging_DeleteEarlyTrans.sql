-- =============================================
-- Author:		JEA
-- Create date: 19/08/2015
-- Description:	
-- =============================================
CREATE PROCEDURE [MI].[SchemeUpliftTrans_BlueIncOfficersClub_Staging_DeleteEarlyTrans]
AS
BEGIN

	SET NOCOUNT ON;

	DELETE FROM MI.SchemeUpliftTrans_Stage
	WHERE Partnerid IN (4325,4326)
	AND TranDate <= '2014-12-28'

	UPDATE MI.SchemeUpliftTrans_Stage
	SET OutletID = 48442
		, PartnerID = 4100
		WHERE OutletID = 109757
	AND AddedDate < '2016-04-09'

END
