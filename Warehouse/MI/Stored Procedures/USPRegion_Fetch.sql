-- =============================================
-- Author:		JEA
-- Create date: 11/03/2014
-- Description:	Sources USP statistics report region section
-- =============================================
CREATE PROCEDURE MI.USPRegion_Fetch 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT Region, CustomerCount
	FROM MI.USPRegion a
	WHERE StatsDate = (SELECT StatsDate FROM MI.USPStatistics WHERE ID = (SELECT MAX(ID) FROM MI.USPStatistics))

END