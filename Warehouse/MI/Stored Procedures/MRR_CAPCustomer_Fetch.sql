-- =============================================
-- Author:		JEA
-- Create date: 31/10/2015
-- Description:	
-- =============================================
CREATE PROCEDURE MI.MRR_CAPCustomer_Fetch 

AS
BEGIN

	SET NOCOUNT ON;

	Declare @DateID as int=46, 
	@EndDate as Date,-- @partnerID as int,
	@StartDate as Date,
	@CumulativetypeID as int=0,
	@StartDateID int,
	@EndDateID int
	, @EndDatePlusOne DATE
	, @MaxEndDate DATE

	SET @MaxEndDate = DATEADD(YEAR, 1, GETDATE())

	set @StartDate = (select MIN(StartDate) from Relational.SchemeUpliftTrans_Month where id=@DateID)
	Set @EndDate = (select MAX(EndDate) from Relational.SchemeUpliftTrans_Month where id=@DateID)

	SET @EndDatePlusOne = DATEADD(DAY, 1, @EndDate)

	set @StartDateID = (select MIN(ID) from Relational.SchemeUpliftTrans_Month where id= @DateID)
	Set @EndDateID = (select MAX(ID) from Relational.SchemeUpliftTrans_Month where id= @DateID)

SELECT FanID
	, MIN(ActivationStart) as StartDate
	, MAX(ISNULL(ActivationEnd, @MaxEndDate)) AS EndDate
FROM MI.CustomerActivationPeriod
WHERE ActivationStart <= @EndDate
	AND (ActivationEnd IS  NULL OR ActivationEnd >= @StartDate)
	AND (AddedDate='2014-11-12' OR AddedDate <= @EndDatePlusOne)
GROUP BY FanID

END