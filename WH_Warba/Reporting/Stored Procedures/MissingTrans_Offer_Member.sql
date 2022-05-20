Create PROCEDURE [Reporting].[MissingTrans_Offer_Member]
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT *
	FROM [WH_Warba].[inbound].[Offer_Member]

END;