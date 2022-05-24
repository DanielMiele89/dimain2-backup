-- =============================================
-- Author:		JEA
-- Create date: 31/05/2016
-- Description:	Assigns PseudoActivationMonthID to the
-- section of the control group in the holding table
-- =============================================
CREATE PROCEDURE [APW].[ControlMethod_PseudoActivationMonthID_Assign] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @ControlCount FLOAT, @ExposedCount FLOAT, @FirstTranMonthID INT

	SELECT @FirstTranMonthID = MIN(FirstTranMonthID), @ControlCount = COUNT(1) FROM APW.ControlBase_PseudoActivationAssign
	SELECT @ExposedCount = COUNT(1) FROM APW.CustomersActive WHERE FirstTranMonthID = @FirstTranMonthID

	CREATE TABLE #ExposedCounts(ID INT PRIMARY KEY IDENTITY, ActivatedMonthID INT NOT NULL, ExposedCount INT NOT NULL, ControlCount INT NULL, StartID INT, EndID INT)

	INSERT INTO #ExposedCounts(ActivatedMonthID, ExposedCount)
	SELECT ActivatedMonthID, COUNT(1)
	FROM APW.CustomersActive
	WHERE FirstTranMonthID = @FirstTranMonthID
	GROUP BY ActivatedMonthID
	ORDER BY ActivatedMonthID

	UPDATE #ExposedCounts SET ControlCount = CASE WHEN @ExposedCount = 0 THEN 0 ELSE CAST(ROUND(CAST(ExposedCount AS FLOAT) * (@ControlCount/@ExposedCount),0) AS INT) END

	UPDATE e SET EndID = f.cumul, StartID = f.cumul - e.ControlCount + 1
	FROM #ExposedCounts e
	INNER JOIN (SELECT ID, SUM(ControlCount) OVER(ORDER BY ID RANGE UNBOUNDED PRECEDING) AS Cumul
					FROM #ExposedCounts) f ON e.ID = f.ID

	UPDATE c SET PseudoActivatedMonthID = e.ActivatedMonthID
	FROM APW.ControlBase_PseudoActivationAssign c
	INNER JOIN #ExposedCounts e ON c.ID BETWEEN e.StartID AND e.EndID

	UPDATE c SET PseudoActivatedMonthID = p.PseudoActivatedMonthID
	FROM APW.ControlBase c
	INNER JOIN APW.ControlBase_PseudoActivationAssign p ON c.CINID = p.CINID

	DROP TABLE #ExposedCounts

END