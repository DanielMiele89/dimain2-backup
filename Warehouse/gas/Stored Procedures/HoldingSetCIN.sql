-- =============================================
-- Author:		JEA
-- Create date: 08/11/2012
-- Description:	Used by Merchant Processing Module.
-- Sets CINs on transactions in the holding area
-- =============================================
CREATE PROCEDURE gas.HoldingSetCIN
	
AS
BEGIN

	SET NOCOUNT ON;

    UPDATE Staging.CardTransactionHolding SET CIN = i.SourceUID
	FROM Staging.CardTransactionHolding h WITH (NOLOCK)
	INNER JOIN SLC_Report.dbo.IssuerPaymentCard p WITH (NOLOCK) ON h.PaymentCardID = p.PaymentCardID
	INNER JOIN SLC_Report.dbo.IssuerCustomer i WITH (NOLOCK) ON p.IssuerCustomerID= i.ID
	
END