-- =============================================
-- Author:		JEA
-- Create date: 19/06/2017
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [ExcelQuery].[ROCEFT_PubScaling_ETLInsightStore_Fetch] 
	
AS
BEGIN

	SET NOCOUNT ON;

    SELECT ClubID 
		, Clubname
		, RR_Scaling
	FROM ExcelQuery.ROCEFT_PubScaling

END
GO
GRANT EXECUTE
    ON OBJECT::[ExcelQuery].[ROCEFT_PubScaling_ETLInsightStore_Fetch] TO [BIDIMAINETLUser]
    AS [dbo];

