
-- *******************************************************************************
-- Author: Suraj Chahal
-- Create date: 18/08/2015
-- Description: Run GeoDem HeatMap for an Individual Partner - Takes 
--		PartnerID Parameter
-- *******************************************************************************
CREATE PROCEDURE [Staging].[GeoDemographicHeatMap_AllSteps_IndividualRun]
				(@PartnerID_Indiv INT)
	WITH EXECUTE AS OWNER	
AS
BEGIN
	SET NOCOUNT ON;


EXEC Staging.GeoDemographicHeatMap_01_CollatingFanGeoDemData_Individual @PartnerID_Indiv
EXEC Staging.GeoDemographicHeatMap_02_Build_RetailerProfiling_LookUpTable_Individual @PartnerID_Indiv
EXEC Staging.GeoDemographicHeatMap_03_UpdatingGeoDemMembers_Individual @PartnerID_Indiv


END