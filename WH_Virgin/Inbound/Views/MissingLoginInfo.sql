
CREATE VIEW [Inbound].[MissingLoginInfo]
AS
	SELECT DISTINCT [DIMAIN].[WH_Virgin].[Inbound].[Login].[LoginInformation] 
	FROM [DIMAIN].[WH_Virgin].[Inbound].[Login] td
	WHERE NOT EXISTS (
		SELECT 1
		FROM Derived.LoginInfo li
		WHERE td.LoginInformation = li.UserAgent
	)	



GO
GRANT SELECT
    ON OBJECT::[Inbound].[MissingLoginInfo] TO [dops_useragent]
    AS [dbo];

