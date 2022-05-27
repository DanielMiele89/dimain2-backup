-- =============================================
-- Author:		JEA
-- Create date: 08/11/2012
-- Description:	Used by Merchant Processing Module.
-- Makes sure that all CINs in the holding area
-- are also in the CIN list.
-- =============================================
CREATE PROCEDURE gas.CINList_Refresh
	
AS
BEGIN

	SET NOCOUNT ON;

    INSERT INTO Relational.CINList(CIN)
	SELECT CIN
	FROM Staging.CardTransactionHolding
	EXCEPT
	SELECT CIN
	FROM Relational.CINList
	
END
