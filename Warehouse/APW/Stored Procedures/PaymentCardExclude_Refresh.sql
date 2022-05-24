-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE APW.PaymentCardExclude_Refresh 

AS
BEGIN

	SET NOCOUNT ON;

	INSERT INTO APW.PaymentCardExclude(PaymentCardID)
	SELECT PaymentCardID
	FROM
	(
		SELECT P.PaymentCardID, COUNT(*) AS Freq
		FROM SLC_Report.dbo.IssuerPaymentCard p
		LEFT OUTER JOIN APW.PaymentCardExclude e ON p.PaymentCardID = e.PaymentCardID
		WHERE e.PaymentCardID IS NULL
		GROUP BY P.PaymentCardID
		HAVING COUNT(*) > 1
	) P

END
