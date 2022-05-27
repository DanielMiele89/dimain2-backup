-- =============================================
-- Author:		JEA
-- Create date: 31/10/2015
-- Description:	
-- =============================================
CREATE PROCEDURE [MI].[MRR_CAPCustomer_Refresh]
(@DateID AS Int)
WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;


	ALTER INDEX IX_MI_CAPCustomers_Cover ON MI.CAPCustomers DISABLE
	TRUNCATE TABLE MI.CAPCustomers

	DECLARE @EndDate as Date,-- @partnerID as int,
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

	INSERT INTO MI.CAPCustomers(FanID, StartDate, EndDate)
	SELECT FanID
		, MIN(ActivationStart) as StartDate
		, MAX(ISNULL(ActivationEnd, @MaxEndDate)) AS EndDate
	FROM MI.CustomerActivationPeriod
	WHERE ActivationStart <= @EndDate
		AND (ActivationEnd IS  NULL OR ActivationEnd >= @StartDate)
		AND (AddedDate='2014-11-12' OR AddedDate <= @EndDatePlusOne)
	GROUP BY FanID

	ALTER INDEX IX_MI_CAPCustomers_Cover ON MI.CAPCustomers REBUILD

END
