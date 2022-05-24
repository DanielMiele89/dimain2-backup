/*
	Author:			Stuart Barnley
	Date:			23-05-2014

	Description:	This stored procedure is used to populate the report R_0014.

					This pulls out Stats for offers loaded into Iron.NominatedOfferMember
					(Targeted Offers) and Iron.TriggerOfferMember (Trigger Offers)

Update:			N/A
					
*/
CREATE Procedure [Staging].[SSRS_R0014_NOM_TOM_Detail_V2]
as
SELECT	* 
FROM  (
	Select	a.PartnerID,
			a.PartnerName,
			a.IronOfferID,
			a.IronOfferName,
			a.StartDate,
			a.EndDate,
			a.isTriggerOffer,
			a.CashbackRate,
			a.CommissionRate,
			htmg.HTMID,
			htmg.[HTM_Description],
			Count(Distinct a.CompositeID) as OfferMembers
	From
		(SELECT p.PartnerID,
				p.PartnerName,
				io.IronOfferID,
				io.IronOfferName,
				io.StartDate,
				io.EndDate,
				io.isTriggerOffer,
				pcr.CashbackRate,
				pcr.CommissionRate,
				nom.CompositeID
		 FROM Warehouse.[iron].[OfferMemberAddition] nom
		 INNER JOIN Warehouse.Relational.IronOffer io
			ON nom.IronOfferID = io.IronOfferID
		 INNER JOIN Warehouse.Relational.Partner p
			ON io.PartnerID = p.PartnerID
		 LEFT OUTER JOIN		(
					SELECT	RequiredIronOfferID,
						MAX(CASE WHEN Status = 1 AND TypeID = 1 THEN CommissionRate END) as CashbackRate,
						CAST(MAX(CASE WHEN Status = 1 AND TypeID = 2 THEN CommissionRate END) AS NUMERIC(32,2)) as CommissionRate
					FROM slc_report.dbo.PartnerCommissionRule p
					WHERE RequiredIronOfferID IS NOT NULL
					GROUP BY RequiredIronOfferID
				) pcr
					ON io.IronOfferID = pcr.RequiredIronOfferID
	) as a
	inner join Warehouse.Relational.Customer as c
		on a.CompositeID = c.CompositeID
	Left Outer join Warehouse.[Relational].[ShareOfWallet_Members] as htm
		on c.fanid = htm.fanid and a.partnerid = htm.partnerid and htm.enddate is null
	Left Outer join Warehouse.[Relational].[HeadroomTargetingModel_Groups] as htmg
		on htm.htmid = htmg.htmid
	Group by	a.PartnerID,a.PartnerName,a.IronOfferID,a.IronOfferName,a.StartDate,a.EndDate,a.isTriggerOffer,
				a.CashbackRate,a.CommissionRate,htmg.HTMID,htmg.[HTM_Description]
UNION ALL
	Select	a.PartnerID,
			a.PartnerName,
			a.IronOfferID,
			a.IronOfferName,
			a.StartDate,
			a.EndDate,
			a.isTriggerOffer,
			a.CashbackRate,
			a.CommissionRate,
			htmg.HTMID,
			htmg.[HTM_Description],
			Count(Distinct a.CompositeID) as OfferMembers
	From
		(SELECT  p.PartnerID,
				 p.PartnerName,
				 io.IronOfferID,
				 io.IronOfferName,
				 CAST(tom.StartDate AS DATETIME) as StartDate,
				 CAST(tom.EndDate AS DATETIME) as EndDate,
				 io.isTriggerOffer,
				 pcr.CashbackRate,
				 pcr.CommissionRate,
				 tom.CompositeID
	FROM Warehouse.Iron.TriggerOfferMember tom
	INNER JOIN Warehouse.Relational.IronOffer io
		ON tom.IronOfferID = io.IronOfferID
	INNER JOIN Warehouse.Relational.Partner p
		ON io.PartnerID = p.PartnerID
	LEFT OUTER JOIN		(
				SELECT	RequiredIronOfferID,
					MAX(CASE WHEN Status = 1 AND TypeID = 1 THEN CommissionRate END) as CashbackRate,
					CAST(MAX(CASE WHEN Status = 1 AND TypeID = 2 THEN CommissionRate END) AS NUMERIC(32,2)) as CommissionRate
				FROM slc_report.dbo.PartnerCommissionRule p
				WHERE RequiredIronOfferID IS NOT NULL
				GROUP BY RequiredIronOfferID
				) pcr
		ON io.IronOfferID = pcr.RequiredIronOfferID
      ) as a
	inner join Warehouse.Relational.Customer as c
		on a.CompositeID = c.CompositeID
	Left Outer join Warehouse.[Relational].[ShareOfWallet_Members] as htm
		on c.fanid = htm.fanid and a.partnerid = htm.partnerid and htm.enddate is null
	Left Outer join Warehouse.[Relational].[HeadroomTargetingModel_Groups] as htmg
		on htm.htmid = htmg.htmid
	Group by	a.PartnerID,a.PartnerName,a.IronOfferID,a.IronOfferName,a.StartDate,a.EndDate,a.isTriggerOffer,
				a.CashbackRate,a.CommissionRate,htmg.HTMID,htmg.[HTM_Description]
) as a
ORDER BY IronOfferID