
/******************************************************************************
-- Author:		Hayden Reid
-- Create date: 23/09/2020
-- Description:	Clears and inserts into Threshold Dates for Mid Transaction Counting.
				This table is looped through in SSIS package

-- Performance Notes:
	If performance over longer periods becomes a problem, consider
		collecting the minimum buckets and then aggregating up to required buckets 
		at a later stage

------------------------------------------------------------------------------
Modification History

[Date] [User]
	- [Description]

******************************************************************************/
CREATE PROCEDURE [Processing].[Masking_ThresholdDates_Build]
AS
BEGIN
	
	----------------------------------------------------------------------
	-- Clear Down
	----------------------------------------------------------------------
	TRUNCATE TABLE Processing.Masking_ThresholdDates;

	----------------------------------------------------------------------
	-- Build set of dates to be used in masking transaction count comparisons
	----------------------------------------------------------------------
	DECLARE @TODAY DATE = GETDATE()


	;WITH Last60Months AS
	(
		SELECT 
			0 AS ID
			, DATEADD(MONTH, -2, @TODAY) AS ThresholdDateStart
			, DATEADD(MONTH, -1, @TODAY) AS ThresholdDateEnd
		UNION ALL
		SELECT
			ID + 1
			, DATEADD(MONTH, -1, ThresholdDateStart)
			, DATEADD(MONTH, -1, ThresholdDateENd)
		FROM Last60Months
		WHERE ID < 60
	)
	INSERT INTO Processing.Masking_ThresholdDates
	SELECT *
	FROM (
		VALUES
			('L5Y', DATEADD(YEAR, -5, @TODAY), @TODAY),
			('L12M', DATEADD(MONTH, -12, @TODAY), @TODAY),
			('L1M', DATEADD(MONTH, -1, @TODAY), @TODAY)
	) x(a,b,c)

	UNION ALL

	SELECT
		CONCAT('R', ID, 'M')
		, ThresholdDateStart
		, ThresholdDateEnd
	FROM Last60Months
	WHERE ID > 0

	RETURN @@rowcount
	
END


