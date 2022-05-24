-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [MI].[ForecastWeighting_Fetch] 
	(
		@PartnerID INT
	)
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @StartDate DATE, @EndDate DATE, @BrandID SMALLINT

	SET @StartDate = DATEADD(YEAR,-1,DATEFROMPARTS(YEAR(GETDATE()),1,2))
	SET @EndDate = DATEFROMPARTS(YEAR(GETDATE()),1,1)

	SELECT @BrandID = BrandID
	FROM Relational.[Partner]
	WHERE PartnerID = @PartnerID

	CREATE TABLE #Combos(ConsumerCombinationID INT PRIMARY KEY)

	INSERT INTO #Combos(ConsumerCombinationID)
	SELECT ConsumerCombinationID
	FROM Relational.ConsumerCombination
	WHERE BrandID = @BrandID

	SELECT @PartnerID AS RetailerID, DATEADD(DAY, 364, c.CalendarDate) AS ForecastDate, ISNULL(s.Spend,0) AS Spend
	FROM MI.Calendar c
	LEFT OUTER JOIN
	(
		SELECT TranDate, SUM(Amount) AS Spend
		FROM Relational.ConsumerTransaction_MyRewards ct WITH (NOLOCK)
		INNER JOIN #Combos c ON ct.ConsumerCombinationID = c.ConsumerCombinationID
		WHERE TranDate BETWEEN @StartDate AND @EndDate
		GROUP BY TranDate
	) s ON c.CalendarDate = s.TranDate
	WHERE c.CalendarDate BETWEEN @StartDate AND @EndDate
	ORDER BY ForecastDate

END