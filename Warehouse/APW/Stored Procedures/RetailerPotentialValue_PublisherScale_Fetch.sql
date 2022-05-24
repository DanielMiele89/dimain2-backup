-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE APW.RetailerPotentialValue_PublisherScale_Fetch

AS
BEGIN

	SET NOCOUNT ON;

	SELECT ClubID AS PublisherID, RR_Scaling
	FROM ExcelQuery.ROCEFT_PubScaling
	WHERE ClubID = 12 --only scale quidco for now

END