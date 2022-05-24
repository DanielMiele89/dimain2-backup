/*
	Author:			Stuart Barnley
	Date:			23-05-2014

	Description:	This stored procedure is used to populate the report R_0016.

					This is part of the Pre SFD Upload Data Assessment

Update:			N/A
					
*/
CREATE Procedure [Staging].[SSRS_R0016_CustomerAssessment]
				 @LionSendID int
as
IF OBJECT_ID ('tempdb..#SelectedCusts') IS NOT NULL DROP TABLE #SelectedCusts
SELECT      DISTINCT nl.CompositeID as SelectedCusts,
      LionSendID,
      CAST(nl.Date AS DATE) as UploadDate
INTO #SelectedCusts
FROM Lion.NominatedLionSendComponent nl with (nolock)
WHERE LionSendID = @LionSendID


--IF OBJECT_ID ('tempdb..#CustomerStats') IS NOT NULL DROP TABLE #CustomerStats
SELECT      LionSendID,
      UploadDate,
      COUNT(DISTINCT nl.SelectedCusts) as SelectedCustomerCount,
      COUNT(CASE WHEN c.CurrentlyActive = 1 THEN nl.SelectedCusts ELSE NULL END) as Currently_Activated,
      COUNT(CASE WHEN c.CurrentlyActive = 1 AND MarketableByEmail = 1 THEN nl.SelectedCusts ELSE NULL END) as Currently_MarketableByEmail,
      COUNT(CASE WHEN c.CurrentlyActive = 0 THEN nl.SelectedCusts ELSE NULL END) as Deactivated,
      COUNT(cj.FanID) as CustomerJourneyStatues
FROM #SelectedCusts nl
LEFT OUTER JOIN Relational.Customer c with (nolock)
      ON nl.SelectedCusts = c.CompositeID
LEFT OUTER JOIN Relational.CustomerJourney cj with (nolock)
      ON c.FanID = cj.FanID
      AND cj.EndDate IS NULL
GROUP BY LionSendID, UploadDate