CREATE TABLE [Staging].[Combination] (
    [CombinationID]       INT          IDENTITY (1, 1) NOT NULL,
    [LocationCountry]     VARCHAR (3)  NOT NULL,
    [MID]                 VARCHAR (22) NOT NULL,
    [Narrative]           VARCHAR (50) NOT NULL,
    [IsHighVariance]      BIT          NOT NULL,
    [BrandMIDID]          INT          NOT NULL,
    [Inserted]            DATETIME     CONSTRAINT [DF_Combination_Inserted] DEFAULT (getdate()) NOT NULL,
    [LastMatched]         DATETIME     CONSTRAINT [DF_Combination_LastMatched] DEFAULT (getdate()) NOT NULL,
    [CombinationReviewID] INT          NULL,
    CONSTRAINT [PK_Combination] PRIMARY KEY CLUSTERED ([CombinationID] ASC),
    CONSTRAINT [FK_Combination_BrandMID] FOREIGN KEY ([BrandMIDID]) REFERENCES [Relational].[BrandMID] ([BrandMIDID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Combination_BrandMIDNarrative]
    ON [Staging].[Combination]([BrandMIDID] ASC, [Narrative] ASC);

