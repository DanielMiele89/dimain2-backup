-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [Prototype].[RetailerHeaderStage_Refresh] 
AS
BEGIN

	SET NOCOUNT ON;

	TRUNCATE TABLE Prototype.RetailerHeaderStage

	INSERT INTO Prototype.RetailerHeaderStage(RetailerID, Header)
	SELECT DISTINCT COALESCE(a.AlternatePartnerID, p.PartnerID) AS RetailerID, c.[Text] AS Header
	FROM slc_report.dbo.Collateral c
	INNER JOIN Relational.IronOffer o ON c.IronOfferID = o.IronOfferID
	INNER JOIN Relational.[Partner] p ON o.PartnerID = p.PartnerID
	LEFT OUTER JOIN APW.PartnerAlternate a ON p.PartnerID = a.PartnerID
	LEFT OUTER JOIN Prototype.RetailerHeader h ON c.[Text] COLLATE Latin1_General_CS_AS = h.Header COLLATE Latin1_General_CS_AS
	LEFT OUTER JOIN Prototype.RetailerHeaderStage_Exclude e on c.[Text] = e.Header
	WHERE CollateralTypeID = 53
	AND h.Header IS NULL
	AND e.Header IS NULL

END

GO
GRANT EXECUTE
    ON OBJECT::[Prototype].[RetailerHeaderStage_Refresh] TO [SmartEmailClickUser]
    AS [dbo];

