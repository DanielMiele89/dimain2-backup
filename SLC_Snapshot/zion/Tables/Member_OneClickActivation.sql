CREATE TABLE [zion].[Member_OneClickActivation] (
    [FanID]              INT              NOT NULL,
    [ActivationLinkGUID] UNIQUEIDENTIFIER NOT NULL,
    [Date]               DATETIME         NOT NULL,
    [LinkActive]         BIT              NULL,
    CONSTRAINT [PK_Member_OneClickActivation] PRIMARY KEY CLUSTERED ([FanID] ASC)
);

