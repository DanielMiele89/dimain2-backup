CREATE TABLE [SmartEmail].[BlackFriday_ControlGroup] (
    [FanID] INT NOT NULL
);


GO
GRANT VIEW DEFINITION
    ON OBJECT::[SmartEmail].[BlackFriday_ControlGroup] TO [New_PIIRemoved]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[SmartEmail].[BlackFriday_ControlGroup] TO [New_PIIRemoved]
    AS [dbo];

