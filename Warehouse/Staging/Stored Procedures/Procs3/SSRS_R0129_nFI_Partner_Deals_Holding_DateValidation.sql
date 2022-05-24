

-- ***************************************************************************--
-- ***************************************************************************--
-- Author:		Ijaz Amjad													  --
-- Create date: 15/08/2016													  --
-- Description: Validation checks on holding table on dates					  --
--																			  --
-- ***************************************************************************--
-- ***************************************************************************--
CREATE PROCEDURE [Staging].[SSRS_R0129_nFI_Partner_Deals_Holding_DateValidation]
AS


/***************************************************************************
************************** Pull Back Month *********************************
***************************************************************************/
IF OBJECT_ID ('tempdb..#Months') IS NOT NULL DROP TABLE #Months
SELECT			SUBSTRING(StartDate,5,99) AS Month
INTO			#Months
FROM			Staging.nFI_Partner_Deals_Holding
WHERE			LEN(StartDate) = 6


/***************************************************************************
************************ Check for Invalid Month ***************************
***************************************************************************/
IF OBJECT_ID ('tempdb..#InvalidMonth') IS NOT NULL DROP TABLE #InvalidMonth
SELECT			*
INTO			#InvalidMonth
FROM			#Months
WHERE			LEN(Month) != 2
		OR		(
						CAST(Month AS INT) > 12
				OR		CAST(Month AS INT) < 1
				)


/***************************************************************************
************************* No. of invalid Months ***************************
***************************************************************************/
SELECT			COUNT(1) AS NumberOfErrors
FROM			#InvalidMonth

--select * from mi.campaign_log order by 1 desc