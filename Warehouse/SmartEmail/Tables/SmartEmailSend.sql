CREATE TABLE [SmartEmail].[SmartEmailSend] (
    [ID]            INT          NOT NULL,
    [StatusID]      TINYINT      NOT NULL,
    [CreatedDate]   DATETIME     NOT NULL,
    [CreatedBy]     VARCHAR (20) NULL,
    [StartDateTime] DATETIME     NULL,
    [EndDateTime]   DATETIME     NULL,
    [TotalMembers]  INT          NULL,
    CONSTRAINT [PK_SmartEmailSend] PRIMARY KEY CLUSTERED ([ID] ASC)
);

