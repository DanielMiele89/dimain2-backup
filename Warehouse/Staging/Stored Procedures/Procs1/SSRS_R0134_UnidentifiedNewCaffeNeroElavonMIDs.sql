


-- *****************************************************************************************************
-- Author:		Ijaz Amjad
-- Create date: 17/10/2016
-- Description: Shows info of new elavon MIDs have are NOT in GAS.
-- *****************************************************************************************************
CREATE PROCEDURE [Staging].[SSRS_R0134_UnidentifiedNewCaffeNeroElavonMIDs](
				@Date DATE)
						
			
AS

	SET NOCOUNT ON;

DECLARE			@SDate DATE
SET				@SDate = @Date

/***************************************************************************
**************** Identify new MIDs that are not in GAS *********************
***************************************************************************/
IF OBJECT_ID ('tempdb..#MIDsNotInGAS') IS NOT NULL DROP TABLE #MIDsNotInGAS
SELECT			DISTINCT MerchantID
INTO			#MIDsNotInGAS
FROM			SLC_Report.dbo.Match
WHERE			Status = 7
		AND		VectorID = 32
		AND		TransactionDate >= @SDate


/***************************************************************************
********************** Identify CCID's for new MIDs ************************
***************************************************************************/
IF OBJECT_ID ('tempdb..#CCIDs') IS NOT NULL DROP TABLE #CCIDs
SELECT			cc.ConsumerCombinationID
,				REPLACE(cc.MID,' ','') AS MID
,				cc.Narrative
INTO			#CCIDs
FROM			#MIDsNotInGAS AS a
INNER JOIN		Warehouse.Relational.ConsumerCombination AS cc WITH (NOLOCK)
		ON		cc.MID = a.MerchantID
LEFT OUTER JOIN	Warehouse.Staging.R_0134_MIDs_tobeExcluded AS ex
		ON		a.MerchantID = ex.MID
WHERE			ex.MID IS NULL

CREATE CLUSTERED INDEX IDX_CCID ON #CCIDs (ConsumerCombinationID)


/***************************************************************************
************************ Tran Data for the CCIDs ***************************
***************************************************************************/
IF OBJECT_ID ('tempdb..#TranData') IS NOT NULL DROP TABLE #TranData
SELECT			a.MID
,				COUNT(ct.Amount) AS TotalTrans
,				SUM(ct.Amount) AS TotalAmount
,				MIN(ct.TranDate) AS FirstTranDate
,				MAX(ct.TranDate) AS LastTranDate
INTO			#TranData
FROM			#CCIDs AS a
INNER JOIN		Warehouse.Relational.ConsumerTransaction AS ct WITH (NOLOCK)
		ON		ct.ConsumerCombinationID = a.ConsumerCombinationID
GROUP BY		a.MID


/***************************************************************************
**************************** Display Report ********************************
***************************************************************************/
SELECT			a.MID
,				a.Narrative
,				b.TotalTrans
,				b.TotalAmount
,				b.FirstTranDate
,				b.LastTranDate
FROM			#CCIDs a
INNER JOIN		#TranData AS b
		ON		a.MID = b.MID
left Outer join slc_report.dbo.retailoutlet as ro
		on		b.MID = ro.MerchantID
Where			ro.ID is null
ORDER BY		MID