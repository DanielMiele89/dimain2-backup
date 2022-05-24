CREATE TABLE [SmartEmail].[SmartEmailSendStatus] (
    [ID]          INT           IDENTITY (1, 1) NOT NULL,
    [Name]        VARCHAR (40)  NOT NULL,
    [Description] VARCHAR (150) NOT NULL,
    CONSTRAINT [pk_SmartFocusSendStatus] PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
GRANT SELECT
    ON OBJECT::[SmartEmail].[SmartEmailSendStatus] TO [sfduser]
    AS [dbo];

