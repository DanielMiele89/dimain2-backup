/*
	Author:			Stuart Barnley
	Date:			23-05-2014

	Description:	This stored procedure is used to populate the report R_0022.

			This report pu

Update:			N/A
					
*/
Create Procedure Staging.SSRS_R0032_ShareOfWallet_Competitors
				 @Date Date
as
Select a.*,bc.CompetitorID,bc.CompetitorName
from 
(SELECT PartnerString,PartnerName_Formated,Mth,Loyalty,CategorySpend,Max(sow.ID) as SOWID
FROM RELATIONAL.ShareofWallet_RunLog as sow
Where Cast(Runtime as date) = @Date
Group by PartnerString,PartnerName_Formated,Mth,Loyalty,CategorySpend
) as a
inner join [Relational].[ShareofWallet_BrandCompetitorLog] as bc
	on a.SOWID = bc.ShareOfWalletID