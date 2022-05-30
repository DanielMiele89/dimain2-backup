----GO
CREATE FUNCTION Processing.getSLATimeDiff(@SLA_ID INT)
RETURNS INT
AS
BEGIN
	DECLARE @TimeDiff INT
	
	SELECT
		@TimeDiff = 24 - (-Processing.getTimeDiff()-SLATime) -- calculate how many hours from the offset until the SLA
	FROM
	(
		SELECT
			ROW_NUMBER() OVER (ORDER BY SLATIME) ID
			, *
		FROM (
			VALUES
				(3)
				, (8)
		)x(SLATime)
	) x
	WHERE x.ID = @SLA_ID

	RETURN @TimeDiff

END
