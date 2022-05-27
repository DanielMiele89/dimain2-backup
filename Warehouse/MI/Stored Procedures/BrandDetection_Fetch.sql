-- =============================================
-- Author:		<Hayden Reid>
-- Create date: <18/03/2015>
-- Description:	<Sources spend information for brand detection>
-- =============================================
CREATE PROCEDURE MI.BrandDetection_Fetch
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @startDate DATE, @endDate DATE

	SET @startDate = getDate()

	SET @startDate = DATEADD(DAY, 1, EOMONTH(@startDate, -2))

	SET @endDate = EOMONTH(@startDate)
	
	--select @startdate, @endDate

    -- Insert statements for procedure here
	SELECT ConsumerCombinationID, SUM(Amount) AS Spend
	FROM Relational.ConsumerTransaction 
	WHERE TranDate BETWEEN @startDate AND @endDate
	GROUP BY ConsumerCombinationID

END
