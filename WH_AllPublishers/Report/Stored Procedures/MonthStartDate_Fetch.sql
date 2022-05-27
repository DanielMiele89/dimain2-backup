CREATE PROCEDURE [Report].[MonthStartDate_Fetch] (@MonthStartDateOutput INT = 0 OUTPUT)
AS
	BEGIN

		--	DATEADD(MONTH,-1,DATEFROMPARTS(YEAR(GETDATE()),MONTH(GETDATE()),1))

		DECLARE @Today DATETIME = GETDATE()

		--SET @Today = DATEADD(DAY, -9, @Today)

		DECLARE @MonthStartDate DATETIME = (SELECT	CASE 
														WHEN DAY(@Today) > 25 THEN DATEADD(DAY, 1, EOMONTH(@Today, -1))
														ELSE DATEADD(DAY, 1, EOMONTH(@Today, -2))
													END)

		IF GETDATE() < '2021-09-23 11:30:00' SET @MonthStartDate = DATEADD(MONTH, -1, @MonthStartDate)	--	For calculating previous months

		--SELECT @MonthStartDate

		SET @MonthStartDateOutput = CAST(CONVERT(CHAR(8), @MonthStartDate, 112) AS INT)
			
		RETURN @MonthStartDateOutput
	END