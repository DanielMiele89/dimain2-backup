-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
create PROCEDURE [AWSFile].[BrandCombinationCutDown_Fetch]
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT cc.ConsumerCombinationID
		, cc.BrandID
	FROM Relational.ConsumerCombination cc
	WHERE cc.BrandID NOT IN (943,944,1293)

END