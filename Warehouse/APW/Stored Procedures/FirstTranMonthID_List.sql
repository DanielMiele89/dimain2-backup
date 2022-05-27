-- =============================================
-- Author:		JEA
-- Create date: 31/05/2016
-- Description:	List of FirstTranMonthIDs from APW.CustomersActive
-- =============================================
CREATE PROCEDURE APW.FirstTranMonthID_List 

AS
BEGIN

	SET NOCOUNT ON;

    SELECT DISTINCT FirstTranMonthID
	FROM APW.CustomersActive
	ORDER BY FirstTranMonthID

END
