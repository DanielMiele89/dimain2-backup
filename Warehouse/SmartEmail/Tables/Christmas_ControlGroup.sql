CREATE TABLE [SmartEmail].[Christmas_ControlGroup] (
    [FanID] INT NOT NULL
);




GO
GRANT VIEW DEFINITION
    ON OBJECT::[SmartEmail].[Christmas_ControlGroup] TO [New_PIIRemoved]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[SmartEmail].[Christmas_ControlGroup] TO [New_PIIRemoved]
    AS [dbo];

