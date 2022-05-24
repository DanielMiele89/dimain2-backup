-- =============================================
-- Author:		JEA
-- Create date: 04/07/2017
-- Description:	Retrieves FanIDs for Quidco R4G customers
-- =============================================
CREATE PROCEDURE [APW].[QuidcoR4GCustomer_Fetch] 

AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT DISTINCT SourceUID
	FROM InsightArchive.QuidcoR4GCustomers
	WHERE SourceUID IS NOT NULL

END