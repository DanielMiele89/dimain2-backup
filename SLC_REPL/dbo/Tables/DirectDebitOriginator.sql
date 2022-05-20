CREATE TABLE [dbo].[DirectDebitOriginator] (
    [ID]          INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [OIN]         INT            NOT NULL,
    [Name]        NVARCHAR (100) NOT NULL,
    [Category1ID] INT            NOT NULL,
    [Category2ID] INT            NOT NULL,
    [StartDate]   DATETIME       NOT NULL,
    [EndDate]     DATETIME       NULL,
    [PartnerID]   INT            NULL,
    CONSTRAINT [PK_DirectDebitOriginatorID] PRIMARY KEY CLUSTERED ([ID] ASC)
);

