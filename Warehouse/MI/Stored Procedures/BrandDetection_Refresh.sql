
-- =============================================
-- Author:		<Hayden Reid>
-- Create date: <18/03/2015>
-- Description:	<Refreshes information for brand detection>
-- =============================================
CREATE PROCEDURE [MI].[BrandDetection_Refresh]
	--WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

	TRUNCATE TABLE MI.BrandDetection

     Declare @MonthCount TinyInt
              ,@StartDate Date
              ,@EndDate Date
 
        Set @MonthCount = 12 
 
        Set @EndDate = DateFromParts(year(GetDate()), month(GetDate()), 1)
        Set @StartDate = DateAdd(month, -@MonthCount, @EndDate)
        Set @EndDate = DateAdd(day, -1, @EndDate)

	INSERT INTO MI.BrandDetection (ConsumerCombinationID, Spend,StartOfMonth)
	SELECT ConsumerCombinationID
		  ,SUM(Amount) AS Spend
		  ,DATEADD(day, 1, EOMONTH(TranDate, - 1)) as StartOfMonth
	FROM Relational.ConsumerTransaction WITH (NOLOCK)
	WHERE TranDate BETWEEN @startDate AND @endDate
	GROUP BY ConsumerCombinationID,DATEADD(day, 1, EOMONTH(TranDate, - 1))


END