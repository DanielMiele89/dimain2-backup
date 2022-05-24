
/********************************************************************************************
	Name: Staging.RocShopperSegments_Selections_Run
	Desc: To run the pre selections, and campaign selections for RBS automatically
	Auth: Zoe Taylor

	Change History
			Initials Date
				Change Info
	
*********************************************************************************************/

CREATE PROCEDURE Staging.RocShopperSegments_Selections_Run
AS
BEGIN
	
	/******************************************************************		
			Set email date to use as parameter 
	******************************************************************/
	DECLARE @EmailDate date

	SET DATEFIRST 1
	Set @EmailDate = (Select dateadd(day, 3, [Staging].[fnGetStartOfWeek] (getdate())))

	/******************************************************************		
			Execute preselections 
	******************************************************************/
	
	--Exec -- Hayden Procedure

	/******************************************************************		
			Execute Selections 
	******************************************************************/
	
	Exec Staging.CampaignCode_Selections_ShopperSegment_ALS_V3 @EmailDate


END 