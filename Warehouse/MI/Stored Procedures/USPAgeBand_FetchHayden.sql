-- =============================================
-- Author:		JEA
-- Create date: 11/03/2014
-- Description:	Sources USP statistics report age band section
-- =============================================
CREATE PROCEDURE [MI].[USPAgeBand_FetchHayden] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

	    SELECT b.AgeBandID
		, b.BandDesc AS AgeBand
		, a.CustomerCount
		, a.PublisherName
	FROM MI.USPAgeBandHayden a
	INNER JOIN MI.AgeBand b ON a.AgeBandID = b.AgeBandID
	WHERE StatsDate = (SELECT MAX(StatsDate) FROM MI.USPStatistics)

END
