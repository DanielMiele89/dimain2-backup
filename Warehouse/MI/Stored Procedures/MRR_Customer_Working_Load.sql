-- =============================================
-- Author:		JEA
-- Create date: 14/10/2015
-- =============================================
CREATE PROCEDURE MI.MRR_Customer_Working_Load 
	(
		@DateID int
		, @partnerid int
	)
AS
BEGIN

	SET NOCOUNT ON;

    SELECT * 
	FROM MI.Staging_Customer_TempCUMLandNonCore
	WHERE DateID = @DateID 
	AND PartnerID=@partnerid

END