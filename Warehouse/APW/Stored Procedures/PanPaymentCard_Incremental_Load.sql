-- =============================================
-- Author:		JEA
-- Create date: 15/02/2017
-- Description:	APW PanPaymentCard incremental Load
-- =============================================
CREATE PROCEDURE [APW].[PanPaymentCard_Incremental_Load] 
	(
		@MaxPanID INT
	)
AS
BEGIN

	SET NOCOUNT ON;

    SET NOCOUNT ON;

	SELECT p.ID AS PanID
		,f.ID AS FanID
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
	from SLC_Report.dbo.fan f
	INNER JOIN SLC_Report.dbo.pan p on p.CompositeID = f.CompositeID
	INNER JOIN SLC_Report.dbo.PaymentCard pc on p.PaymentCardID = pc.ID
	LEFT OUTER JOIN APW.BinRange br on LEFT(pc.MaskedCardNumber,6) >= br.BinStart and LEFT(pc.MaskedCardNumber,6) <= br.BinEnd
	LEFT OUTER JOIN SLC_Report.dbo.BINRANGEISSUER bri on LEFT(pc.MaskedCardNumber,6) = bri.ID
	LEFT OUTER JOIN (SELECT P.PaymentCardID, IssuerCustomerID 
						FROM SLC_Report.dbo.IssuerPaymentCard p
						LEFT OUTER JOIN APW.PaymentCardExclude e ON p.PaymentCardID = e.PaymentCardID
						WHERE e.PaymentCardID IS NULL
						)ipc on pc.id = ipc.PaymentCardID --- to flag RBS/NW as issuer
	LEFT OUTER JOIN SLC_Report.dbo.IssuerCustomer ic on ipc.IssuerCustomerID = ic.ID --- to flag RBS/NW as issuer
	LEFT OUTER JOIN SLC_Report.dbo.issuer i on ic.IssuerID = i.ID --- to flag RBS/NW as issuer
	WHERE p.ID > @MaxPanID

END