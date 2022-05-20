Create PROCEDURE [Reporting].[MissingTrans_Calendar]
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT *
	FROM [WH_Warba].[inbound].[Calendar]


END;