CREATE TABLE [Staging].[CreditCardCombo_Alter] (
    [ID]               INT          NOT NULL,
    [Narrative]        VARCHAR (50) NOT NULL,
    [SuggestedBrandID] SMALLINT     NOT NULL,
    [IsHighVariance]   BIT          NOT NULL,
    CONSTRAINT [PK_Staging_CreditCardCombo_Alter] PRIMARY KEY CLUSTERED ([ID] ASC)
);

