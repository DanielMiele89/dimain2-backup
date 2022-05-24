-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [AWSFile].[ConsumerTransaction_DDLoadDates_Fetch_Initial] @Date Date

AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @OneYearLater DATE = DATEADD(YEAR, 1, @Date)

    SELECT DISTINCT TranDate
	FROM Relational.ConsumerTransaction_DD
	WHERE TranDate > @Date
	AND TranDate < @OneYearLater
	ORDER BY TranDate
	
END