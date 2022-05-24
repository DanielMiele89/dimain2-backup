/*
	Author:			Stuart Barnley
	Date:			23-05-2014

	Description:	This stored procedure is used to populate the report R_0028.

					This accesses the table Staging.SSRS_CustomerJourneyAssessmentV1_2_RunDate

	Update:			N/A
					
*/
Create Procedure Staging.SSRS_R0028_ReportRunDate
as
Select * from Warehouse.Staging.SSRS_CustomerJourneyAssessmentV1_2_RunDate