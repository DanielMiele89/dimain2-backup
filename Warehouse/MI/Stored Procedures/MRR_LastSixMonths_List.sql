-- =============================================
-- Author:		JEA
-- Create date: 03/06/2015
-- Description:	List of last 6 months
-- =============================================
CREATE PROCEDURE MI.MRR_LastSixMonths_List 
	(
		@DateID INT
	)
AS
BEGIN

	SET NOCOUNT ON;

    SELECT ID, MonthDesc
	FROM Relational.SchemeUpliftTrans_Month
	WHERE ID BETWEEN @DateID - 5 AND @DateID
	ORDER BY ID

END