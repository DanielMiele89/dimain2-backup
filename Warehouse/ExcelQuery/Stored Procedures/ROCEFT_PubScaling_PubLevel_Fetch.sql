-- =============================================
-- Author:		<Shaun H>
-- Create date: <19/06/2017>
-- Description:	<Tool Export - Publisher Scaling (Topline)>
-- =============================================
CREATE PROCEDURE [ExcelQuery].[ROCEFT_PubScaling_PubLevel_Fetch]
AS
BEGIN
	SET NOCOUNT ON;

	SELECT	ClubName
			,RR_Scaling
	FROM	Warehouse.ExcelQuery.ROCEFT_PubScaling
END
