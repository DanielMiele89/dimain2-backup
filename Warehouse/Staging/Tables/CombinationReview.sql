CREATE TABLE [Staging].[CombinationReview] (
    [CombinationReviewID] INT          IDENTITY (1, 1) NOT NULL,
    [MID]                 VARCHAR (50) NOT NULL,
    [Narrative]           VARCHAR (50) NOT NULL,
    [LocationAddress]     VARCHAR (50) NULL,
    [LocationCountry]     VARCHAR (3)  NULL,
    [MCC]                 VARCHAR (4)  NULL,
    [SuggestedBrandID]    SMALLINT     NULL,
    [Confidence]          VARCHAR (3)  NULL,
    [BrandMIDID]          INT          NULL,
    [IsHighVariance]      BIT          CONSTRAINT [DF_CombinationReview_IsHighVariance] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_CombinationReview] PRIMARY KEY CLUSTERED ([CombinationReviewID] ASC) WITH (FILLFACTOR = 80),
    CONSTRAINT [FK_CombinationReview_CombinationReviewConfidence] FOREIGN KEY ([Confidence]) REFERENCES [Staging].[CombinationReviewConfidence] ([Confidence])
);

