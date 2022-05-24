CREATE PROCEDURE [MI].[MonthStartDate_Fetch] (@MonthStartDateOutput INT = 0 OUTPUT)
AS
	BEGIN

		DECLARE @MonthStartDate DATETIME = (SELECT	CASE 
														WHEN DAY(GETDATE()) > 14 THEN DATEADD(DAY, 1, EOMONTH(GETDATE(), -1))
														ELSE DATEADD(DAY, 1, EOMONTH(GETDATE(), -2))
													END)

		IF (SELECT GETDATE()) < '2022-03-29' SET @MonthStartDate = DATEADD(MONTH, -1, @MonthStartDate)

		--	SELECT @MonthStartDate
										
		SET @MonthStartDateOutput = CAST(CONVERT(CHAR(8), @MonthStartDate, 112) AS INT)

			
		RETURN @MonthStartDateOutput
	END