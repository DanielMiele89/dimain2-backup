

-- ***************************************************************************--
-- ***************************************************************************--
-- Author:		Ijaz Amjad													  --
-- Create date: 23/09/2016													  --
-- Description: Shows MID Data for Credit Card Transactions					  --
-- ***************************************************************************--
-- ***************************************************************************--
CREATE PROCEDURE [Staging].[SSRS_R0131_MID_CreditCardTrans](
			@MID VARCHAR(50)
			)
With execute as owner
AS

DECLARE	@MerchantID VARCHAR(50)

SET		@MerchantID = @MID

--SELECT @SDATE


IF OBJECT_ID ('tempdb..#CTH') IS NOT NULL DROP TABLE #CTH
SELECT		*
INTO		#CTH
FROM		Archive_Light.dbo.CBP_Credit_TransactionHistory AS th
WHERE		MerchantID LIKE '%'+@MerchantID+'%'

IF OBJECT_ID ('tempdb..#Info') IS NOT NULL DROP TABLE #Info
SELECT		MerchantDBAName
,           MerchantDBACity
,           MerchantZip
,           MerchantID
,			MIN(TranDate) AS FirstTranDate
,           MAX(Trandate) AS LastTranDate
,           COUNT(*) AS Transactions
INTO		#Info
FROM		#CTH
GROUP BY	MerchantDBAName
,			MerchantDBACity
,			MerchantID
,			MerchantZip

SELECT		*
FROM		#Info
ORDER BY	LastTranDate DESC