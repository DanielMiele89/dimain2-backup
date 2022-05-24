-- =============================================
-- Author:		JEA
-- Create date: 08/11/2012
-- Description:	Used by Merchant Processing Module.
-- Sets CINIDs in the holding area
-- =============================================
CREATE PROCEDURE gas.HoldingSetCINID
	
AS
BEGIN

	SET NOCOUNT ON;

    UPDATE Staging.CardTransactionHolding SET CINID = c.CINID
	FROM Staging.CardTransactionHolding h WITH (NOLOCK)
	INNER JOIN Relational.CINList C WITH (NOLOCK) ON h.CIN = c.CIN
	
END
