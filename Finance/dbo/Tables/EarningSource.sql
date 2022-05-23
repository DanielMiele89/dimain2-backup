CREATE TABLE [dbo].[EarningSource] (
    [EarningSourceID] SMALLINT      IDENTITY (1, 1) NOT NULL,
    [SourceName]      VARCHAR (100) NOT NULL,
    [PartnerID]       INT           NOT NULL,
    [isBankFunded]    BIT           NULL,
    [FundingType]     VARCHAR (20)  CONSTRAINT [DF_EarningSource_FundingType] DEFAULT ('Uncategorised') NOT NULL,
    [AdditionalInfo1] VARCHAR (50)  NULL,
    [AdditionalInfo2] VARCHAR (50)  NULL,
    [SourceTypeID]    SMALLINT      NOT NULL,
    [SourceID]        VARCHAR (36)  NOT NULL,
    [CreatedDateTime] DATETIME2 (7) NOT NULL,
    [DisplayName]     VARCHAR (200) NULL,
    CONSTRAINT [PK_dbo_EarningSource] PRIMARY KEY CLUSTERED ([EarningSourceID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_EarningSource_PartnerID] FOREIGN KEY ([PartnerID]) REFERENCES [dbo].[Partner] ([PartnerID]),
    CONSTRAINT [FK_EarningSource_SourceTypeID] FOREIGN KEY ([SourceTypeID]) REFERENCES [dbo].[SourceType] ([SourceTypeID])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UNIX_EarningSource_Source]
    ON [dbo].[EarningSource]([SourceTypeID] ASC, [SourceID] ASC) WITH (FILLFACTOR = 90);

