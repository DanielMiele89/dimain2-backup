


-- *****************************************************************************************************
-- Author:		Ijaz Amjad
-- Create date: 21/04/2016
-- Description: MIDs and transactions data for a Partner.
-- *****************************************************************************************************
CREATE PROCEDURE [Staging].[SSRS_R0121_MIDsPerPartner_BPD](
			@PartnerID int
			)
						
			
AS
BEGIN
	SET NOCOUNT ON;

DECLARE @PID int
SET		@PID = @PartnerID

/************************************************************************
********* Finding ALL ConsumerCombinationID's for Partner ***************
************************************************************************/
IF OBJECT_ID ('tempdb..#CCIDs') IS NOT NULL DROP TABLE #CCIDs
SELECT		p.PartnerID,
			p.PartnerName,
			b.BrandID,
			b.BrandName,
			cc.ConsumerCombinationID,
			cc.MID,
			cc.Narrative,
			cc.LocationCountry,
			mcc.MCC,
			mcc.MCCDesc
INTO		#CCIDs
FROM		Relational.ConsumerCombination AS cc WITH (NOLOCK)
INNER JOIN	Relational.Partner AS p
	ON		cc.BrandID = p.BrandID
INNER JOIN	Relational.MCCList AS mcc
	ON		cc.MCCID = mcc.MCCID
INNER JOIN	Relational.Brand AS b
	ON		cc.BrandID = b.BrandID
WHERE		REPLACE(p.PartnerID, ' ','') LIKE @PID

CREATE CLUSTERED INDEX IDX_CCID1 ON #CCIDs (ConsumerCombinationID)


/************************************************************************
*************** Finding Transactional Data  for CCID's ******************
************************************************************************/
IF OBJECT_ID ('tempdb..#TranData') IS NOT NULL DROP TABLE #TranData
SELECT		#CCIDs.ConsumerCombinationID,
			SUM(ct.Amount) AS TransactionAmountEver,
			COUNT(1) AS TransactionsEver,
			SUM(CASE
					WHEN ct.TranDate	BETWEEN DATEADD(YEAR,-1,DATEADD(MONTH,-1,DATEADD(DAY,(-DAY(GETDATE()))+1,CAST(GETDATE() AS DATE))))  
									AND		DATEADD(DAY,-DAY(GETDATE()),CAST(GETDATE() AS DATE))
					THEN ct.Amount
					ELSE 0
				END) AS TransactionAmountLastYear,
			SUM(CASE
					WHEN ct.TranDate	BETWEEN DATEADD(YEAR,-1,DATEADD(MONTH,-1,DATEADD(DAY,(-DAY(GETDATE()))+1,CAST(GETDATE() AS DATE))))  
									AND		DATEADD(DAY,-DAY(GETDATE()),CAST(GETDATE() AS DATE))
					THEN 1
					ELSE 0
				END) AS TransactionsLastYear
INTO		#TranData
FROM		#CCIDs
INNER JOIN	Relational.ConsumerTransaction ct WITH (NOLOCK)
	ON		#CCIDs.ConsumerCombinationID = ct.ConsumerCombinationID
GROUP BY	#CCIDs.ConsumerCombinationID

CREATE CLUSTERED INDEX IDX_CCID2 ON #TranData (ConsumerCombinationID)


/************************************************************************
*********************** Collating Data Together *************************
************************************************************************/
IF OBJECT_ID ('tempdb..#AllData') IS NOT NULL DROP TABLE #AllData
SELECT		#CCIDs.*,
			#TranData.TransactionAmountEver AS TransactionAmount_Ever,
			#TranData.TransactionsEver AS Transactions_Ever,
			#TranData.TransactionAmountLastYear AS TransactionAmount_LastYear,
			#TranData.TransactionsLastYear AS Transactions_LastYear,
			Min(ct.TranDate) AS FirstTranDate,
			Max(ct.TranDate) AS LastTranDate,
			COUNT(ct.TranDate) AS TransactionCount
INTO		#AllData
FROM		#CCIDs
LEFT OUTER JOIN	#TranData
	ON		#CCIDs.ConsumerCombinationID = #TranData.ConsumerCombinationID
INNER JOIN	Relational.ConsumerTransaction AS ct WITH (NOLOCK)
	ON		#CCIDs.ConsumerCombinationID = ct.ConsumerCombinationID
LEFT OUTER JOIN Staging.BrandSuggestionRejected bsr
	ON		#CCIDs.ConsumerCombinationID = bsr.ConsumerCombinationID
WHERE		bsr.ConsumerCombinationID IS NULL
GROUP BY	#CCIDs.PartnerID,
			#CCIDs.PartnerName,
			#CCIDs.BrandID,
			#CCIDs.BrandName,
			#CCIDs.ConsumerCombinationID,
			#CCIDs.MID,
			#CCIDs.Narrative,
			#CCIDs.LocationCountry,
			#CCIDs.MCC,
			#CCIDs.MCCDesc,
			#TranData.TransactionAmountEver,
			#TranData.TransactionsEver,
			#TranData.TransactionAmountLastYear,
			#TranData.TransactionsLastYear


/************************************************************************
************************* Display Report ********************************
************************************************************************/
SELECT		*
FROM		#AllData
ORDER BY	TransactionAmount_LastYear DESC


END

-- EXEC [Staging].[SSRS_R0121_MIDsPerPartner_BPD] 4319