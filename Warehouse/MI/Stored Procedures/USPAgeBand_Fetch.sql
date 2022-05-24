-- =============================================
-- Author:		JEA
-- Create date: 11/03/2014
-- Description:	Sources USP statistics report age band section
-- =============================================
CREATE PROCEDURE MI.USPAgeBand_Fetch 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT b.AgeBandID
		, b.BandDesc AS AgeBand
		, a.CustomerCount
	FROM MI.USPAgeBand a
	INNER JOIN MI.AgeBand b ON a.AgeBandID = b.AgeBandID
	WHERE StatsDate = (SELECT StatsDate FROM MI.USPStatistics WHERE ID = (SELECT MAX(ID) FROM MI.USPStatistics))

END
