/*
	Author:			Stuart Barnley
	Date:			23-05-2014

	Description:	This stored procedure is used to populate the report R_0014.

					This pulls out overall Stats for offers loaded into Iron.NominatedOfferMember
					(Targeted Offers) and Iron.TriggerOfferMember (Trigger Offers)

Update:			N/A
					
*/
CREATE Procedure [Staging].[SSRS_R0014_NOM_TOM_Stats_V2]
as

select 'Warehouse.Iron.OfferMemberAddition' as TableName,Count(*) as MemberRecords 
from Warehouse.[iron].[OfferMemberAddition] oma
INNER JOIN Warehouse.Relational.IronOffer io
	ON oma.IronOfferID = io.IronOfferID 
Union all
select 'Warehouse.Iron.TriggerOfferMember' as TableName,Count(*) as MemberRecords 
from warehouse.[iron].[TriggerOfferMember]