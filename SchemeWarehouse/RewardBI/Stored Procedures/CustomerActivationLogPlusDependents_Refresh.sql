
-- =============================================
-- Author:		JEA
-- Create date: 10/09/2014
-- Description:	Refreshes the customer activation log
-- =============================================
CREATE PROCEDURE [RewardBI].[CustomerActivationLogPlusDependents_Refresh]
	
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @LoadedDate DATETIME

	SELECT @LoadedDate = COALESCE(MAX(AuditDate), '1900-01-01')
	FROM RewardBI.CustomerActivationLog

	INSERT INTO RewardBI.CustomerActivationLog(FanID, ActivationStatusID, StatusDate, AuditDate)

	--Activations
	SELECT d.FanID, 1, COALESCE(f.AgreedTCsDate,DATEADD(DAY, -1,d.AuditDate)), d.AuditDate
	FROM Warehouse.MI.CustomerActivation_ChangeLog d
	INNER JOIN SLC_Report.dbo.Fan f on d.FanID = f.ID
	WHERE f.ClubID = 141 AND d.ActivationStatusID = 1 AND d.AuditDate > @LoadedDate

	UNION
	--customers who have been deactivated
	SELECT d.FanID, 3, DATEADD(DAY, -1,d.AuditDate), d.AuditDate
	FROM Warehouse.MI.CustomerActivation_ChangeLog d
	INNER JOIN SLC_Report.dbo.Fan f on d.FanID = f.ID
	WHERE f.ClubID = 141 AND d.ActivationStatusID = 3 AND d.AuditDate > @LoadedDate

	UNION
	--customers who have opted out
	SELECT d.FanID, 2, DATEADD(DAY, -1,d.AuditDate), d.AuditDate
	FROM Warehouse.MI.CustomerActivation_ChangeLog d
	INNER JOIN SLC_Report.dbo.Fan f on d.FanID = f.ID
	WHERE f.ClubID = 141 AND d.ActivationStatusID = 2 AND d.AuditDate > @LoadedDate
    
	EXEC RewardBI.CustomerActiveStatus_Refresh

END

