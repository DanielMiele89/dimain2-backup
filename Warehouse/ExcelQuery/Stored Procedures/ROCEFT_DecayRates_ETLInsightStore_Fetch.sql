-- =============================================
-- Author:		JEA
-- Create date: 19/06/2017
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE ExcelQuery.ROCEFT_DecayRates_ETLInsightStore_Fetch 
	
AS
BEGIN

	SET NOCOUNT ON;

    SELECT BrandID
		, LapsedAcquire
		, ShopperLapsed
	FROM ExcelQuery.ROCEFT_DecayRates

END

GO
GRANT EXECUTE
    ON OBJECT::[ExcelQuery].[ROCEFT_DecayRates_ETLInsightStore_Fetch] TO [BIDIMAINETLUser]
    AS [dbo];

