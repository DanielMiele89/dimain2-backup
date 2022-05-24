-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE MI.PartnerDealsCheck 
	
AS
BEGIN

	SET NOCOUNT ON;

	SELECT ID
		, ClubID
		, PartnerID
		, PartnerName
		, StartDate
		, EndDate
		, NextStart
	FROM
	(
		SELECT p.partnername
			, d.ID, d.ClubID
			, d.PartnerID
			, d.StartDate
			, d.EndDate
			, LEAD(startdate, 1) over (partition by d.partnerID, d.clubID order by d.startdate) As NextStart
		FROM Relational.nFI_Partner_Deals d
		INNER JOIN Relational.[Partner] p on d.PartnerID = p.PartnerID
	) d
	LEFT OUTER JOIN MI.PartnerDealException e ON d.ID = e.PartnerDealID
	WHERE NextStart IS NOT NULL AND DATEDIFF(DAY, EndDate, NextStart) != 1
	AND e.PartnerDealID IS NULL
	ORDER BY d.PartnerID, d.ClubID, d.StartDate
    
END
GO
GRANT EXECUTE
    ON OBJECT::[MI].[PartnerDealsCheck] TO [BIDIMAINReportUser]
    AS [dbo];

