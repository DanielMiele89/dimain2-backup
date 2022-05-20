Create PROCEDURE [Reporting].[MissingTrans_Customer]
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT * 
	FROM [WH_Warba].[inbound].[Customer]

END