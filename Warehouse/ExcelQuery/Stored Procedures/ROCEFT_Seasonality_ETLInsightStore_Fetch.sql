-- =============================================
-- Author:		JEA
-- Create date: 19/06/2017
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE ExcelQuery.ROCEFT_Seasonality_ETLInsightStore_Fetch 
	
AS
BEGIN

	SET NOCOUNT ON;

    SELECT BrandID
		, Seasonality_Cycle
		, Spend_Index
		, Txns_Index
		, Spenders_Index
	FROM ExcelQuery.ROCEFT_Seasonality

END

GO
GRANT EXECUTE
    ON OBJECT::[ExcelQuery].[ROCEFT_Seasonality_ETLInsightStore_Fetch] TO [BIDIMAINETLUser]
    AS [dbo];

