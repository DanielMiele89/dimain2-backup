-- =============================================
-- Author:		<Shaun Hide>
-- Create date: <23rd July 2018>
-- Description:	<Convert the current Warehouse.APW.ContrlAdjusted_Archive table into a slowly changing dimension as it is easier to work with>
-- =============================================
CREATE PROCEDURE ExcelQuery.MVP_Control_Calculate
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF OBJECT_ID('tempdb..#Months') IS NOT NULL DROP TABLE #Months
	SELECT	MonthDate,
			ROW_NUMBER() OVER (ORDER BY MonthDate ASC) AS RowNo
	INTO	#Months
	FROM  (
			SELECT	DISTINCT MonthDate
			FROM	Warehouse.APW.ControlAdjusted_Archive
		  ) a
	WHERE	NOT EXISTS
		(	SELECT	1
			FROM	Warehouse.ExcelQuery.MVP_ControlSCDDates b
			WHERE	a.MonthDate = b.MonthDate	)

	SELECT * FROM #Months

	/* Do your thing here */

	DECLARE @i INT = 1
	DECLARE @MonthDate DATE
	DECLARE @EndDate DATE

	WHILE @i <= (SELECT MAX(RowNo) FROM #Months)
		BEGIN
			SET @MonthDate = (SELECT MonthDate FROM #Months WHERE RowNo = @i)
		
			IF @MonthDate = '2016-11-01'
				BEGIN
					INSERT INTO Warehouse.ExcelQuery.MVP_ControlAdjustedSCD
						SELECT	CINID,
								@MonthDate AS StartDate,
								NULL AS EndDate
						FROM	Warehouse.APW.ControlAdjusted_Archive
						WHERE	MonthDate = @MonthDate
				END
			ELSE
				BEGIN
					SET @EndDate = DATEADD(DAY,-1,@MonthDate)
				
					-- Close old entries
					UPDATE	c
					SET		c.EndDate = @EndDate
					FROM	Warehouse.ExcelQuery.MVP_ControlAdjustedSCD c
					WHERE	c.EndDate IS NULL
						AND	NOT EXISTS
						(	SELECT	1
							FROM	Warehouse.APW.ControlAdjusted_Archive a
							WHERE	MonthDate = @MonthDate
								AND a.CINID = c.CINID )
				
					-- Add new entries
					INSERT INTO Warehouse.ExcelQuery.MVP_ControlAdjustedSCD
						SELECT	CINID,
								@MonthDate AS StartDate,
								NULL AS EndDate
						FROM	Warehouse.APW.ControlAdjusted_Archive a
						WHERE	MonthDate = @MonthDate
							AND	NOT EXISTS
							(	SELECT	1
								FROM	Warehouse.ExcelQuery.MVP_ControlAdjustedSCD b
								WHERE	EndDate IS NULL
									AND	a.CINID = b.CINID	)
				END
		
			INSERT INTO Warehouse.ExcelQuery.MVP_ControlSCDDates
				SELECT @MonthDate

			-- Increment
			SET @i = @i + 1
		END

	ALTER INDEX ALL ON Warehouse.ExcelQuery.MVP_ControlSCDDates REBUILD
END