-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [APW].[PaymentCardExclude_Refresh] 

AS
BEGIN

	SET NOCOUNT ON;

	INSERT INTO [APW].[PaymentCardExclude] (PaymentCardID)
	SELECT	p.PaymentCardID
	FROM [dbo].[IssuerPaymentCard] p
	WHERE NOT EXISTS (	SELECT 1
						FROM [APW].[PaymentCardExclude] e
						WHERE p.PaymentCardID = e.PaymentCardID)
	GROUP BY P.PaymentCardID
	HAVING COUNT(*) > 1

END
