/*
	Author:			Stuart Barnley
	Date:			23-05-2014

	Description:	This stored procedure is used to populate the report R_0014.

					This pulls out overall Stats for offers loaded into Iron.NominatedOfferMember
					(Targeted Offers) and Iron.TriggerOfferMember (Trigger Offers)

Update:			N/A
					
*/
Create Procedure Staging.SSRS_R0014_NOM_TOM_Stats
as

select 'warehouse.[iron].[NominatedOfferMember]' as TableName,Count(*) as MemberRecords 
from warehouse.[iron].[NominatedOfferMember]
Union all
select 'warehouse.[iron].[TriggerOfferMember]' as TableName,Count(*) as MemberRecords 
from warehouse.[iron].[TriggerOfferMember]