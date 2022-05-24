-- =============================================
-- Author:		JEA
-- Create date: 20/10/2014
-- Description:	Cleans unnecessary results from data mining output
-- =============================================
CREATE PROCEDURE gas.CTLoad_DataMiningCleanResults_Cleanup 
	WITH EXECUTE AS OWNER
AS
BEGIN
	
	SET NOCOUNT ON;

    DELETE FROM dbo.dmtest WHERE [Expression.$SUPPORT] = 0
	DELETE FROM dbo.dmtest WHERE [Expression.Brand ID] = 943

END
