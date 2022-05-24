-- =============================================
-- Author:		Jason Shipp
-- Create date: 19/06/2017
-- Description:	Select all data from Relational.nFI_Partner_Deals table, for refresh of Transform.nFI_Partner_Deals table in AllPublisherWarehouse
-- =============================================

CREATE PROCEDURE MI.nFI_Partner_Deals_Fetch
	
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT * FROM Relational.nFI_Partner_Deals;

END
GO
GRANT EXECUTE
    ON OBJECT::[MI].[nFI_Partner_Deals_Fetch] TO [BIDIMAINETLUser]
    AS [dbo];

