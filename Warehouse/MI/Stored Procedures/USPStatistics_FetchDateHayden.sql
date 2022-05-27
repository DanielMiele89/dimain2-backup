
CREATE PROCEDURE [MI].[USPStatistics_FetchDateHayden] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT StatsDate, 1 AS DateJoinKey
	FROM MI.USPStatistics
	WHERE ID = (SELECT MAX(ID) FROM MI.USPStatistics)

END

