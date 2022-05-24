-- =============================================
-- Author:		JEA
-- Create date: 15/02/2017
-- Description:	Retrieves PanPaymentCard records with change dates
-- =============================================
CREATE PROCEDURE APW.PanPaymentCardUpdate_Fetch

AS
BEGIN

	SET NOCOUNT ON;

    SELECT p.ID AS PanID
		, p.DuplicationDate
		, p.RemovalDate
	FROM SLC_Report.DBO.Pan p
	INNER JOIN APW.PansUnremoved u ON P.ID = u.PanID
	WHERE p.RemovalDate IS NOT NULL
	OR (u.DuplicationDate IS NULL AND p.DuplicationDate IS NOT NULL)

END
