-- =============================================
-- Author:		JEA
-- Create date: 07/08/2015
-- Description:	
-- =============================================
CREATE PROCEDURE MI.RBSActivationsBankBrand_Fetch
	
AS
BEGIN

	SET NOCOUNT ON;

    SELECT CASE WHEN c.ClubID = 132 THEN 'NatWest' ELSE 'RBS' END as [Bank Brand], count(1) AS Activations
	FROM Relational.Customer c
	INNER JOIN MI.customerActiveStatus a on c.fanid = a.fanid
	WHERE a.ActivatedDate = CAST(DATEADD(DAY, -1, GETDATE()) AS DATE)
	GROUP BY c.ClubID

END
