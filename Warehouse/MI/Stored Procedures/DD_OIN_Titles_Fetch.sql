-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE MI.DD_OIN_Titles_Fetch 
	
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @CurrentMonth AS DATE = DATEFROMPARTS(YEAR(GETDATE()),MONTH(GETDATE()),1)
	DECLARE @PrevMonth AS DATE = DATEADD(MONTH,-1, @CurrentMonth)
	DECLARE @YearMonth AS DATE = DATEADD(YEAR, -1, @CurrentMonth)

    SELECT 'Category' AS Category
		, @CurrentMonth As CurrentMonth
		, @PrevMonth AS PreviousMonth
		, 'Monthly Movement' AS MonthlyMovement
		, @YearMonth AS YearMonth
		, 'Yearly Movement' AS YearlyMovement

END