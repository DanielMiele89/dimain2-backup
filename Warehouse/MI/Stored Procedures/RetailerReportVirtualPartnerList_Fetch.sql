-- =============================================
-- Author:		JEA
-- Create date: 16/07/2013
-- Description:	List of partner IDs that are found in the stratified control groups for the current month
-- =============================================
CREATE PROCEDURE [MI].[RetailerReportVirtualPartnerList_Fetch] 
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

	
	--set @MonthID = 27

	
	SELECT @StartDate = StartDate, @EndDate = EndDate
	FROM Relational.SchemeUpliftTrans_Month
	WHERE ID = @MonthID

	--SELECT 3960 as PartnerID, 3960 As ControlGroupID, @StartDate as Scheme_StartDate, @EndDate as Scheme_EndDate
	

	SELECT P.[VirtualPartnerID], case when ISNULL(C.PartnerID,0)= 0 Then ISNULL(S.PartnerID, 0) else C.PartnerID-10000000 end As ControlGroupID, p.Scheme_StartDate, p.Scheme_EndDate
	FROM 
		(
		SELECT VP.[VirtualPartnerID], MIN(Scheme_StartDate) as Scheme_StartDate, Max(Scheme_EndDate) as Scheme_EndDate, max(VP.PartnerGroupID) as PartnerGroupID
			FROM relational.Partner_CBPDates P
			inner join MI.SchemeMarginsAndTargets SMT on SMT.PartnerID = P.PartnerID-- added by AJS on 20-06-2014 to exclude non active partners
			inner Join MI.VirtualPartner VP On VP.Partnerid = P.PartnerID
			WHERE Scheme_StartDate < @EndDate --and PartnerID <> 3960  -- added by AJS on 31-10-2013 to exclude BP 
			and SMT.IsNonCore =0 and (SMT.EndMonthID is null or SMT.EndMonthID >= @MonthID)  
			AND (Scheme_EndDate IS NULL OR Scheme_EndDate > @StartDate)
			group by VP.[VirtualPartnerID]
			)P
	LEFT OUTER JOIN
		(
			SELECT DISTINCT P.PartnerID
			FROM Relational.Control_Stratified P
			inner join MI.SchemeMarginsAndTargets SMT on SMT.PartnerID = P.PartnerID  -- added by AJS on 20-06-2014 to exclude non active partners
			WHERE MonthID = @MonthID --and PartnerID <> 3960 -- added by AJS on 31-10-2013 to exclude BP
			and SMT.IsNonCore =0 and (SMT.EndMonthID is null or SMT.EndMonthID >= @MonthID) 
		) S ON P.[VirtualPartnerID] = S.PartnerID
		LEFT OUTER JOIN
		(
			SELECT DISTINCT P.PartnerID+10000000 as PartnerID
			FROM Relational.Control_Stratified P
			inner join MI.SchemeMarginsAndTargets SMT on SMT.PartnerGroupID = P.PartnerID  -- added by AJS on 20-06-2014 to exclude non active partners
			WHERE MonthID = @MonthID --and PartnerID <> 3960 -- added by AJS on 31-10-2013 to exclude BP
			and SMT.IsNonCore =0 and (SMT.EndMonthID is null or SMT.EndMonthID >=@MonthID) 
		) C ON P.[VirtualPartnerID] = C.PartnerID
		
	ORDER BY P.VirtualPartnerID
	

END
