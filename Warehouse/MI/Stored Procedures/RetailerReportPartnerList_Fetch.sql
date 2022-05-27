-- =============================================
-- Author:		JEA
-- Create date: 16/07/2013
-- Description:	List of partner IDs that are found in the stratified control groups for the current month
-- =============================================
CREATE PROCEDURE [MI].[RetailerReportPartnerList_Fetch] 
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
	--set @MonthID = 35

	SELECT @StartDate = StartDate, @EndDate = EndDate
	FROM Relational.SchemeUpliftTrans_Month
	WHERE ID = @MonthID
	--SELECT 3960 as PartnerID, 3960 As ControlGroupID, @StartDate as Scheme_StartDate, @EndDate as Scheme_EndDate
	SELECT distinct P.PartnerID, ISNULL(S.PartnerID, 0) As ControlGroupID, p.Scheme_StartDate, p.Scheme_EndDate
	FROM 
		(
		SELECT P.PartnerID, Scheme_StartDate, Scheme_EndDate
			FROM relational.Partner_CBPDates P
			
			LEFT join [Relational].[Master_Retailer_Table] MRT on MRT.PartnerID = P.PartnerID
			inner join[Stratification].[ReportingBaseOffer] BO  on BO.PartnerID = P.PartnerID 

			WHERE Scheme_StartDate < @EndDate --and PartnerID <> 3960  -- added by AJS on 31-10-2013 to exclude BP 
			AND p.PartnerID != 4447--EXCLUDES CO-OP
			and (MRT.Core is null OR MRT.Core = 'Y') and (BO.LastReportingMonth is null or @MonthID between BO.FirstReportingMonth and BO.LastReportingMonth )  
			AND (Scheme_EndDate IS NULL OR Scheme_EndDate > @StartDate)
			AND @MonthID >= BO.FirstReportingMonth
			
			)P
	LEFT OUTER JOIN
		(
			SELECT DISTINCT P.PartnerID
			FROM Relational.Control_Stratified_Compressed P --changed to compressed by DW on 05/03/2015
			inner join [Relational].[Master_Retailer_Table] MRT1 on MRT1.PartnerID = P.PartnerID
			inner join[Stratification].[ReportingBaseOffer] BO1  on BO1.PartnerID = P.PartnerID
			WHERE @MonthID between MinMonthID and MaxMonthID--and PartnerID <> 3960 -- added by AJS on 31-10-2013 to exclude BP
			and (MRT1.Core is null OR MRT1.Core = 'Y') and (BO1.LastReportingMonth is null or BO1.LastReportingMonth >= @MonthID)
		) S ON P.PartnerID = S.PartnerID
	ORDER BY P.PartnerID
	

END
