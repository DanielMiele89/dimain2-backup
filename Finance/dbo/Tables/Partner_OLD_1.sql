CREATE TABLE [dbo].[Partner_OLD] (
    [PartnerID]       INT           NOT NULL,
    [Name]            VARCHAR (100) NOT NULL,
    [Status]          SMALLINT      NOT NULL,
    [CreatedDateTime] DATETIME2 (7) NOT NULL,
    [UpdatedDateTime] DATETIME2 (7) NULL,
    CONSTRAINT [PK_Partner_OLD] PRIMARY KEY CLUSTERED ([PartnerID] ASC)
);

