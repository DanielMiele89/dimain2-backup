
-- =============================================
-- Author: Suraj Chahal
-- Create date: 24/10/2014
-- Description: Script to pull customer data for those customers who have a birthday on that day or next so they can be sent
--		the Caffe Nero Birthday Email
-- Change Log:	Updated to show Date in different format
-- =============================================
CREATE PROCEDURE [Staging].[SSRS_R0047_CaffeNero_BirthdayEmailsSelectionV2]
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


SELECT  Email,
        ClubID,
        Title,
        FirstName,
        LastName,
        DOB,
	CASE	
		WHEN RIGHT(DAY(DOB),1) = 1 THEN (CASE	
							WHEN LEN(DAY(DOB)) = 1 THEN CAST(DAY(DOB) AS CHAR(1))+'st '+DATENAME(MONTH,DOB)
							ELSE CAST(DAY(DOB) AS CHAR(2))+'st '+DATENAME(MONTH,DOB)
						END)
		WHEN RIGHT(DAY(DOB),1) = 2 THEN (CASE	
							WHEN LEN(DAY(DOB)) = 1 THEN CAST(DAY(DOB) AS CHAR(1))+'nd '+DATENAME(MONTH,DOB)
							ELSE CAST(DAY(DOB) AS CHAR(2))+'nd '+DATENAME(MONTH,DOB)
						END)
		WHEN RIGHT(DAY(DOB),1) = 3 THEN (CASE	
							WHEN LEN(DAY(DOB)) = 1 THEN CAST(DAY(DOB) AS CHAR(1))+'rd '+DATENAME(MONTH,DOB)
							ELSE CAST(DAY(DOB) AS CHAR(2))+'rd '+DATENAME(MONTH,DOB)
						END)
		ELSE 	(CASE	
							WHEN LEN(DAY(DOB)) = 1 THEN CAST(DAY(DOB) AS CHAR(1))+'th '+DATENAME(MONTH,DOB)
							ELSE CAST(DAY(DOB) AS CHAR(2))+'th '+DATENAME(MONTH,DOB)
			END)
	END as DateOfBirth,
        Shortcode
FROM Warehouse.Relational.Customer c (NOLOCK)
INNER JOIN SLC_Report..CustomerJourney cj (NOLOCK)
            ON c.FanID = cj.FanID
            AND cj.EndDate IS NULL
INNER JOIN #t1 as t
            ON (Month(DOB)*100)+Day(DOB) between Start_ and End_
            AND CurrentlyActive = 1
            AND MarketableByEmail = 1
            AND LEFT(Shortcode,2) NOT IN ('DL','DN','M1')


END