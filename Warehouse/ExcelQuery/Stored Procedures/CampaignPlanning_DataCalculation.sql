




/*=================================================================================================
Campaign Planning Procedures
Part 2: Results calculation
Version 3: P.Lovell 13/11/2015
Revisions: Added the insert to the record tables
=================================================================================================*/



CREATE PROCEDURE [ExcelQuery].[CampaignPlanning_DataCalculation] (@IDs	VARCHAR(600))

AS
BEGIN
	SET NOCOUNT ON;


/*
UPDATE warehouse.excelquery.CampaignPlanning_Calculations
SET partnerID = iq.partnerID
FROM warehouse.excelquery.CampaignPlanning_Calculations as cpc
INNER JOIN (SELECT c.ID, p.partnerid 
			from warehouse.relational.partner as p WITH (NOLOCK)
			INNER JOIN warehouse.excelquery.CampaignPlanning_Calculations as c ON c.PartnerName=p.PartnerName
			) as iq ON iq.ID = cpc.ID
;
*/
--Get relevant brand level information
UPDATE warehouse.excelquery.CampaignPlanning_Calculations
SET 
	Override_rate = b.Override
	--,halo = b.halo 
	,baserate = CASE WHEN ci.campaigntype like '%base%' THEN 0 
					 WHEN b.RetailerTypeID = 1 AND b.baseoffer= 0 THEN 0.02  --used as *most* non-core base offers are 2%
					 ELSE b.baseoffer END --identifies base offers and updates accordingly
	--,uplift = CASE WHEN b.retailerclass = 'Known Retailer' THEN -0.11
	--									WHEN b.retailerclass = 'High ATV' THEN 0.22
	--									WHEN b.retailerclass = 'Medium ATV' THEN 0.136
	--									ELSE 0 END
FROM  warehouse.excelquery.CampaignPlanning_Calculations as cd
INNER JOIN warehouse.staging.CampaignPlanningTool_CampaignSegment as cs	ON cd.id = cs.ID
INNER JOIN warehouse.staging.CampaignPlanningTool_CampaignInput as ci ON cs.ClientServicesRef=ci.ClientServicesRef
INNER JOIN warehouse.staging.CampaignPlanning_Brand as b with (NOLOCK) ON ci.partnerID=b.PartnerID
where cd.id IN (@IDs)
;


-- get estimated future customer base volumes
UPDATE warehouse.excelquery.CampaignPlanning_Calculations
SET audience_fcst = iq. customercount
FROM  warehouse.excelquery.CampaignPlanning_Calculations as cd

INNER JOIN 
(SELECT cs.id,CustomerCount
					FROM warehouse.staging.CampaignPlanning_ActivatedBase as pw with (NOLOCK)
					
					INNER JOIN warehouse.staging.CampaignPlanningTool_CampaignSegment as cs WITH (NOLOCK)
						ON DATEADD(dd,-3,cs.startdate) = pw.weekstartdate
					
					INNER JOIN warehouse.staging.campaignplanningtool_campaignInput as ci WITH (NOLOCK)
						ON ci.ClientServicesRef = cs.ClientServicesRef
					WHERE ci.customerbaseID = pw.CustomerBaseID--customerbaseID
					  AND cs.ID IN (@IDs)
			
					) as iq ON iq.id = cd.id 
					 --get forecast audience size for the week in question
;
--super quick to here



UPDATE warehouse.excelquery.CampaignPlanning_Calculations
SET audience_fcst = iq.total
FROM  warehouse.excelquery.CampaignPlanning_Calculations as cpc
INNER JOIN warehouse.staging.CampaignPlanningTool_CampaignSegment as cd WITH (NOLOCK)
ON cpc.id = cd.id									
INNER JOIN warehouse.staging.campaignplanningtool_campaignInput as ci WITH (NOLOCK)
ON ci.ClientServicesRef = cd.ClientServicesRef
INNER JOIN 
(SELECT cd.ID, count( fanid) as total
						from warehouse.staging.CampaignPlanningTool_CampaignSegment as cd WITH (NOLOCK)
											
						INNER JOIN warehouse.staging.campaignplanningtool_campaignInput as ci WITH (NOLOCK)
						ON ci.ClientServicesRef = cd.ClientServicesRef
						INNER JOIN warehouse.staging.CampaignPlanning_TriggerMember as tm with (NOLOCK)
						ON ci.partnerID=tm.PartnerID
						AND ( tm.noncorebo_csref = cd.noncorebo_csref OR cd.noncorebo_csref IS NULL)
						where cd.id IN (@IDs)
						GROUP BY cd.id ) as iq ON iq.ID=cpc.id 
WHERE ci.RetailerType = 'Non-Core' OR cd.noncorebo_csref IS NOT NULL
;
--30s

/*  this could be faster if I could get it to work across multiple rows
IF (SELECT CASE WHEN Retailertype = 'Non-Core' OR  noncorebo_csref IS NOT NULL THEN 1 ELSE 0 END FROM warehouse.excelquery.CampaignPlanning_Calculations) = 1 
	BEGIN 
		UPDATE warehouse.excelquery.CampaignPlanning_Calculations
		SET audience_fcst = (SELECT count( fanid) 
							from warehouse.staging.CampaignPlanning_TriggerMember as tm with (NOLOCK)
							INNER JOIN warehouse.excelquery.CampaignPlanning_Calculations as cd ON cd.partnerID=tm.PartnerID
							)
	END
ELSE 
	BEGIN
		UPDATE warehouse.excelquery.CampaignPlanning_Calculations
		SET audience_fcst = (SELECT count( fanid) 
							from warehouse.staging.CampaignPlanning_TriggerMember as tm with (NOLOCK)
							INNER JOIN warehouse.excelquery.CampaignPlanning_Calculations as cd ON cd.partnerID=tm.PartnerID
							AND ( tm.noncorebo_csref = cd.noncorebo_csref OR cd.noncorebo_csref IS NULL))
	END
;
*/


-- get current customer base size  --could be faster i THINK
UPDATE warehouse.excelquery.CampaignPlanning_Calculations
SET audience_now = (SELECT count(distinct  fanid) 
						from warehouse.staging.CampaignPlanning_TriggerMember as tm with (NOLOCK)
						)  --get total unique peeps
FROM warehouse.excelquery.CampaignPlanning_Calculations as cc
INNER JOIN warehouse.staging.CampaignPlanningTool_CampaignSegment as cs WITH (NOLOCK)
	ON cc.id = cs.ID
INNER JOIN warehouse.staging.campaignplanningtool_campaignInput as ci WITH (NOLOCK)
ON ci.ClientServicesRef = cs.ClientServicesRef
WHERE ci.RetailerType != 'Non-Core'  OR cs.noncorebo_csref IS NULL
AND cc.id IN (@IDs)
;

UPDATE warehouse.excelquery.CampaignPlanning_Calculations
SET audience_now = audience_fcst
FROM warehouse.excelquery.CampaignPlanning_Calculations as cc
INNER JOIN warehouse.staging.CampaignPlanningTool_CampaignSegment as cs WITH (NOLOCK)
	ON cc.id = cs.ID
INNER JOIN warehouse.staging.campaignplanningtool_campaignInput as ci WITH (NOLOCK)
ON ci.ClientServicesRef = cs.ClientServicesRef
WHERE ci.RetailerType = 'Non-Core'  OR cs.noncorebo_csref IS NOT NULL
AND cc.id IN (@IDs)
;



 --campaign length
UPDATE warehouse.excelquery.CampaignPlanning_Calculations
SET c_length = DATEDIFF(ww,cs.startdate,cs.enddate)
FROM warehouse.excelquery.CampaignPlanning_Calculations as cc
INNER JOIN warehouse.staging.CampaignPlanningTool_CampaignSegment as cs WITH (NOLOCK)
	ON cs.ID = cc.ID
WHERE cc.ID IN (@IDs)
;

--share of customers with birthdays in period
UPDATE warehouse.excelquery.CampaignPlanning_Calculations
SET b_day_share = CASE WHEN ci.birthdaytype IS NULL THEN 1 ELSE (365 / (7*c_length) *1.0)/100 END --where birthday is not null
FROM warehouse.excelquery.CampaignPlanning_Calculations as cc
INNER JOIN warehouse.staging.CampaignPlanningTool_CampaignSegment as cs WITH (NOLOCK)
	ON cs.ID = cc.ID
INNER JOIN warehouse.staging.campaignplanningtool_campaignInput as ci WITH (NOLOCK)
ON ci.ClientServicesRef = cs.ClientServicesRef
WHERE cc.id IN (@IDs)
;


--Do the base autouplift calculations
/*
UPDATE warehouse.excelquery.CampaignPlanning_Calculations
SET uplift = uplift 
				+(Offerrate *  ((0.0138 + CASE WHEN HTMID IN (10,11,12) OR Acquiremember = 1 OR supersegmentID=1 THEN 0.0016 ELSE 0 END) * 10))
				+0.14
				+ CASE WHEN campaigntype like '%Launch' THEN 0 ELSE -0.053 END 
;


--set minimum uplift if below threshold
UPDATE warehouse.excelquery.CampaignPlanning_Calculations
SET uplift = CASE WHEN uplift <=0.01 THEN CASE WHEN offerrate <0.05 THEN offerrate*1.5
											WHEN offerrate <0.1 THEN OfferRate*1.25 
											ELSE offerrate *1.1 END
					 ELSE uplift END
;
*/

--NOW get SPC seasonality

UPDATE warehouse.excelquery.CampaignPlanning_Calculations					
SET season_SPC =  iq.spcadj
FROM warehouse.excelquery.CampaignPlanning_Calculations as c 
INNER JOIN 
(SELECT cs.ID, AVG(SPCadj) as spcadj
					from warehouse.staging.CampaignPlanning_Seasonality as s with (NOLOCK) 
					INNER JOIN warehouse.staging.CampaignPlanningTool_CampaignSegment as cs WITH (NOLOCK)
					ON s.Date >= cs.startdate AND s.date <=cs.enddate
					INNER JOIN warehouse.staging.campaignplanningtool_campaignInput as ci WITH (NOLOCK)
						ON ci.ClientServicesRef = cs.ClientServicesRef
					WHERE cs.ID IN (@IDs)
					 AND s.PartnerID=ci.partnerID
					GROUP BY cs.id
					) as iq ON iq.ID=c.ID
;




--- Now do the maths

-- Calculate customer volumes
UPDATE warehouse.excelquery.CampaignPlanning_Calculations		
SET Mailed_group = iq.estimated_mailed 
	,Control_Group = iq.estimated_control 

FROM warehouse.excelquery.CampaignPlanning_Calculations as cd WITH (NOLOCK)
INNER JOIN ( SELECT cc.ID
			,ROUND(((count(distinct tm.fanid) /( cc.audience_now *1.0 ))* cd.AB_Split) * cc.audience_fcst *(1-ci.ControlGroup_Size) * cc.b_day_share,0) as estimated_mailed
			,ROUND(((count(distinct tm.fanid) /( cc.audience_now *1.0 ))* cd.AB_Split) * cc.audience_fcst * ci.ControlGroup_Size * cc.b_day_share ,0)as estimated_control
			

			FROM warehouse.excelquery.CampaignPlanning_Calculations as cc WITH (NOLOCK)
			INNER JOIN warehouse.staging.CampaignPlanningTool_CampaignSegment as cd WITH (NOLOCK)
			ON cd.ID = cc.ID
			INNER JOIN warehouse.staging.campaignplanningtool_campaignInput as ci WITH (NOLOCK)
			ON ci.ClientServicesRef = cd.ClientServicesRef 
			INNER JOIN warehouse.staging.CampaignPlanning_TriggerMember as tm with (NOLOCK)
			ON tm.PartnerID=ci.partnerID
				AND	(tm.CompetitorShopper4wk = cd.CompetitorShopper4wk OR cd.CompetitorShopper4wk IS NULL)
				AND (tm.Homemover = cd.Homemover OR  cd.Homemover IS NULL)
				AND (tm.Lapser= cd.Lapser OR cd.lapser IS NULL)
				AND (tm.AcquireMember=cd.AcquireMember OR cd.AcquireMember IS NULL)
				AND (tm.HTMID = cd.HTMID OR cd.htmid IS NULL )
				AND ( tm.SuperSegmentID=cd.SuperSegmentID OR cd.SuperSegmentID IS NULL)
				AND (cd.gender= tm.gender OR cd.gender IS NULL ) -- ELSE cd.gender =tm.gender END
				AND (cd.minage <= tm.minage OR cd.minage IS NULL)
				AND (cd.maxage >= tm.maxage OR cd.maxage IS NULL)
				AND (cd.cameo_code_grp = tm.cameo_code_group OR cd.CAMEO_CODE_GRP IS NULL)
				AND (cd.socialclass = tm.SocialClass OR cd.SocialClass IS NULL)
				AND (cd.DriveTimeBand = tm.DriveTimeBandID OR cd.DriveTimeBand IS NULL)
				AND ( tm.ResponseIndexScore >= cd.minheatmapscore OR cd.MinHeatMapScore IS NULL)
				AND (tm.ResponseIndexScore <= cd.maxheatmapscore OR cd.MAxHeatMapScore IS NULL)
				AND (tm.NonCoreBO_CSRef = cd.noncorebo_csref OR cd.noncorebo_csref IS NULL)
			WHERE cc.ID IN (@IDs)
			GROUP BY cc.audience_now,cc.audience_fcst,cd.AB_Split,cc.b_day_share,ci.ControlGroup_Size,cc.ID) as iq ON iq.id = cd.ID
;

-- Calculate total sales and incremental sales
UPDATE warehouse.excelquery.CampaignPlanning_Calculations		
SET total_sales = iq.total_sales
	,Natural_Sales = iq.natural_sales
	,incremental_sales = iq.inc_sales
	,qualifying_sales = iq.q_sales
FROM warehouse.excelquery.CampaignPlanning_Calculations as cd WITH (NOLOCK)
INNER JOIN ( SELECT cc.ID
			,(((sum(tm.total_salesvalue_wk1) / count(tm.fanid) ) * cc.c_length * cc.season_SPC) + ((sum(tm.total_salesvalue_wk1) / count(tm.fanid) ) * cc.c_length * cc.season_SPC *cs.uplift) ) * cc.mailed_group as total_sales
			,(((sum(tm.total_salesvalue_wk1) / count(tm.fanid) ) * cc.c_length * cc.season_SPC)  ) * cc.mailed_group as natural_sales
			,((((sum(tm.total_salesvalue_wk1) / count(tm.fanid) ) * cc.c_length * cc.season_SPC *cs.uplift ) ) ) * cc.mailed_group as inc_sales
			,(((sum(tm.total_salesvalue_wk1) / count(tm.fanid) ) * cc.c_length * cc.season_SPC) + ((sum(tm.total_salesvalue_wk1) / count(tm.fanid) ) * cc.c_length * cc.season_SPC *cs.Uplift) ) * cc.mailed_group * (SUM(CASE WHEN ((tm.total_salesvalue_wk1/tm.Total_Transactions_Wk1) >=ISNULL(cs.spendthreshold,0)) THEN Total_SalesValue_Wk1 ELSE 0 END) / sum(Total_SalesValue_Wk1)*1.0) as Q_sales
			FROM warehouse.excelquery.CampaignPlanning_Calculations as cc WITH (NOLOCK)
			INNER JOIN warehouse.staging.CampaignPlanningTool_CampaignSegment as cs WITH (NOLOCK)
			ON cc.ID = cs.ID
			INNER JOIN warehouse.staging.CampaignPlanningTool_CampaignInput as ci WITH (NOLOCK)
			ON cs.ClientServicesRef = ci.ClientServicesRef
			INNER JOIN warehouse.staging.CampaignPlanning_TriggerMember as tm with (NOLOCK)
			ON tm.PartnerID=ci.partnerID
				AND	(tm.CompetitorShopper4wk = cs.CompetitorShopper4wk OR cs.CompetitorShopper4wk IS NULL)
				AND (tm.Homemover = cs.Homemover OR  cs.Homemover IS NULL)
				AND (tm.Lapser= cs.Lapser OR cs.lapser IS NULL)
				AND (tm.AcquireMember=cs.AcquireMember OR cs.AcquireMember IS NULL)
				AND (tm.HTMID = cs.HTMID OR cs.htmid IS NULL )
				AND ( tm.SuperSegmentID=cs.SuperSegmentID OR cs.SuperSegmentID IS NULL)
				AND (cs.gender= tm.gender OR cs.gender IS NULL ) -- ELSE cs.gender =tm.gender END
				AND (cs.minage <= tm.minage OR cs.minage IS NULL)
				AND (cs.maxage >= tm.maxage OR cs.maxage IS NULL)
				AND (cs.cameo_code_grp = tm.cameo_code_group OR cs.CAMEO_CODE_GRP IS NULL)
				AND (cs.socialclass = tm.SocialClass OR cs.SocialClass IS NULL)
				AND (cs.DriveTimeBand = tm.DriveTimeBandID OR cs.DriveTimeBand IS NULL)
				AND ( tm.ResponseIndexScore >= cs.minheatmapscore OR cs.MinHeatMapScore IS NULL)
				AND (tm.ResponseIndexScore <= cs.maxheatmapscore OR cs.MAxHeatMapScore IS NULL)
				AND (tm.NonCoreBO_CSRef = cs.noncorebo_csref OR cs.noncorebo_csref IS NULL)
			WHERE cc.ID IN (@IDs)
			GROUP BY cc.ID,cc.season_SPC,cc.c_length,cc.Mailed_group,cs.uplift) as iq ON iq.id = cd.ID
;


-- Now do the costs
UPDATE warehouse.excelquery.CampaignPlanning_Calculations		
SET Cost_of_Campaign = isNULL(IQ.COST,0)
	
FROM warehouse.excelquery.CampaignPlanning_Calculations as cd WITH (NOLOCK)
INNER JOIN ( SELECT cc.ID
			,CASE WHEN ci.partnerID != 3960 THEN Qualifying_sales * (cd.OfferRate-cc.Baserate) * (1+Override_rate) 
				 ELSE Qualifying_sales * (cd.OfferRate-cc.Baserate) * (1+override_rate) + ((Total_sales-qualifying_sales) * baserate * (1+Override_rate))
			
			END as cost

			FROM warehouse.excelquery.CampaignPlanning_Calculations as cc WITH (NOLOCK)
			INNER JOIN warehouse.staging.CampaignPlanningTool_CampaignSegment as cd WITH (NOLOCK)
			ON cd.ID = cc.ID
			INNER JOIN warehouse.staging.campaignplanningtool_campaignInput as ci WITH (NOLOCK)
			ON ci.ClientServicesRef = cd.ClientServicesRef 

			INNER JOIN warehouse.staging.CampaignPlanning_TriggerMember as tm with (NOLOCK)
			ON tm.PartnerID=ci.partnerID
				AND	(tm.CompetitorShopper4wk = cd.CompetitorShopper4wk OR cd.CompetitorShopper4wk IS NULL)
				AND (tm.Homemover = cd.Homemover OR  cd.Homemover IS NULL)
				AND (tm.Lapser= cd.Lapser OR cd.lapser IS NULL)
				AND (tm.AcquireMember=cd.AcquireMember OR cd.AcquireMember IS NULL)
				AND (tm.HTMID = cd.HTMID OR cd.htmid IS NULL )
				AND ( tm.SuperSegmentID=cd.SuperSegmentID OR cd.SuperSegmentID IS NULL)
				AND (cd.gender= tm.gender OR cd.gender IS NULL ) -- ELSE cd.gender =tm.gender END
				AND (cd.minage <= tm.minage OR cd.minage IS NULL)
				AND (cd.maxage >= tm.maxage OR cd.maxage IS NULL)
				AND (cd.cameo_code_grp = tm.cameo_code_group OR cd.CAMEO_CODE_GRP IS NULL)
				AND (cd.socialclass = tm.SocialClass OR cd.SocialClass IS NULL)
				AND (cd.DriveTimeBand = tm.DriveTimeBandID OR cd.DriveTimeBand IS NULL)
				AND ( tm.ResponseIndexScore >= cd.minheatmapscore OR cd.MinHeatMapScore IS NULL)
				AND (tm.ResponseIndexScore <= cd.maxheatmapscore OR cd.MAxHeatMapScore IS NULL)
				AND (tm.NonCoreBO_CSRef = cd.noncorebo_csref OR cd.noncorebo_csref IS NULL)
			WHERE cc.ID IN (@IDs)
			GROUP BY cc.ID,cc.Total_sales,cc.Override_rate,cd.OfferRate,cc.baserate,cc.Qualifying_sales,ci.partnerID) as iq ON iq.id = cd.ID
;

--Finally add the results
UPDATE warehouse.excelquery.CampaignPlanning_Calculations
SET incremental_sales_ROI = incremental_sales / case when cost_of_campaign = 0 then 1 else cost_of_campaign end
	,incremental_sales_ROI_ext = (incremental_sales * 1.25) / case when cost_of_campaign = 0 then 1 else cost_of_campaign end
	,billing_rate = cd.OfferRate*(1+Override_rate)
	,final_offer_rate = cd.offerrate	
FROM warehouse.excelquery.CampaignPlanning_Calculations as cc
INNER JOIN warehouse.staging.CampaignPlanningTool_CampaignSegment as cd WITH (NOLOCK)
			ON cd.ID = cc.ID
;

--set values to 0 for empty rows, just in case
UPDATE warehouse.excelquery.CampaignPlanning_Calculations
SET mailed_group = 0
		,control_group = 0
		,total_sales = 0
		,natural_sales = 0
		,incremental_sales = 0
		,cost_of_campaign = 0
		,incremental_sales_ROI = 0
		,incremental_sales_ROI_ext = 0
		,billing_rate = 0
		,final_offer_rate = 0
WHERE ActiveRow = 0
  and ID IN (@IDs)
;



/* Update Campaign Input and segment */

UPDATE warehouse.excelquery.CampaignPlanning_Calculations
SET status_startdate = GETDATE()
WHERE ID IN (@IDs)
END
;




