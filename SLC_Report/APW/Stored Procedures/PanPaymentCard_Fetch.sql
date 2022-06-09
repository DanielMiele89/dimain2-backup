-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>

------------------------------------------------------------------------------
-- Modification History

-- 10/04/2019 Jason Shipp
	-- Substituted SLC_Report.APW.Publisher table for Warehouse.APW.DirectLoad_PublisherIDs table, as the latter table is refreshed daily
-- =============================================
CREATE PROCEDURE [APW].[PanPaymentCard_Fetch] 

AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; -- CJM 20210303

BEGIN

	SET NOCOUNT ON;

    SELECT
       p.ID AS PanID
       , f.ID AS FanID
       , pc.ID AS PaymentCardID
       , CAST(p.AdditionDate as date) as AdditionDate
       , CAST(p.RemovalDate as date) as RemovalDate
       , CAST(p.DuplicationDate as date) as DuplicationDate
       , pc.CardTypeID
       , CAST(CASE WHEN f.ClubID = 138 THEN 132 ELSE f.ClubID END AS INT) AS PublisherID
       , CAST(LEFT(pc.MaskedCardNumber,6) AS VARCHAR(6)) AS BinRange
       , CAST(COALESCE(br.scheme,bri.scheme,'') AS VARCHAR(20)) AS CardScheme
       , CAST(COALESCE(bri.issuer,i.name,'') AS VARCHAR(100)) AS CardIssuer
	   , pc.MaskedCardNumber
	from dbo.Pan p
	INNER JOIN SLC_Report.dbo.PaymentCard pc 
		   on p.PaymentCardID = pc.ID
	INNER JOIN SLC_Report.dbo.fan f
		   on p.CompositeID = f.CompositeID
	INNER JOIN Warehouse.APW.DirectLoad_PublisherIDs pu ON f.ClubID = pu.PublisherID AND pu.PublisherID >0
	LEFT OUTER JOIN APW.BinRange br on LEFT(pc.MaskedCardNumber,6) >= br.BinStart and LEFT(pc.MaskedCardNumber,6) <= br.BinEnd
	LEFT OUTER JOIN SLC_Report.dbo.BINRANGEISSUER bri on LEFT(pc.MaskedCardNumber,6) = bri.ID

	OUTER APPLY ( --- to flag RBS/NW as issuer
		SELECT p.PaymentCardID, p.IssuerCustomerID 
		FROM SLC_Report.dbo.IssuerPaymentCard p
		LEFT OUTER JOIN APW.PaymentCardExclude e 
				  ON p.PaymentCardID = e.PaymentCardID
		WHERE p.PaymentCardID = pc.id 
				  AND e.PaymentCardID IS NULL
	) ipc 
	LEFT OUTER JOIN SLC_Report.dbo.IssuerCustomer ic on ipc.IssuerCustomerID = ic.ID --- to flag RBS/NW as issuer
	LEFT OUTER JOIN SLC_Report.dbo.issuer i on ic.IssuerID = i.ID;

END