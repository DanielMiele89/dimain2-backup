-- =============================================
-- Author:		JEA
-- Create date: 06/03/2014
-- Description:	Disables the payment gateway secondary index
-- =============================================
CREATE PROCEDURE gas.SideBySide_PaymentGatewaySecondaryIndex_Disable

AS
BEGIN
	
	SET NOCOUNT ON;

    ALTER INDEX IX_Relational_PaymentGatewaySecondaryDetail ON Relational.PaymentGatewaySecondaryDetail DISABLE

END
