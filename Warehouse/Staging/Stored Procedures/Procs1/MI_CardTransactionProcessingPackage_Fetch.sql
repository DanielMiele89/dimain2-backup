-- =============================================
-- Author:		JEA
-- Create date: 27/11/2012
-- Description:	Identifies whether a card transaction load package
-- has run in the last day, and if so whether it has been successful
-- =============================================
CREATE PROCEDURE [Staging].[MI_CardTransactionProcessingPackage_Fetch] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    DECLARE @RecentAuditCount SmallInt, @LoadHasRun Bit, @LoadSuccessful Bit, @PackageStartTime SmallDateTime, @PackageEndTime SmallDateTime
    
    --have any audit actions been logged in the past day?
    SELECT @RecentAuditCount = COUNT(1)
    FROM MI.ProcessLog
    WHERE ActionDate BETWEEN DATEADD(HOUR, -24, GETDATE()) AND GETDATE()
	AND ProcessName LIKE 'ConsumerTransaction%'
    
    --therefore, has the package run?
    SELECT @LoadHasRun = CASE WHEN @RecentAuditCount > 0 THEN 1 ELSE 0 END
    
    --is a 'package successful' action the most recent action to have been logged?
    SELECT @LoadSuccessful = CASE WHEN ProcessName = 'ConsumerTransactionHoldingLoad' AND ActionName = 'Complete' THEN 1 ELSE 0 END
    FROM (SELECT a.ProcessName, a.ActionName, a.ActionDate
		FROM MI.ProcessLog a
		INNER JOIN (SELECT MAX(ActionDate) AS ActionDate
					FROM MI.ProcessLog
					WHERE ProcessName LIKE 'ConsumerTransaction%') m ON A.ActionDate = M.ActionDate
		WHERE a.ProcessName LIKE 'ConsumerTransaction%') a
					
	--Get the most recent package run time.
	SELECT @PackageEndTime = MAX(ActionDate) FROM MI.ProcessLog WHERE ActionName = 'Complete' AND ProcessName = 'ConsumerTransactionHoldingLoad'
	SELECT @PackageStartTime = MAX(ActionDate) FROM MI.ProcessLog WHERE ActionName = 'Started' AND ProcessName = 'ConsumerTransactionHoldingLoad'
	
	SELECT @LoadHasRun AS LoadHasRun
		, @LoadSuccessful AS LoadSuccessful
		, @PackageStartTime AS PackageStartTime
		, @PackageEndTime AS PackageEndTime
    
END
