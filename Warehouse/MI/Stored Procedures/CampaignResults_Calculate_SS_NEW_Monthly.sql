-- =============================================
-- Author:		Hayden
-- Create date:	19/08/2016
-- =============================================

CREATE PROCEDURE [MI].[CampaignResults_Calculate_SS_NEW_Monthly] (
    @ClientServicesRef varchar(25)=NULL
    , @StartDate DATE=NULL
    , @CalcStartDate DATE=NULL
    , @CalcEndDate DATE=NULL
    , @isIncomplete bit
    , @isCalculated bit
    , @DatabaseName NVARCHAR(400)='Sandbox'
) AS -- -- unhide this row to modify SP

BEGIN 

    IF @isCalculated = 0 AND @isIncomplete = 0
	   EXEC MI.CampaignResults_Calculate_SS_NEW @ClientServicesRef, @StartDate, @CalcStartDate, @CalcEndDate, @DatabaseName
    ELSE IF @isIncomplete = 1
	   EXEC MI.CampaignResults_Calculate_SS_Incomplete @ClientServicesRef, @StartDate, @CalcStartDate, @CalcEndDate, @DatabaseName = @DatabaseName
	   
END
