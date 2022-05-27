-- =============================================
-- Author:		JEA
-- Create date: 12/06/2018
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [MI].[IronOfferCycleCustomerCount_Refresh] 
	WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @CyclesToCount INT

	--clear table that counts new cycles
    TRUNCATE TABLE MI.IronOfferCyclesToCount

	INSERT INTO MI.IronOfferCyclesToCount(IronOfferID, StartDate, EndDate)
	
	SELECT o.OfferID, a.StartDate, cast(a.EndDate as datetime) + cast('23:59:59.000' as datetime) AS EndDateTest
	FROM Selections.ROCShopperSegment_PreSelection_ALS a
	CROSS APPLY MI.OfferIDSplit(a.OfferID) o --splits the comma-separated offer id column into a list of IronOfferIDs
	WHERE a.SelectionRun = 1 -- indicates selection has completed for these ironoffers

	EXCEPT

	SELECT IronOfferID, StartDate, EndDate
	FROM MI.IronOfferCycleCustomerCount --cycles that have already been counted


	INSERT INTO MI.IronOfferCyclesToCount(IronOfferID, StartDate, EndDate)
	SELECT o.OfferID, a.StartDate, cast(a.EndDate as datetime) + cast('23:59:59.000' as datetime) AS EndDateTest
	FROM Selections.CampaignSetup_DD a
	CROSS APPLY MI.OfferIDSplit(a.OfferID) o --splits the comma-separated offer id column into a list of IronOfferIDs
	WHERE a.SelectionRun = 1 -- indicates selection has completed for these ironoffers

	EXCEPT

	SELECT IronOfferID, StartDate, EndDate
	FROM MI.IronOfferCycleCustomerCount --cycles that have already been counted





	INSERT INTO MI.IronOfferCycleCustomerCount(IronOfferID, StartDate, EndDate, CustomerCount)

	SELECT c.IronOfferID, c.StartDate, c.EndDate, ISNULL(M.CustomerCount, 0) AS CustomerCount
	FROM MI.IronOfferCyclesToCount c --a cycle where the selection has run should always be entered, even if there are no members
	LEFT OUTER JOIN (SELECT c.IronOfferID, c.StartDate, c.EndDate, COUNT(DISTINCT m.CompositeID) AS CustomerCount
					FROM Relational.IronOfferMember m
					INNER JOIN MI.IronOfferCyclesToCount c ON m.IronOfferID = c.IronOfferID and m.StartDate = c.StartDate and m.EndDate = c.EndDate
					GROUP BY  c.IronOfferID, c.StartDate, c.EndDate
					) m ON c.IronOfferID = m.IronOfferID and c.StartDate = m.StartDate AND c.EndDate = m.EndDate

	--JEA 18/06/2018 - Shane has requested that he receive the report every week regardless of whether there are new offers

	--SELECT @CyclesToCount = COUNT(*) --check whether a report is required
	--FROM MI.IronOfferCyclesToCount c
	--INNER JOIN MI.IronOfferCycleCustomerCount m ON c.IronOfferID = m.IronOfferID AND C.StartDate = M.StartDate AND C.EndDate = m.EndDate
	--WHERE M.CustomerCount != 0

	--IF ISNULL(@CyclesToCount,0) > 0 -- if new cycles have been counted, run the report
	--BEGIN
		EXEC msdb.dbo.sp_start_job 'A3100E85-67A5-4AE9-993B-4197DFD858C9' --RBSOfferCount report subscription on DIMAIN
	--END

END