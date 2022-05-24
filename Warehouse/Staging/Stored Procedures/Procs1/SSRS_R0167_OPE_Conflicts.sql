/*

	Author:		Stuart Barnley

	Date:		24th July 2017


	Purpose:	To display the conflicts 
*/

CREATE Procedure [Staging].[SSRS_R0167_OPE_Conflicts]
--with execute as owner
as

Select	a.RuleID,
		a.LiveRule,
		a.PartnerID,
		p.Name as PartnerName,
		coalesce(b.CurrentlyActive,0) as CurrentlyActive,
		a.RNumber_Type+1 as Variations
From warehouse.Selections.OPEPartnerConflict as a
inner join slc_report.dbo.partner as p
	on a.partnerid = p.id
Left Outer join warehouse.relational.Partner as b
	on a.PartnerID = b.PartnerID

