
-- =============================================
-- Author: Suraj Chahal
-- Create date: 02/09/2014
-- Description: Script to pull customer data for those customers who have a birthday on that day or next so they can be sent
--		the Caffe Nero Birthday Email
-- =============================================
CREATE PROCEDURE [Staging].[SSRS_R0047_CaffeNero_BirthdayEmailsSelection]
				(@EmailDate DATE)

AS
BEGIN
	SET NOCOUNT ON;

IF OBJECT_ID ('tempdb..#t1') IS NOT NULL DROP TABLE #t1
SELECT	(MONTH(StartDate)*100)+DAY(StartDate) As Start_, 
	(MONTH(EndDate)*100)+DAY(EndDate) as End_
INTO #t1
FROM
(
SELECT	DATENAME(DW,@EmailDate) as StartDay,
        CAST(@EmailDate AS DATE) as StartDate,
        CASE
                WHEN DATEPART(DW,@EmailDate) IN (2,4) THEN DATEADD(DAY,1,CAST(@EmailDate AS DATE))
                WHEN DATEPART(DW,@EmailDate) IN (6) THEN DATEADD(DAY,2,CAST(@EmailDate AS DATE))
        END AS EndDate
) a


SELECT      Email,
            ClubID,
            Title,
            FirstName,
            LastName,
            DOB,
            Shortcode
FROM Warehouse.Relational.Customer c (NOLOCK)
INNER JOIN SLC_Report..CustomerJourney cj (NOLOCK)
            ON c.FanID = cj.FanID
            AND cj.EndDate IS NULL
INNER JOIN #t1 as t
            ON (Month(DOB)*100)+Day(DOB) between Start_ and End_
            AND CurrentlyActive = 1
            AND MarketableByEmail = 1
            AND LEFT(Shortcode,2) IN ('M2','M3','R','S')

END