-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [Prototype].[RetailerHeaderStage_Fetch]
	
AS
BEGIN

	SET NOCOUNT ON;

    SELECT h.RetailerID, ISNULL(p.PartnerName,'') AS PartnerName, h.Header
	FROM Prototype.RetailerHeaderStage h
	LEFT OUTER JOIN Relational.[Partner] p ON h.RetailerID = p.PartnerID

END