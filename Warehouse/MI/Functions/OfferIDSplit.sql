-- =============================================
-- Author:		JEA
-- Create date: 12/06/2018
-- Description:	Returns a list of events for a brand
-- compatible with a monthly time series
-- =============================================
CREATE FUNCTION MI.OfferIDSplit 
(
	@OfferIDs VARCHAR(40)
)
RETURNS 
@OfferIDTable TABLE(OfferID INT)
AS
BEGIN
	
	DECLARE @x XML 

	SELECT @x = CAST('<A>'+ REPLACE(@OfferIDs,',','</A><A>')+ '</A>' AS XML)

    INSERT INTO @OfferIDTable(OfferID)

	SELECT DISTINCT inval
	FROM
	(
		SELECT t.value('.', 'int') as inVal
		FROM @x.nodes('/A') as x(t)
	) s
	WHERE inVal != 0
	
	RETURN 
END