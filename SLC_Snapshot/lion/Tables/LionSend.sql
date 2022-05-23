CREATE TABLE [lion].[LionSend] (
    [ID]                     INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Name]                   NVARCHAR (50)  NULL,
    [Description]            NVARCHAR (255) NULL,
    [CreatedDate]            DATETIME       NULL,
    [CreatedBy]              NVARCHAR (45)  NULL,
    [SendDate]               DATETIME       NULL,
    [EmailCampaignKey]       NVARCHAR (45)  NULL,
    [Status]                 INT            NULL,
    [ChannelID]              INT            NULL,
    [ProcessMessage]         NVARCHAR (255) NULL,
    [Uploaded]               BIT            NOT NULL,
    [TotalMembers]           INT            NOT NULL,
    [OfferPerMember]         INT            NOT NULL,
    [TotalNumberOfChunks]    INT            NULL,
    [NumberOfChunksUploaded] INT            NOT NULL,
    CONSTRAINT [PK__LionSend__3214EC275E38FC6B] PRIMARY KEY CLUSTERED ([ID] ASC)
);

