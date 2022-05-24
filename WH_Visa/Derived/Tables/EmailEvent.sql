CREATE TABLE [Derived].[EmailEvent] (
    [EventID]          INT          NOT NULL,
    [EventDateTime]    DATETIME     NOT NULL,
    [EventDate]        DATE         NULL,
    [FanID]            INT          NOT NULL,
    [CompositeID]      BIGINT       NULL,
    [CampaignKey]      NVARCHAR (8) NOT NULL,
    [EmailEventCodeID] INT          NOT NULL,
    PRIMARY KEY CLUSTERED ([EventID] ASC)
);


GO
CREATE COLUMNSTORE INDEX [CSX_All]
    ON [Derived].[EmailEvent]([EventDate], [CampaignKey], [FanID], [EmailEventCodeID], [EventDateTime]);


GO
GRANT INSERT
    ON OBJECT::[Derived].[EmailEvent] TO [crtimport]
    AS [New_DataOps];


GO
GRANT SELECT
    ON OBJECT::[Derived].[EmailEvent] TO [crtimport]
    AS [New_DataOps];


GO
GRANT UPDATE
    ON OBJECT::[Derived].[EmailEvent] TO [crtimport]
    AS [New_DataOps];

