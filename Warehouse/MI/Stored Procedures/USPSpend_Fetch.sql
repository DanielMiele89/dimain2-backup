-- =============================================
-- Author:		JEA
-- Create date: 12/05/2014
-- Description:	Sources USP statistics report spend section
-- =============================================
CREATE PROCEDURE [MI].[USPSpend_Fetch] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT TranYear, TranSpend
	FROM MI.USPSpend a
	WHERE StatsDate = (SELECT StatsDate FROM MI.USPStatistics WHERE ID = (SELECT MAX(ID) FROM MI.USPStatistics))
	ORDER BY TranYear

END
