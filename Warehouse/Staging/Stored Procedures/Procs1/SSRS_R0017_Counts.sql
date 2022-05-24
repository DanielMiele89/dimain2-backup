/*
	Author:			Stuart Barnley
	Date:			23-05-2014

	Description:	This stored procedure is used to populate the report R_0017.

					This gives a count of members in lion.NominatedLionSendComponent

Update:			N/A
					
*/
Create Procedure Staging.SSRS_R0017_Counts
				 @LionSendID int
as
select COUNT(distinct CompositeID) as CustomerCount
from lion.NominatedLionSendComponent
Where LionSendID = @LionSendID