CREATE TABLE [Staging].[RBSG_MonthlyReport_InMonthComms] (
    [Reference]           VARCHAR (10)   NULL,
    [Subject]             NVARCHAR (255) NOT NULL,
    [CampaignDescription] VARCHAR (28)   NULL,
    [ClubID]              INT            NULL,
    [EmailName]           VARCHAR (100)  NULL,
    [SentDate]            DATE           NULL,
    [E_EmailsSentOK]      INT            NULL,
    [Delivered]           INT            NULL,
    [Delivery_Pct]        FLOAT (53)     NULL,
    [E_EmailsOpened]      INT            NULL,
    [EmailOpens_Pct]      FLOAT (53)     NULL,
    [E_ClickLink]         INT            NULL,
    [Clicks_Open_Pct]     FLOAT (53)     NULL,
    [E_Unsubscribed]      INT            NULL,
    [UnSub_PCt]           INT            NULL
);

