-- =============================================
-- Author:		Rory Francis
-- Create date: 27/11/2019
-- Description:	Retrieves ConsumerCombination_DD information for AWS File
-- =============================================
CREATE PROCEDURE [AWSFile].[DOPS_ConsumerCombination_DD_Fetch] 
	WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

	SELECT cc.ConsumerCombinationID_DD
		 , cc.OIN
		 , cc.Narrative_RBS
		 , cc.Narrative_VF
		 , cc.BrandID
	FROM Relational.ConsumerCombination_DD cc
    
END
