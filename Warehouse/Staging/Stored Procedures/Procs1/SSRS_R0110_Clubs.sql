/*
	Author:			Stuart Barnley
	Date:			03-12-2015

	Description:	This stored procedure is used to populate the report R_0110.

					This pulls off a list of Clubs that are currently active 
					offer based schemes

	Update:			
					
*/
CREATE Procedure [Staging].[SSRS_R0110_Clubs]
as

Select ID,
		Name
from SLC_report.dbo.Club
Where Status = 1 and IsOfferBased = 1
	