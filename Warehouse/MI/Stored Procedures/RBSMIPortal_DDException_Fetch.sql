-- =============================================
-- Author:		JEA
-- Create date: 04/03/2016
-- Description:	Fetches DD exceptions for transport to the MI Portal
-- =============================================
CREATE PROCEDURE MI.RBSMIPortal_DDException_Fetch
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT ID
		, ClubID
		, CIN
		, FanID
		, TransactionDate
		, SMonth
		, OIN
		, Narrative
		, TransactionAmount
	FROM MI.RBSMIPortal_DDException

END
