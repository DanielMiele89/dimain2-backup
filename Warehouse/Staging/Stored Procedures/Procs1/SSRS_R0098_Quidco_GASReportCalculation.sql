
-- ***********************************************************
-- Author: Suraj Chahal - Code originally written by Lloyd Green
-- Create date: 21/08/2015
-- Description: Populates data for Quidco from GAS
-- ***********************************************************
CREATE PROCEDURE [Staging].[SSRS_R0098_Quidco_GASReportCalculation]

AS
BEGIN

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY

	/**************************************
	******Write entry to JobLog Table******
	**************************************/
	INSERT INTO staging.JobLog_Temp
	SELECT	StoredProcedureName = 'SSRS_R0098_Quidco_GASReportCalculation',
		TableSchemaName = 'Staging',
		TableName = 'SSRS_R0098_Quidco_GASReport',
		StartDate = GETDATE(),
		EndDate = NULL,
		TableRowCount  = NULL,
		AppendReload = 'R'
	
	
	/****************************************************
	***********Finding Cardholders and Cards*************
	****************************************************/
	IF OBJECT_ID ('Staging.SSRS_R0098_Quidco_Cards') IS NOT NULL DROP TABLE Staging.SSRS_R0098_Quidco_Cards
	SELECT	CAST(GETDATE() AS DATE) as Report_Date, 
		COUNT(p.id) as Cards,
		COUNT(DISTINCT f.ID) as Cardholders
	INTO Staging.SSRS_R0098_Quidco_Cards
	FROM SLC_Report.dbo.Pan p
	INNER JOIN SLC_Report.dbo.Fan f 
		ON f.CompositeID = p.CompositeID
	WHERE	(p.removaldate is null)
		AND f.clubID = 12 -- Quidco
			AND
		(
		(p.DuplicationDate IS NULL)
		OR 
		(p.DuplicationDate IS NOT NULL AND EXISTS 
							(
							SELECT	1
							FROM SLC_Report.dbo.Pan ps 
							INNER JOIN SLC_Report.dbo.Fan fs 
								ON ps.CompositeID = fs.CompositeID
							WHERE	ps.PaymentCardID = p.PaymentCardID
								AND ps.AdditionDate >= p.AdditionDate 
								AND fs.ClubID = 141 -- P4L
							)))


	/****************************************************
	*************Declaring Date Variables****************
	****************************************************/
	DECLARE	@Report_End_Date DATETIME,
		@PreviousMonthStart DATETIME,
		@PreviousMonthEnd DATETIME,
		@CurrentMonthStart DATETIME,
		@StartDate DATETIME 


	SET @Report_End_Date = CAST(CONVERT(VARCHAR(10),
			CAST(CASE 
				WHEN DATEPART(DW,GETDATE())>=5 THEN DATEADD(DAY,-(DATEPART(DW,GETDATE())-5),GETDATE())
				ELSE DATEADD(DAY, -((DATEPART(DW,GETDATE())+7)-5),GETDATE())
			END AS DATE)
			,110)+' 23:59:59' AS DATETIME)
	SET @PreviousMonthStart = DATEADD(MONTH,DATEDIFF(MONTH,-1,GETDATE())-2,0)
	SET @PreviousMonthEnd = DATEADD(SS,-1,DATEADD(MONTH,DATEDIFF(MONTH,0,GETDATE()),0))
	SET @CurrentMonthStart = DATEADD(MONTH,DATEDIFF(MONTH,-1,GETDATE())-1,0)
	SET @StartDate = CAST('2009-10-01' AS DATETIME)


	/**************************************************************************
	***********Find Last Month - Current Month and Cumulative Totals***********
	**************************************************************************/
	IF OBJECT_ID ('Staging.SSRS_R0098_Quidco_GASReport') IS NOT NULL DROP TABLE Staging.SSRS_R0098_Quidco_GASReport
	SELECT	*
	INTO Staging.SSRS_R0098_Quidco_GASReport
	FROM	(
	--**Last Month
		SELECT	'Last Month' as Reporting_Period,
			(@PreviousMonthStart) AS StartPeriod,
			(@PreviousMonthEnd) AS EndPeriod,
			p.Name as PartnerName,
			COUNT(DISTINCT f.ID) as Transactors,
			COUNT(DISTINCT(CASE WHEN Amount > 0 THEN f.ID ELSE NULL END)) as Spenders,
			SUM(CASE WHEN Amount > 0 THEN 1 ELSE 0 END) as Spends,
			SUM(CASE WHEN Amount < 0 THEN 1 ELSE 0 END) as Refunds,
			SUM(m.Amount) as TotalSpend,
			(SUM(m.PartnerCommissionAmount)/SUM(m.Amount)) as Commission,
			SUM(m.PartnerCommissionAmount) as GrossCommission,
			SUM(m.PartnerCommissionAmount) - SUM(m.VatAmount) as NetCommission,
			SUM(tt.Multiplier * t.CommissionEarned)as cashbackamount
		FROM SLC_Report.dbo.Fan f
		INNER JOIN SLC_Report.dbo.Trans t 
			ON f.ID = t.FanID
		INNER JOIN SLC_Report.dbo.Match m
			ON t.MatchID = m.ID
		INNER JOIN SLC_Report.dbo.RetailOutlet ro
			ON m.RetailOutletID = ro.ID
		INNER JOIN SLC_Report.dbo.Partner p
			ON ro.PartnerID = p.ID
		INNER JOIN SLC_Report.dbo.TransactionType tt
			ON tt.ID = t.TypeID
		WHERE	f.ClubID = 12 --12 is Quidco Club ID
			AND m.Status IN (1)-- Valid transaction status
			AND m.RewardStatus IN (0,1) -- Valid transaction status
			AND m.TransactionDate BETWEEN @PreviousMonthStart AND @PreviousMonthEnd
		GROUP BY p.Name
	UNION
	--**Last Month Total
		SELECT	'Last Month' as Reporting_Period,
			(@PreviousMonthStart) as StartPeriod,
			(@PreviousMonthEnd) as EndPeriod,
			'01. Total' as PartnerName,
			COUNT(DISTINCT f.ID) as Transactors,
			COUNT(DISTINCT(CASE WHEN Amount > 0 THEN f.ID ELSE NULL END)) as Spenders,
			SUM(CASE WHEN Amount > 0 THEN 1 ELSE 0 END) as Spends,
			SUM(CASE WHEN Amount < 0 THEN 1 ELSE 0 END) as Refunds,
			SUM(m.Amount) as TotalSpend,
			(SUM(m.PartnerCommissionAmount)/SUM(m.Amount)) as Commission,
			SUM(m.PartnerCommissionAmount) as GrossCommission,
			SUM(m.PartnerCommissionAmount) - SUM(m.VatAmount) as NetCommission,
			SUM(tt.Multiplier * t.CommissionEarned)as CashbackAmount
		FROM SLC_Report.dbo.Fan f
		INNER JOIN SLC_Report.dbo.Trans t
			ON f.ID = t.FanID
		INNER JOIN SLC_Report.dbo.Match m
			ON t.MatchID = m.ID
		INNER JOIN SLC_Report.dbo.TransactionType tt
			ON tt.ID = t.TypeID
		WHERE	f.ClubID = 12 --12 is Quidco Club ID
			AND m.Status IN (1)-- Valid transaction status
			AND m.RewardStatus IN (0,1) -- Valid transaction status
			AND m.TransactionDate BETWEEN @PreviousMonthStart AND @PreviousMonthEnd
	UNION
	--**Current Month
		SELECT	'Current Month' as Reporting_Period,
			(@CurrentMonthStart) AS StartPeriod,
			(@Report_End_Date) AS EndPeriod,
			p.Name as PartnerName,
			COUNT(DISTINCT f.ID) as Transactors,
			COUNT(DISTINCT(CASE WHEN Amount > 0 THEN f.ID ELSE NULL END)) as Spenders,
			SUM(CASE WHEN Amount > 0 THEN 1 ELSE 0 END) as Spends,
			SUM(CASE WHEN Amount < 0 THEN 1 ELSE 0 END) as Refunds,
			SUM(m.Amount) as TotalSpend,
			(SUM(m.PartnerCommissionAmount)/SUM(m.Amount)) as Commission,
			SUM(m.PartnerCommissionAmount) as GrossCommission,
			SUM(m.PartnerCommissionAmount) - SUM(m.VatAmount) as NetCommission,
			SUM(tt.Multiplier * t.CommissionEarned) as CashbackAmount
		FROM SLC_Report.dbo.Fan f
		INNER JOIN SLC_Report.dbo.Trans t 
			ON f.ID = t.FanID
		INNER JOIN SLC_Report.dbo.Match m
			ON t.MatchID = m.ID
		INNER JOIN SLC_Report.dbo.RetailOutlet ro
			ON m.RetailOutletID = ro.ID
		INNER JOIN SLC_Report.dbo.Partner p
			ON ro.PartnerID = p.ID
		INNER JOIN SLC_Report.dbo.TransactionType tt
			ON tt.ID = t.TypeID
		WHERE	f.ClubID = 12 --12 is Quidco Club ID
			AND m.Status IN (1)-- Valid transaction status
			AND m.RewardStatus IN (0,1) -- Valid transaction status
			AND m.TransactionDate BETWEEN @CurrentMonthStart AND @Report_End_Date
		GROUP BY p.Name
	UNION
	--**Current Month Total
		SELECT	'Current Month' as Reporting_Period,
			(@CurrentMonthStart) AS StartPeriod,
			(@Report_End_Date) AS EndPeriod,
			'01. Total' as PartnerName,
			COUNT(DISTINCT f.ID) as Transactors,
			COUNT(DISTINCT(CASE WHEN Amount > 0 THEN f.ID ELSE NULL END)) as Spenders,
			SUM(CASE WHEN Amount > 0 THEN 1 ELSE 0 END) as Spends,
			SUM(CASE WHEN Amount < 0 THEN 1 ELSE 0 END) as Refunds,
			SUM(m.Amount) as TotalSpend,
			(SUM(m.PartnerCommissionAmount)/SUM(m.Amount)) as Commission,
			SUM(m.PartnerCommissionAmount) as GrossCommission,
			SUM(m.PartnerCommissionAmount) - SUM(m.VatAmount) as NetCommission,
			SUM(tt.Multiplier * t.CommissionEarned)as CashbackAmount
		FROM SLC_Report.dbo.Fan f
		INNER JOIN SLC_Report.dbo.Trans t
			ON f.ID = t.FanID
		INNER JOIN SLC_Report.dbo.Match m
			ON t.MatchID = m.ID
		INNER JOIN SLC_Report.dbo.TransactionType tt
			ON tt.ID = t.TypeID
		WHERE	f.ClubID = 12 --12 is Quidco Club ID
			AND m.Status IN (1)-- Valid transaction status
			AND m.RewardStatus IN (0,1) -- Valid transaction status
			AND m.TransactionDate BETWEEN @CurrentMonthStart AND @Report_End_Date
	UNION
	--**To Date
		SELECT	'To Date' as Reporting_Period,
			(@StartDate) AS StartPeriod,
			(@Report_End_Date) AS EndPeriod,
			p.Name as PartnerName,
			COUNT(DISTINCT f.ID) as Transactors,
			COUNT(DISTINCT(CASE WHEN Amount > 0 THEN f.ID ELSE NULL END)) as Spenders,
			SUM(CASE WHEN Amount > 0 THEN 1 ELSE 0 END) as Spends,
			SUM(CASE WHEN Amount < 0 THEN 1 ELSE 0 END) as Refunds,
			SUM(m.Amount) as TotalSpend,
			(SUM(m.PartnerCommissionAmount)/SUM(m.Amount)) as Commission,
			SUM(m.PartnerCommissionAmount) as GrossCommission,
			SUM(m.PartnerCommissionAmount) - SUM(m.VatAmount) as NetCommission,
			SUM(tt.Multiplier * t.CommissionEarned)as cashbackamount
		FROM SLC_Report.dbo.Fan f
		INNER JOIN SLC_Report.dbo.Trans t 
			ON f.ID = t.FanID
		INNER JOIN SLC_Report.dbo.Match m
			ON t.MatchID = m.ID
		INNER JOIN SLC_Report.dbo.RetailOutlet ro
			ON m.RetailOutletID = ro.ID
		INNER JOIN SLC_Report.dbo.Partner p
			ON ro.PartnerID = p.ID
		INNER JOIN SLC_Report.dbo.TransactionType tt
			ON tt.ID = t.TypeID
		WHERE	f.ClubID = 12 --12 is Quidco Club ID
			AND m.Status IN (1)-- Valid transaction status
			AND m.RewardStatus IN (0,1) -- Valid transaction status
			AND m.TransactionDate BETWEEN @StartDate AND @Report_End_Date
		GROUP BY p.Name
	--**To Date Total
	UNION
		SELECT	'To Date' as Reporting_Period,
			(@StartDate) AS StartPeriod,
			(@Report_End_Date) AS EndPeriod,
			'01. Total' as PartnerName,
			COUNT(DISTINCT f.ID) as Transactors,
			COUNT(DISTINCT(CASE WHEN Amount > 0 THEN f.ID ELSE NULL END)) as Spenders,
			SUM(CASE WHEN Amount > 0 THEN 1 ELSE 0 END) as Spends,
			SUM(CASE WHEN Amount < 0 THEN 1 ELSE 0 END) as Refunds,
			SUM(m.Amount) as TotalSpend,
			(SUM(m.PartnerCommissionAmount)/SUM(m.Amount)) as Commission,
			SUM(m.PartnerCommissionAmount) as GrossCommission,
			SUM(m.PartnerCommissionAmount) - SUM(m.VatAmount) as NetCommission,
			SUM(tt.Multiplier * t.CommissionEarned)as CashbackAmount
		FROM SLC_Report.dbo.Fan f
		INNER JOIN SLC_Report.dbo.Trans t
			ON f.ID = t.FanID
		INNER JOIN SLC_Report.dbo.Match m
			ON t.MatchID = m.ID
		INNER JOIN SLC_Report.dbo.TransactionType tt
			ON tt.ID = t.TypeID
		WHERE	f.ClubID = 12 --12 is Quidco Club ID
			AND m.Status IN (1)-- Valid transaction status
			AND m.RewardStatus IN (0,1) -- Valid transaction status
			AND m.TransactionDate BETWEEN @StartDate AND @Report_End_Date
		)a



	/*****************************************************************
	***********Update entry in JobLog Table with End Date*************
	*****************************************************************/
	UPDATE staging.JobLog_Temp
	SET EndDate = GETDATE()
	WHERE	StoredProcedureName = 'SSRS_R0098_Quidco_GASReportCalculation' 
		AND TableSchemaName = 'Staging'
		AND TableName = 'SSRS_R0098_Quidco_GASReport' 
		AND EndDate IS NULL


	/******************************************************************************
	*****************Update entry in JobLog Table with Row Count*******************
	******************************************************************************/
	--**Count run seperately as when table grows this as a task on its own may 
	--**take several minutes and we do not want it included in table creation times
	UPDATE Staging.JobLog_Temp
	SET TableRowCount = (SELECT COUNT(1) FROM Insightarchive.Halfords_Volumes_By_Week)
	WHERE	StoredProcedureName = 'SSRS_R0098_Quidco_GASReportCalculation'
		AND TableSchemaName = 'Staging'
		AND TableName = 'SSRS_R0098_Quidco_GASReport' 
		AND TableRowCount IS NULL


	INSERT INTO Staging.JobLog
	SELECT	StoredProcedureName,
		TableSchemaName,
		TableName,
		StartDate,
		EndDate,
		TableRowCount,
		AppendReload
	FROM Staging.JobLog_Temp

	TRUNCATE TABLE staging.JobLog_Temp

	RETURN 0; -- normal exit here

END TRY
BEGIN CATCH		
		
	-- Grab the error details
	SELECT  
		@ERROR_NUMBER = ERROR_NUMBER(), 
		@ERROR_SEVERITY = ERROR_SEVERITY(), 
		@ERROR_STATE = ERROR_STATE(), 
		@ERROR_PROCEDURE = ERROR_PROCEDURE(),  
		@ERROR_LINE = ERROR_LINE(),   
		@ERROR_MESSAGE = ERROR_MESSAGE();
	SET @ERROR_PROCEDURE = ISNULL(@ERROR_PROCEDURE, OBJECT_NAME(@@PROCID))

	IF @@TRANCOUNT > 0 ROLLBACK TRAN;
			
	-- Insert the error into the ErrorLog
	INSERT INTO Staging.ErrorLog (ErrorDate, ProcedureName, ErrorLine, ErrorMessage, ErrorNumber, ErrorSeverity, ErrorState)
	VALUES (GETDATE(), @ERROR_PROCEDURE, @ERROR_LINE, @ERROR_MESSAGE, @ERROR_NUMBER, @ERROR_SEVERITY, @ERROR_STATE);	

	-- Regenerate an error to return to caller
	SET @ERROR_MESSAGE = 'Error ' + CAST(@ERROR_NUMBER AS VARCHAR(6)) + ' in [' + @ERROR_PROCEDURE + '] at Line ' + CAST(@ERROR_LINE AS VARCHAR(6)) + '; ' + @ERROR_MESSAGE; 
	RAISERROR (@ERROR_MESSAGE, @ERROR_SEVERITY, @ERROR_STATE);  

	-- Return a failure
	RETURN -1;
END CATCH

RETURN 0; -- should never run

END