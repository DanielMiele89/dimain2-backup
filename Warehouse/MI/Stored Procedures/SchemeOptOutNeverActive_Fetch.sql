-- =============================================
-- Author:		JEA
-- Create date: 09/07/2013
-- Description:	Retrieves list of customers who have opted out without ever activating within the scheme
-- eddited By AJS on 15052014 to add Bankid
-- =============================================
CREATE PROCEDURE [MI].[SchemeOptOutNeverActive_Fetch]
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT o.FanID, O.OptedOutDate, case F.Clubid when 138 then 1 when 132 then 2 else 101 end as BankID
	FROM
	(
		SELECT FanID, MAX(StatusDate) AS OptedOutDate
		FROM MI.CustomerActivationHistory
		WHERE ActivationStatusID = 2 --Opted Out
		GROUP BY FanID --records should be unique, but in case of odd data, use latest date
	) o
	LEFT OUTER JOIN
	(
		SELECT DISTINCT FanID
		FROM MI.CustomerActivationHistory
		WHERE ActivationStatusID = 1 --Activated
	) a ON o.FanID = a.FanID
	INNER JOIN SLC_report.dbo.fan F on o.fanid = F.id -- look for bank in SLC as fanes wonn'tbe in warehouse.customer
	WHERE A.FanID IS NULL and F.Clubid in (138,132) -- include only those customers who have NEVER activated.
	ORDER BY O.FanID

END
