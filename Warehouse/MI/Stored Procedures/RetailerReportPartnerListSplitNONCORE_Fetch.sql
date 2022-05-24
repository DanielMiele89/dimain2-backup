-- =============================================
-- Author:		AJS
-- Create date: 20/06/2014
-- Description:	List of partner IDs that are found in the stratified control groups for the current month FOR Split NONCORERetailers
-- 
-- =============================================
CREATE PROCEDURE [MI].[RetailerReportPartnerListSplitNONCORE_Fetch]
	(
		@MonthID Int
	)
AS
BEGIN
	
	SET NOCOUNT ON;
	--	DECLARE @StartDate Date, @EndDate Date
	--set @StartDate ='2012-01-30'
	--set @EndDate ='2014-01-30'
	--SELECT 3960 as PartnerID, 3960 As ControlGroupID, @StartDate as Scheme_StartDate, @EndDate as Scheme_EndDate
	

	
	DECLARE @StartDate Date, @EndDate Date--, @MonthID int

	
	--set @MonthID = 29



	SELECT @StartDate = StartDate, @EndDate = EndDate
	FROM Relational.SchemeUpliftTrans_Month
	WHERE ID = @MonthID

	--SELECT 3960 as PartnerID, 3960 As ControlGroupID, @StartDate as Scheme_StartDate, @EndDate as Scheme_EndDate
	

	SELECT P.PartnerID, ISNULL(S.PartnerID, 0) As ControlGroupID, p.Scheme_StartDate, p.Scheme_EndDate
	FROM 
		(SELECT P.PartnerID, Scheme_StartDate, Scheme_EndDate
			FROM relational.Partner_CBPDates P
			inner join MI.SchemeMarginsAndTargets_OLD SMT on SMT.PartnerID = P.PartnerID
			WHERE Scheme_StartDate < @EndDate and P.PartnerID != 4100 --and PartnerID <> 3960  -- added by AJS on 31-10-2013 to exclude BP 
			and P.PartnerID in (SELECT [PartnerID]
  FROM [Warehouse].[MI].[ReportSplitUseforReport]
  Group by [PartnerID])
			and SMT.IsNonCore =1 and (SMT.EndMonthID is null or SMT.EndMonthID >= @MonthID)  
			AND (Scheme_EndDate IS NULL OR Scheme_EndDate > @StartDate)
			)P
	LEFT OUTER JOIN
		(
			SELECT DISTINCT P.PartnerID
			FROM Relational.Control_Stratified P
			inner join MI.SchemeMarginsAndTargets_OLD SMT on SMT.PartnerID = P.PartnerID
			WHERE MonthID = @MonthID and P.PartnerID != 4100 --and PartnerID <> 3960 -- added by AJS on 31-10-2013 to exclude BP
			and SMT.IsNonCore =1 and (SMT.EndMonthID is null or SMT.EndMonthID >= @MonthID)  
						and P.PartnerID in (SELECT [PartnerID]
  FROM [Warehouse].[MI].[ReportSplitUseforReport]
  Group by [PartnerID])
		) S ON P.PartnerID = S.PartnerID
	ORDER BY P.PartnerID
	

END