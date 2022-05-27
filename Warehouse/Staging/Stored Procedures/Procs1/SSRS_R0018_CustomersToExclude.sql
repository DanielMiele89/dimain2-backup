/*
	Author:			Stuart Barnley
	Date:			23-05-2014

	Description:	This stored procedure is used to populate the report R_0018.

					This pull off a list of those chosen for the weekly email
					with customer account changes meaning they no longer should be.

Update:			N/A
					
*/
CREATE Procedure [Staging].[SSRS_R0018_CustomersToExclude]

as
SELECT	DISTINCT c.FanID,
	Email,
	c.ClubID
FROM Warehouse.Lion.NominatedLionSendComponent nl
INNER JOIN Warehouse.Relational.Customer c
	ON nl.CompositeID = c.CompositeID
WHERE	(c.CurrentlyActive = 0 OR c.MarketableByEmail = 0 OR LEN(PostCode) < 3)