-- =============================================
-- Author:		JEA
-- Create date: 04/12/2013
-- Description:	Refreshes I.SchemeMI_OfferExclude table, used to populate the report portal
-- =============================================
CREATE PROCEDURE MI.SchemeMI_OfferExclude_Refresh 

AS
BEGIN

	SET NOCOUNT ON;

	TRUNCATE TABLE MI.SchemeMI_OfferExclude

	DECLARE @LatestDate DATE, @LastMonthEnd DATE

	SET @LatestDate = GETDATE()
	SET @LastMonthEnd = DATEADD(DAY, -1,DATEFROMPARTS(YEAR(@LatestDate), MONTH(@LatestDate), 1))

	Select Mth,PartnerID 
	Into #MthP
	from 
	(select a.Mth, a.PartnerID, ROW_NUMBER() OVER(PARTITION BY a.Mth ORDER BY a.PartnerID DESC) AS RowNo 
	from [Staging].[PartnerSegmentAssessmentMths] as a
	inner join (Select cast(left(PartnerString,4)as int) as PartnerID from Warehouse.[Staging].[PartnerStrings]
					  Where HTM_Current = 1) as b
		  on a.PartnerID = b.PartnerID
	) as a
	Where RowNo = 1

	INSERT INTO MI.SchemeMI_OfferExclude(DateChoiceID, ExcludeDesc, ExcludeCount)

    Select 0,HTM,Count(FanID)
	From
	(select     Count(1) as CustomerCount,
				--m.mth as MonthsForTransAssessment,
				htm.FanID,
				Case
					  When htm.HTMID = 1 then 'Insufficient Data'
					  Else htm_Description
				End as HTM
	from warehouse.[Relational].[HeadroomTargetingModel_Members] as htm
	inner join warehouse.relational.customer as c
		  on htm.fanid = c.fanid and
					  htm.Startdate <= @LatestDate and 
					  (htm.Enddate is null or htm.enddate >= @LatestDate)
	Inner join #MthP as M
		  on htm.PartnerID = M.PartnerID
	inner join warehouse.relational.HeadroomTargetingModel_Groups as g
		  on htm.htmid =g.htmid
	Where g.htmID in (1,9)
	Group by    htm.FanID,
				Case
					  When htm.HTMID = 1 then 'Insufficient Data'
					  Else htm_Description
				End
	Having Count(1) >= 4
	) as a
	Group by HTM

	INSERT INTO MI.SchemeMI_OfferExclude(DateChoiceID, ExcludeDesc, ExcludeCount)

    Select 1,HTM,Count(FanID)
	From
	(select     Count(1) as CustomerCount,
				--m.mth as MonthsForTransAssessment,
				htm.FanID,
				Case
					  When htm.HTMID = 1 then 'Insufficient Data'
					  Else htm_Description
				End as HTM
	from warehouse.[Relational].[HeadroomTargetingModel_Members] as htm
	inner join warehouse.relational.customer as c
		  on htm.fanid = c.fanid and
					  htm.Startdate <= @LastMonthEnd and 
					  (htm.Enddate is null or htm.enddate >= @LastMonthEnd)
	Inner join #MthP as M
		  on htm.PartnerID = M.PartnerID
	inner join warehouse.relational.HeadroomTargetingModel_Groups as g
		  on htm.htmid =g.htmid
	Where g.htmID in (1,9)
	Group by    htm.FanID,
				Case
					  When htm.HTMID = 1 then 'Insufficient Data'
					  Else htm_Description
				End
	Having Count(1) >= 4
	) as a
	Group by HTM

END
