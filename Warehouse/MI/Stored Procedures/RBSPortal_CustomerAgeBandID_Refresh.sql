-- =============================================
-- Author:		JEA
-- Create date: 24/04/2014
-- Description:	Refreshes AgeBandID on the customer
-- check table for the RBS MI incremental load
-- =============================================
CREATE PROCEDURE MI.RBSPortal_CustomerAgeBandID_Refresh 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    UPDATE MI.RBSPortal_Customer_Check SET DOB = DATEADD(YEAR, -30, GETDATE()) WHERE DOB IS NULL OR DOB < '1900-01-01' OR DOB > GETDATE()

	UPDATE MI.RBSPortal_Customer_Check SET AgeBandID = a.AgeBandID
	FROM MI.RBSPortal_Customer_Check c
		INNER JOIN MI.RBSPortal_SchemeAgeBand a on c.DOB BETWEEN a.EndDate AND a.StartDate

END
