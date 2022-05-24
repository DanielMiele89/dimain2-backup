-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE Prototype.AffinityFileMonth_Fetch
	
AS
BEGIN

	SET NOCOUNT ON;

    DECLARE @startdate DATE, @enddate DATE, @fileid INT

	SET @startdate = DATEADD(MONTH,-1,DATEFROMPARTS(year(getdate()),month(getdate()),1))
	SET @enddate = EOMONTH(@startdate)

	SELECT @fileid = MAX(FileID) FROM Prototype.LastFileProcessedAffinity
                                                
	SELECT c.Hashbin AS HashIdentifier
		, c.ProxyUserID
		, t.trandate as AuthorisationDate
		, '"' + RTRIM(cc.MID) + '"' AS MerchantMIDNumber
		, '"' + cc.Narrative + '"' AS MerchantDescriptor
		, '"' + m.MCC + '"' AS MCCCode
		, '"' + RTRIM(l.LocationAddress) +'"' AS MerchantLocation
		, CAST(t.Amount AS DECIMAL(12,2))  AS TransactionAmount
		, '"GBP"' AS CurrencyCode
		, t.cardholderpresentdata AS CardholderPresentFlag
		, '"Debit"' AS CardType
		, '"' + c.CardholderLocationIndicator + '"' AS CardholderLocationIndicator
	, cast(crypt_gen_random(2) as int) as RandSeed
	FROM Relational.ConsumerTransaction t WITH (NOLOCK)
	INNER JOIN InsightArchive.CustomerHashList_Sample c on t.CINID = c.CINID
	INNER JOIN Relational.ConsumerCombination cc on t.consumercombinationid = cc.ConsumerCombinationID
	INNER JOIN Relational.MCCList m on cc.MCCID = m.MCCID
	INNER JOIN InsightArchive.CustomerHashCombo ch ON cc.ConsumerCombinationID = ch.ConsumerCombinationID
	INNER JOIN Relational.Location l on t.LocationID = l.LocationID
	WHERE (t.TranDate BETWEEN @startdate AND @enddate)
	OR (t.trandate < @startdate AND t.FileID > @fileid)

END