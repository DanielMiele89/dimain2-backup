-- =============================================
-- Author:		AJS
-- Create date: 20/06/2014
-- Description:	List of partner IDs that are found in the stratified control groups for the current month FOR NONCORERetailers
-- eddited on 10122014 to remove nolonger used tables
-- =============================================
CREATE PROCEDURE [MI].[RetailerReportPartnerListNONCORE_Fetch]
	(
		@MonthID Int
	)
AS
BEGIN
	
	SET NOCOUNT ON;
	
	DECLARE @StartDate Date, @EndDate Date--, @MonthID int
	--set @MonthID = 35

	SELECT @StartDate = StartDate, @EndDate = EndDate
	FROM Relational.SchemeUpliftTrans_Month
	WHERE ID = @MonthID

	SELECT DISTINCT P.PartnerID, ISNULL(S.PartnerID, 0) AS ControlGroupID, p.Scheme_StartDate, p.Scheme_EndDate
	FROM 
		(
		SELECT P.PartnerID, Scheme_StartDate, Scheme_EndDate
			FROM relational.Partner_CBPDates P
			
			INNER JOIN [Relational].[Master_Retailer_Table] MRT on MRT.PartnerID = P.PartnerID
			INNER JOIN [Stratification].[ReportingBaseOffer] BO  on BO.PartnerID = P.PartnerID 

			WHERE Scheme_StartDate < @EndDate  --and PartnerID <> 3960  -- added by AJS on 31-10-2013 to exclude BP 
			AND MRT.Core = 'n' AND (BO.LastReportingMonth IS NULL OR @MonthID BETWEEN BO.FirstReportingMonth AND BO.LastReportingMonth )  
			AND (Scheme_EndDate IS NULL OR Scheme_EndDate > @StartDate)
			AND @MonthID >= BO.FirstReportingMonth
			
			)P
	LEFT OUTER JOIN
		(
			SELECT DISTINCT P.PartnerID
			FROM Relational.Control_Stratified_Compressed P -- changed to compressed by DW on 05/03/2015
			INNER JOIN [Relational].[Master_Retailer_Table] MRT1 on MRT1.PartnerID = P.PartnerID
			INNER JOIN [Stratification].[ReportingBaseOffer] BO1  on BO1.PartnerID = P.PartnerID
			WHERE @MonthID BETWEEN MinMonthID AND MaxMonthID --and PartnerID <> 3960 -- added by AJS on 31-10-2013 to exclude BP
			AND MRT1.Core = 'n' AND (BO1.LastReportingMonth IS NULL OR BO1.LastReportingMonth >= @MonthID)
		) S ON P.PartnerID = S.PartnerID
	WHERE s.PartnerID != 4447 --EXCLUDE CO-OP
	ORDER BY P.PartnerID
	

END