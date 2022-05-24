-- =============================================
-- Author:		JEA
-- Create date: 07/08/2014
-- Description:	Fetches payment methods available over time for the RBS Portal
-- =============================================
CREATE PROCEDURE [MI].[RBS_CustomerPaymentMethodsAvailable_Fetch]
	
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT FanID, PaymentMethodsAvailableID, StartDate, EndDate
	FROM Relational.CustomerPaymentMethodsAvailable
    
END