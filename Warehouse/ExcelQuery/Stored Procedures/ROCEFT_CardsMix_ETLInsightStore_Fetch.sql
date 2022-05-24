-- =============================================
-- Author:		JEA
-- Create date: 19/06/2017
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [ExcelQuery].[ROCEFT_CardsMix_ETLInsightStore_Fetch] 
	
AS
BEGIN

	SET NOCOUNT ON;

    SELECT PublisherID	
		, PublisherName
		, CardName
		, Proportion_Cardholders
		, Proportion_Cards
	FROM ExcelQuery.ROCEFT_CardsMix

END
GO
GRANT EXECUTE
    ON OBJECT::[ExcelQuery].[ROCEFT_CardsMix_ETLInsightStore_Fetch] TO [BIDIMAINETLUser]
    AS [dbo];

