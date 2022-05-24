-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [ExcelQuery].[ROCEFT_CreditCardMultiplier_fetch](@brandID int)
	
AS
BEGIN
	SET NOCOUNT ON;
	SELECT  BrandID,
			CCMultiplier
	FROM	Warehouse.ExcelQuery.ROCEFT_RBS_PaymentMethodSplit
	WHERE	BrandID = @brandID


END
