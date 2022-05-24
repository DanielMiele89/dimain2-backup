-- =============================================
-- Author:		JEA
-- Create date: 19/06/2017
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE ExcelQuery.ROCEFT_RBS_PaymentMethodSplit_ETLInsightStore_Fetch 
	
AS
BEGIN

	SET NOCOUNT ON;

    SELECT PartnerID
		, BrandID
		, CCMultiplier
	FROM ExcelQuery.ROCEFT_RBS_PaymentMethodSplit

END
GO
GRANT EXECUTE
    ON OBJECT::[ExcelQuery].[ROCEFT_RBS_PaymentMethodSplit_ETLInsightStore_Fetch] TO [BIDIMAINETLUser]
    AS [dbo];

