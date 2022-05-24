-- =============================================
-- Author:		JEA
-- Create date: 02/06/2016
-- Description:	Sets numbers and percentages in
-- the APW.ControlExposedPercentageMakeup table
-- =============================================
CREATE PROCEDURE APW.ControlMethod_ControlExposedPercentageMakeup_SetValues 

AS
BEGIN

	SET NOCOUNT ON;

	--SET EXPOSED VALUES

	DECLARE @ExposedTotal FLOAT, @ControlTotal FLOAT, @MaxPercentDiff FLOAT, @MaxPercentDiffID TINYINT
		, @DiffControlSize FLOAT, @DiffExposedShare FLOAT, @AdjustedControlTotal FLOAT

	UPDATE c
	SET ExposedSize = e.ExposedSize
	FROM APW.ControlExposedPercentageMakeup c
	INNER JOIN
	(
		SELECT ISNULL(d.DateYear,0) AS DateYear, c.PrePeriodSpendID, COUNT(1) AS ExposedSize
		FROM APW.CustomersActive c
		LEFT OUTER JOIN APW.ControlDates d ON c.FirstTranMonthID = d.ID
		GROUP BY d.DateYear, c.PrePeriodSpendID
	) e ON c.FirstTranYear = e.DateYear AND c.PrePeriodSpendID = e.PrePeriodSpendID

	--SET CONTROL VALUES

	UPDATE c
	SET ControlSize = e.ControlSize
	FROM APW.ControlExposedPercentageMakeup c
	INNER JOIN
	(
		SELECT ISNULL(d.DateYear,0) AS DateYear, c.PrePeriodSpendID, COUNT(1) AS ControlSize
		FROM APW.ControlBase c
		LEFT OUTER JOIN APW.ControlDates d ON c.FirstTranMonthID = d.ID
		GROUP BY d.DateYear, c.PrePeriodSpendID
	) e ON c.FirstTranYear = e.DateYear AND c.PrePeriodSpendID = e.PrePeriodSpendID

	SELECT @ExposedTotal = SUM(ExposedSize), @ControlTotal = SUM(ControlSize)
	FROM APW.ControlExposedPercentageMakeup

	--SET PERCENTAGES

	UPDATE APW.ControlExposedPercentageMakeup
	SET ExposedShare = CAST(ExposedSize AS FLOAT)/@ExposedTotal
		, ControlShare = CAST(ControlSize AS FLOAT)/@ControlTotal

	--FIND THE ROW ON WHICH THE EXPOSED PERCENTAGE EXCEEDS THE CONTROL PERCENTAGE BY THE LARGEST AMOUNT

	SELECT @MaxPercentDiff = MAX(ExposedShare - ControlShare)
	FROM APW.ControlExposedPercentageMakeup

	SELECT @MaxPercentDiffID = 
	(SELECT TOP 1 ID
	FROM APW.ControlExposedPercentageMakeup
	WHERE ExposedShare - ControlShare = @MaxPercentDiff)

	--capture the control size from this row

	SELECT @DiffControlSize = ControlSize, @DiffExposedShare = ExposedShare
	FROM APW.ControlExposedPercentageMakeup
	WHERE ID = @MaxPercentDiffID

	--calculate adjusted control size figures based on this control size and the exposed percentages

	SET @AdjustedControlTotal = @DiffControlSize/@DiffExposedShare

	--calculate adjusted control sizes as equal to the exposed percentages of the adjusted control total

	UPDATE APW.ControlExposedPercentageMakeup
	SET AdjustedControlSize = @AdjustedControlTotal * ExposedShare

END