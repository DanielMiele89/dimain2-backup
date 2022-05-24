/*
	Author:			Stuart Barnley
	Date:			23-05-2014

	Description:	This stored procedure is used to populate the report R_0032.

					This is the report to pull the Share of Wallet Stats

Update:			N/A
					
*/

Create Procedure Staging.SSRS_R0032_ShareOfWalletStats
				 @Date Date
as
Select	PartnerString,
		PartnerName_Formated,
		Mth,Loyalty,
		CategorySpend,
		SOWID,
		sc.HTMID,
		g.HTM_Description,
		sc.Members,
		PCT_Customer,
		Case when AverageSpend < 0 then 0 Else AverageSpend End as AverageSpend,
		AverageLoyalty
From
(
SELECT PartnerString,PartnerName_Formated,Mth,Loyalty,CategorySpend,Max(sow.ID) as SOWID
FROM RELATIONAL.ShareofWallet_RunLog as sow
Where Cast(Runtime as date) = @Date
Group by PartnerString,PartnerName_Formated,Mth,Loyalty,CategorySpend
) as a
inner join Relational.ShareOfWallet_SegmentCounts as sc
	on a.SOWID = sc.ShareofWalletID
inner join [Relational].[HeadroomTargetingModel_Groups] as g
	on sc.htmid = g.htmid