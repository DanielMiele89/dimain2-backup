-- =============================================
-- Author:		<Shaun H>
-- Create date: <19/06/2017>
-- Description:	<Tool Export - Publisher Scaling>
-- =============================================
CREATE PROCEDURE [ExcelQuery].[ROCEFT_PubScaling_Fetch]
AS
BEGIN
	SET NOCOUNT ON;

	SELECT	ClubName
			,ShopperSegment
			,PubRRScaling
	FROM	Warehouse.ExcelQuery.ROCEFT_PubScaling_Segment
END