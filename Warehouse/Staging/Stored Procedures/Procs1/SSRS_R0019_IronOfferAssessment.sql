/*
	Author:			Stuart Barnley
	Date:			23-05-2014

	Description:	This stored procedure is used to populate the report R_0019.

					

Update:			N/A
					
*/
Create Procedure Staging.SSRS_R0019_IronOfferAssessment
				 @TableName varchar(300)
as

Select * from [Staging].[PostSFDEmailEvaluation_IronOfferAssessment]
Where @TableName = TableName