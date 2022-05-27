-- =============================================
-- Author:		JEA
-- Create date: 30/06/2016
-- Description:	Rebuilds key campaign history indexes
-- =============================================
CREATE PROCEDURE MI.CampaignHistoryIndexes_Rebuild
	WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

    ALTER INDEX ALL ON Warehouse.Relational.Campaign_History_UC_Spenders REBUILD 
	ALTER INDEX ALL ON Warehouse.Relational.Campaign_History_Spenders REBUILD 

END
